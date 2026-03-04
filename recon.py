import subprocess
import os
import sys
import threading
import time
import argparse
from datetime import datetime

# --- AUTO-INSTALL COLORAMA ---
try:
    from colorama import Fore, Style, init
    init(autoreset=True)
except ImportError:
    print("[*] Installing styling library (colorama)...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "colorama"])
    from colorama import Fore, Style, init
    init(autoreset=True)

# --- SPINNER LOGIC ---
class Spinner:
    def __init__(self, message="Task in progress"):
        self.message = message
        self.stop_event = threading.Event()
        self.thread = threading.Thread(target=self._spin)

    def _spin(self):
        chars = "|/-\\"
        i = 0
        while not self.stop_event.is_set():
            sys.stdout.write(f"\r{Fore.CYAN}[*] {self.message}... {chars[i % len(chars)]}")
            sys.stdout.flush()
            time.sleep(0.1)
            i += 1
        sys.stdout.write("\r" + " " * (len(self.message) + 20) + "\r")

    def start(self):
        self.thread.start()

    def stop(self):
        self.stop_event.set()
        self.thread.join()

def print_banner():
    banner = f"""
{Fore.CYAN}    ╔══════════════════════════════════════════════════╗
    ║             {Fore.YELLOW}N E T   W R I A T H{Fore.CYAN}                  ║
    ║        {Style.BRIGHT}{Fore.WHITE}Automated Asset Discovery Tool{Fore.CYAN}            ║
    ╚══════════════════════════════════════════════════╝
    """
    print(banner)

def log_error(output_dir, description, error_msg, stdout=None):
    log_path = os.path.join(output_dir, "error_log.txt")
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    with open(log_path, "a") as f:
        f.write(f"[{datetime.now()}] ERROR: {description}\n")
        f.write(f"Message: {error_msg}\n")
        if stdout: f.write(f"Output: {stdout}\n")
        f.write("-" * 30 + "\n")
    print(f"\r{Fore.RED}[!] Details logged to: {log_path}")

def run_command(command, description, output_dir):
    start_time = time.time()
    spinner = Spinner(description)
    spinner.start()
    try:
        result = subprocess.run(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        spinner.stop()
        elapsed = round(time.time() - start_time, 2)
        if result.returncode != 0:
            print(f"{Fore.RED}[!] {description} failed after {elapsed}s.")
            log_error(output_dir, description, result.stderr.strip(), result.stdout.strip())
            return False, elapsed
        return True, elapsed
    except Exception as e:
        spinner.stop()
        elapsed = round(time.time() - start_time, 2)
        print(f"{Fore.RED}[!] System error after {elapsed}s: {e}")
        log_error(output_dir, description, str(e))
        return False, elapsed

def check_dependencies():
    def find_bin(name):
        res = subprocess.run(f"where {name}", shell=True, capture_output=True, text=True)
        if res.returncode == 0: return name
        path = os.path.join(os.environ["USERPROFILE"], "go", "bin", f"{name}.exe")
        return path if os.path.exists(path) else None
    return {"subfinder": find_bin("subfinder"), "httpx": find_bin("httpx")}

# --- PHASE FUNCTIONS ---

def phase_1(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    success, duration = run_command(f"{bin_path} -d {target} -o {subdomains_file}", f"PHASE 1: Finding subdomains", output_dir)
    if success:
        with open(subdomains_file, 'r') as f: count = len(f.readlines())
        print(f"{Fore.GREEN}[+] Phase 1 Complete! Found {count} subdomains in {duration}s.")
        return True
    return False

def phase_2(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    if not os.path.exists(subdomains_file):
        print(f"{Fore.RED}[!] subdomains.txt missing. Run Phase 1 first.")
        return False
    live_file = os.path.join(output_dir, "live_sites.txt")
    # Optimized: -t 100 (threads), -timeout 3s, -rl 150 (rate limit)
    cmd = f"type {subdomains_file} | {bin_path} -sc -silent -t 100 -timeout 3s -o {live_file}"
    success, duration = run_command(cmd, f"PHASE 2: Checking web servers", output_dir)
    if success:
        with open(live_file, 'r') as f: count = len(f.readlines())
        print(f"{Fore.GREEN}[+] Phase 2 Complete! {count} live sites found in {duration}s.")
        return True
    return False

def interactive_menu(target, output_dir, deps, script_dir):
    while True:
        print(f"\n{Fore.YELLOW}--- MISSION CONTROL: {Fore.WHITE}{target} {Fore.YELLOW}---")
        print(f"{Fore.WHITE}[1] Full Recon (All Phases)")
        print(f"{Fore.WHITE}[2] Phase 1: Subdomains")
        print(f"{Fore.WHITE}[3] Phase 2: Live Sites")
        print(f"{Fore.WHITE}[4] New Target")
        print(f"{Fore.RED}[5] Exit")
        
        try:
            choice = input(f"\n{Fore.CYAN}NetWriath > ").strip()
            if choice == '1':
                if phase_1(target, output_dir, deps["subfinder"]) and deps["httpx"]:
                    phase_2(target, output_dir, deps["httpx"])
            elif choice == '2': phase_1(target, output_dir, deps["subfinder"])
            elif choice == '3': 
                if deps["httpx"]: phase_2(target, output_dir, deps["httpx"])
                else: print(f"{Fore.RED}[!] httpx not installed.")
            elif choice == '4':
                target = input(f"{Fore.WHITE}[?] New Target: ").strip()
                if not target: continue
                output_dir = os.path.join(script_dir, "outputs", target)
                if os.path.exists(output_dir):
                    import shutil
                    shutil.rmtree(output_dir)
                os.makedirs(output_dir)
            elif choice == '5': break
            else: print(f"{Fore.RED}[!] Invalid choice.")
        except KeyboardInterrupt:
            print(f"\n{Fore.YELLOW}[*] Session interrupted. Returning to menu...")
            continue

def main():
    parser = argparse.ArgumentParser(description="NetWriath - Automated Recon")
    parser.add_argument("-d", "--domain", help="Target domain")
    parser.add_argument("--full", action="store_true", help="Run full scan immediately")
    args = parser.parse_args()

    print_banner()
    deps = check_dependencies()
    if not deps["subfinder"]:
        print(f"{Fore.RED}[!] subfinder missing. Run setup.ps1.")
        return

    script_dir = os.path.dirname(os.path.abspath(__file__))

    try:
        # --- MAIN MISSION LOOP ---
        while True:
            target = args.domain if args.domain else input(f"{Fore.WHITE}[?] Enter Target Domain: ").strip()
            if not target: break

            output_dir = os.path.join(script_dir, "outputs", target)
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
                print(f"{Fore.CYAN}[*] Output folder: {output_dir}")
            elif not args.full:
                ov = input(f"{Fore.YELLOW}[?] Target folder exists. Overwrite? (y/n): ").lower()
                if ov == 'y':
                    import shutil
                    shutil.rmtree(output_dir)
                    os.makedirs(output_dir)

            if args.full:
                print(f"{Fore.YELLOW}[*] Starting automated full scan on {target}...")
                if phase_1(target, output_dir, deps["subfinder"]) and deps["httpx"]:
                    phase_2(target, output_dir, deps["httpx"])
                print(f"{Fore.GREEN}[+] Full scan completed.")
            else:
                interactive_menu(target, output_dir, deps, script_dir)

            # Ask to continue after finishing a mission or exiting the menu
            cont = input(f"\n{Fore.CYAN}[?] Start a new mission for a different domain? (y/n): ").lower()
            if cont != 'y':
                break
            else:
                # Reset domain argument for the next loop
                args.domain = None

    except KeyboardInterrupt:
        print(f"\n\n{Fore.YELLOW}[*] Ghosting... (NetWriath shutdown)")
    finally:
        print(f"{Fore.CYAN}[*] Happy Hunting!")

if __name__ == "__main__":
    main()
