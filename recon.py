import subprocess
import os
import sys
import threading
import time

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
        sys.stdout.write("\r" + " " * (len(self.message) + 15) + "\r")

    def start(self):
        self.thread.start()

    def stop(self):
        self.stop_event.set()
        self.thread.join()

def print_banner():
    """Prints a stylish ASCII banner."""
    banner = f"""
{Fore.CYAN}    ╔══════════════════════════════════════════════════╗
    ║             {Fore.YELLOW}N E T   W R I A T H{Fore.CYAN}                  ║
    ║        {Style.BRIGHT}{Fore.WHITE}Automated Asset Discovery Tool{Fore.CYAN}            ║
    ╚══════════════════════════════════════════════════╝
    """
    print(banner)

def log_error(output_dir, description, error_msg, stdout=None):
    """Creates a log file explaining the failure."""
    log_path = os.path.join(output_dir, "error_log.txt")
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    with open(log_path, "a") as f:
        f.write(f"--- ERROR REPORT: {description} ---\n")
        f.write(f"Error Message: {error_msg}\n")
        if stdout: f.write(f"Standard Output: {stdout}\n")
        f.write("-" * 30 + "\n\n")
    print(f"\r{Fore.RED}[!] Error details saved to: {log_path}")

def run_command(command, description, output_dir):
    """Utility to run a shell command with a spinner."""
    spinner = Spinner(description)
    spinner.start()
    try:
        result = subprocess.run(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        spinner.stop()
        if result.returncode != 0:
            print(f"{Fore.RED}[!] ERROR: {description} failed.")
            log_error(output_dir, description, result.stderr.strip(), result.stdout.strip())
            return False
        return True
    except Exception as e:
        spinner.stop()
        print(f"{Fore.RED}[!] SYSTEM ERROR: {e}")
        log_error(output_dir, description, str(e))
        return False

def check_dependencies():
    """Checks if subfinder and httpx are available."""
    print(f"{Fore.CYAN}[*] Checking dependencies...")
    def find_bin(name):
        res = subprocess.run(f"where {name}", shell=True, capture_output=True, text=True)
        if res.returncode == 0: return name
        path = os.path.join(os.environ["USERPROFILE"], "go", "bin", f"{name}.exe")
        return path if os.path.exists(path) else None
    return {"subfinder": find_bin("subfinder"), "httpx": find_bin("httpx")}

# --- PHASE FUNCTIONS ---

def phase_1_subdomains(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    cmd = f"{bin_path} -d {target} -o {subdomains_file}"
    if run_command(cmd, f"PHASE 1: Finding subdomains for {target}", output_dir):
        if os.path.exists(subdomains_file) and os.path.getsize(subdomains_file) > 0:
            with open(subdomains_file, 'r') as f: count = len(f.readlines())
            print(f"{Fore.GREEN}[+] Phase 1 Complete! Found {count} subdomains.")
            return True
    return False

def phase_2_live_sites(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    if not os.path.exists(subdomains_file):
        print(f"{Fore.RED}[!] Error: subdomains.txt not found. Run Phase 1 first.")
        return False
    
    live_file = os.path.join(output_dir, "live_sites.txt")
    cmd = f"type {subdomains_file} | {bin_path} -sc -silent -o {live_file}"
    if run_command(cmd, f"PHASE 2: Filtering live web servers", output_dir):
        if os.path.exists(live_file) and os.path.getsize(live_file) > 0:
            with open(live_file, 'r') as f: count = len(f.readlines())
            print(f"{Fore.GREEN}[+] Phase 2 Complete! {count} live servers found.")
            return True
    return False

def main():
    print_banner()
    deps = check_dependencies()
    
    if not deps["subfinder"]:
        print(f"{Fore.RED}[!] subfinder not found. Please run setup.ps1 and RESTART.")
        return

    target = input(f"{Fore.WHITE}[?] Enter target domain: ").strip()
    if not target: return

    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "outputs", target)
    if not os.path.exists(output_dir): os.makedirs(output_dir)

    while True:
        print(f"\n{Fore.YELLOW}--- MISSION CONTROL: {target} ---")
        print(f"{Fore.WHITE}1. Full Scan (Phase 1 & 2)")
        print(f"{Fore.WHITE}2. Phase 1 Only (Subdomain Discovery)")
        print(f"{Fore.WHITE}3. Phase 2 Only (Filter Live Sites)")
        print(f"{Fore.WHITE}4. Change Target")
        print(f"{Fore.RED}5. Exit")
        
        choice = input(f"\n{Fore.CYAN}[?] Select an option: ").strip()

        if choice == '1':
            if phase_1_subdomains(target, output_dir, deps["subfinder"]):
                if deps["httpx"]: phase_2_live_sites(target, output_dir, deps["httpx"])
        elif choice == '2':
            phase_1_subdomains(target, output_dir, deps["subfinder"])
        elif choice == '3':
            if deps["httpx"]:
                phase_2_live_sites(target, output_dir, deps["httpx"])
            else:
                print(f"{Fore.RED}[!] httpx is not installed.")
        elif choice == '4':
            target = input(f"{Fore.WHITE}[?] Enter new target domain: ").strip()
            output_dir = os.path.join(script_dir, "outputs", target)
            if not os.path.exists(output_dir): os.makedirs(output_dir)
        elif choice == '5':
            print(f"{Fore.YELLOW}[*] Shutting down NetWraith. Happy Hunting!")
            break
        else:
            print(f"{Fore.RED}[!] Invalid choice.")

if __name__ == "__main__":
    main()
