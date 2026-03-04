import subprocess
import os
import sys
import threading
import time
import argparse
import shutil
import re
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
        chars = "⣾⣽⣻⢿⡿⣟⣯⣷"
        i = 0
        while not self.stop_event.is_set():
            sys.stdout.write(f"\r{Fore.CYAN} {chars[i % len(chars)]} {self.message}...")
            sys.stdout.flush()
            time.sleep(0.1)
            i += 1
        sys.stdout.write("\r" + " " * (len(self.message) + 30) + "\r")

    def start(self):
        self.thread.start()

    def stop(self):
        self.stop_event.set()
        self.thread.join()

def print_banner():
    banner = f"""
    {Fore.CYAN}╔══════════════════════════════════════════════════╗
    ║             {Fore.YELLOW}N E T   W R I A T H{Fore.CYAN}                  ║
    ║        {Style.BRIGHT}{Fore.WHITE}Automated Asset Discovery Tool{Fore.CYAN}            ║
    ╚══════════════════════════════════════════════════╝
    """
    print(banner)

def log_error(output_dir, description, error_msg, stdout=None):
    log_path = os.path.join(output_dir, "error_log.txt")
    if not os.path.exists(output_dir): os.makedirs(output_dir)
    with open(log_path, "a", encoding="utf-8") as f:
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
        result = subprocess.run(command, shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE, text=True, encoding="utf-8")
        spinner.stop()
        elapsed = round(time.time() - start_time, 2)
        if result.returncode != 0:
            print(f"{Fore.RED}[!] {description} failed ({elapsed}s).")
            log_error(output_dir, description, result.stderr.strip(), result.stdout.strip())
            return False, elapsed
        return True, elapsed
    except Exception as e:
        spinner.stop()
        elapsed = round(time.time() - start_time, 2)
        print(f"{Fore.RED}[!] System error: {e}")
        log_error(output_dir, description, str(e))
        return False, elapsed

def check_dependencies():
    def find_bin(name):
        res = subprocess.run(f"where {name}", shell=True, capture_output=True, text=True)
        if res.returncode == 0: return name
        path = os.path.join(os.environ["USERPROFILE"], "go", "bin", f"{name}.exe")
        return f'"{path}"' if os.path.exists(path) else None
    return {
        "subfinder": find_bin("subfinder"), 
        "httpx": find_bin("httpx"), 
        "dnsx": find_bin("dnsx"),
        "naabu": find_bin("naabu"),
        "gowitness": find_bin("gowitness")
    }

def find_browser():
    paths = [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
        r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    ]
    base_edge = r"C:\Program Files (x86)\Microsoft"
    if os.path.exists(base_edge):
        for root, dirs, files in os.walk(base_edge):
            if "msedge.exe" in files:
                paths.append(os.path.join(root, "msedge.exe"))
    for p in paths:
        if os.path.exists(p): return p
    return None

def get_output_dir(target):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "outputs", target)
    
    if os.path.exists(output_dir):
        ov = input(f"\n    {Fore.YELLOW}[?] Target folder exists. Overwrite? (y/n): ").lower()
        if ov == 'y':
            shutil.rmtree(output_dir)
            os.makedirs(output_dir)
            print(f"    {Fore.CYAN}[*] Folder reset.")
    else:
        os.makedirs(output_dir)
    return output_dir

# --- PHASE FUNCTIONS ---

def phase_1(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    with open(subdomains_file, "w", encoding="utf-8") as f: f.write(target + "\n")
    success, duration = run_command(f"{bin_path} -d {target} -o {subdomains_file}.tmp", f"PHASE 1: Subdomain Discovery", output_dir)
    if os.path.exists(subdomains_file + ".tmp"):
        with open(subdomains_file, "a", encoding="utf-8") as f:
            with open(subdomains_file + ".tmp", "r", encoding="utf-8") as tmp: f.write(tmp.read())
        os.remove(subdomains_file + ".tmp")
    with open(subdomains_file, 'r', encoding="utf-8") as f: count = len(f.readlines())
    print(f"{Fore.GREEN}[+] Phase 1 Complete! {count} targets found ({duration}s).")
    return True

def phase_2(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    if not os.path.exists(subdomains_file): return False
    ips_file = os.path.join(output_dir, "resolved_ips.txt")
    success, duration = run_command(f"type {subdomains_file} | {bin_path} -a -resp -nc -o {ips_file}.tmp", f"PHASE 2: IP Resolution", output_dir)
    if os.path.exists(ips_file + ".tmp"):
        with open(ips_file, "w", encoding="utf-8") as f_out:
            with open(ips_file + ".tmp", "r", encoding="utf-8") as f_in:
                for line in f_in:
                    ip_match = re.search(r"\[(\d+\.\d+\.\d+\.\d+)\]", line)
                    domain_match = re.match(r"^(\S+)", line)
                    if domain_match and ip_match:
                        f_out.write(f"{domain_match.group(1)}/{ip_match.group(1)}\n")
                    else:
                        parts = line.split()
                        if len(parts) >= 2:
                            ip = next((p for p in parts if re.match(r"\d+\.\d+\.\d+\.\d+", p)), None)
                            if ip: f_out.write(f"{parts[0]}/{ip}\n")
        os.remove(ips_file + ".tmp")
        if os.path.exists(ips_file):
            with open(ips_file, 'r', encoding="utf-8") as f: count = len(f.readlines())
            print(f"{Fore.GREEN}[+] Phase 2 Complete! {count} IPs resolved ({duration}s).")
            return True
    return False

def phase_3(target, output_dir, bin_path):
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    if not os.path.exists(subdomains_file): return False
    live_file = os.path.join(output_dir, "live_sites.txt")
    cmd = f"type {subdomains_file} | {bin_path} -silent -o {live_file}"
    success, duration = run_command(cmd, f"PHASE 3: Live Web Filtering", output_dir)
    if success and os.path.exists(live_file) and os.path.getsize(live_file) > 0:
        with open(live_file, 'r', encoding="utf-8") as f: count = len(f.readlines())
        print(f"{Fore.GREEN}[+] Phase 3 Complete! {count} live sites found ({duration}s).")
        return True
    return False

def phase_4(target, output_dir, bin_path):
    target_file = os.path.join(output_dir, "subdomains.txt")
    if not os.path.exists(target_file): return False
    ports_file = os.path.join(output_dir, "open_ports.txt")
    cmd = f"{bin_path} -list {target_file} -top-ports 100 -o {ports_file}.tmp"
    success, duration = run_command(cmd, f"PHASE 4: Port Scanning", output_dir)
    if os.path.exists(ports_file + ".tmp"):
        services = {"21": "ftp", "22": "ssh", "23": "telnet", "25": "smtp", "53": "dns", "80": "http", "443": "https", "3306": "mysql", "3389": "rdp", "8080": "http-alt"}
        with open(ports_file, "w", encoding="utf-8") as f_out:
            with open(ports_file + ".tmp", "r", encoding="utf-8") as f_in:
                seen = set()
                for line in f_in:
                    m = re.search(r":(\d+)", line)
                    if m:
                        p = m.group(1)
                        entry = f"{p}/{services.get(p, 'unknown')}"
                        if entry not in seen:
                            f_out.write(entry + "\n")
                            seen.add(entry)
        os.remove(ports_file + ".tmp")
        if os.path.exists(ports_file):
            with open(ports_file, 'r', encoding="utf-8") as f: count = len(f.readlines())
            print(f"{Fore.GREEN}[+] Phase 4 Complete! {count} ports identified ({duration}s).")
            return True
    return False

def phase_5(target, output_dir, bin_path):
    live_file = os.path.join(output_dir, "live_sites.txt")
    if not os.path.exists(live_file) or os.path.getsize(live_file) == 0:
        print(f"{Fore.RED}[!] No live sites for screenshots. Run Phase 3 first.")
        return False
    screenshot_dir = os.path.join(output_dir, "screenshots")
    if not os.path.exists(screenshot_dir): os.makedirs(screenshot_dir)
    browser = find_browser()
    browser_flag = f'--chrome-path "{browser}"' if browser else ""
    cmd = f"{bin_path} scan file -f {live_file} --screenshot-path {screenshot_dir} {browser_flag} -q"
    success, duration = run_command(cmd, f"PHASE 5: Capturing Screenshots", output_dir)
    if success:
        if os.path.exists(screenshot_dir):
            count = len([f for f in os.listdir(screenshot_dir) if f.lower().endswith(('.png', '.jpeg', '.jpg'))])
            print(f"{Fore.GREEN}[+] Phase 5 Complete! {count} screenshots captured ({duration}s).")
            return True
    return False

def clear_outputs():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, "outputs")
    if os.path.exists(output_path):
        spinner = Spinner("Purging all scan data")
        spinner.start()
        shutil.rmtree(output_path)
        os.makedirs(output_path)
        time.sleep(1)
        spinner.stop()
        print(f"{Fore.GREEN}[+] Data cleared successfully.")
    else:
        print(f"{Fore.YELLOW}[!] Already empty.")

def display_menu():
    os.system('cls' if os.name == 'nt' else 'clear')
    print_banner()
    print(f"    {Fore.CYAN}┌──────────────────────────────────────────────────┐")
    print(f"    {Fore.CYAN}│ {Fore.YELLOW}{'MISSION CONTROL DASHBOARD'.center(48)} {Fore.CYAN}│")
    print(f"    {Fore.CYAN}├──────────────────────────────────────────────────┤")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[0] Full Recon Mission (Phases 1 -> 5)           {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[1] Phase 1: Subdomain Discovery                 {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[2] Phase 2: IP Resolution                       {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[3] Phase 3: Live Web Filtering                  {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[4] Phase 4: Port Scanning                       {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[5] Phase 5: Visual Recon (Screenshots)          {Fore.CYAN}│")
    print(f"    {Fore.CYAN}├──────────────────────────────────────────────────┤")
    print(f"    {Fore.CYAN}│ {Fore.WHITE}[6] Clear All Scan Data                          {Fore.CYAN}│")
    print(f"    {Fore.CYAN}│ {Fore.RED}[7] Exit Program                                 {Fore.CYAN}│")
    print(f"    {Fore.CYAN}└──────────────────────────────────────────────────┘")

def main():
    parser = argparse.ArgumentParser(description="NetWriath - Automated Recon")
    parser.add_argument("-d", "--domain", help="Target domain")
    parser.add_argument("--full", action="store_true", help="Run full scan immediately")
    args = parser.parse_args()
    deps = check_dependencies()
    if not deps["subfinder"]:
        print(f"{Fore.RED}[!] Core tools missing. Run setup.ps1.")
        return
    if args.domain and args.full:
        print_banner()
        target = args.domain
        output_dir = get_output_dir(target)
        print(f"{Fore.YELLOW}[*] Starting automated full scan on {target}...")
        phase_1(target, output_dir, deps["subfinder"])
        phase_2(target, output_dir, deps["dnsx"])
        phase_3(target, output_dir, deps["httpx"])
        phase_4(target, output_dir, deps["naabu"])
        if deps["gowitness"]: phase_5(target, output_dir, deps["gowitness"])
        print(f"{Fore.GREEN}[+] Full scan completed.")
        return
    while True:
        display_menu()
        choice = input(f"\n    {Fore.CYAN}NetWriath > ").strip()
        if choice == '7': break
        elif choice == '6':
            clear_outputs()
            time.sleep(1)
            continue
        elif choice in ['0', '1', '2', '3', '4', '5']:
            target = input(f"\n    {Fore.WHITE}[?] Enter Target Domain: ").strip()
            if not target: continue
            output_dir = get_output_dir(target)
            if choice == '0':
                phase_1(target, output_dir, deps["subfinder"])
                phase_2(target, output_dir, deps["dnsx"])
                phase_3(target, output_dir, deps["httpx"])
                phase_4(target, output_dir, deps["naabu"])
                if deps["gowitness"]: phase_5(target, output_dir, deps["gowitness"])
            elif choice == '1': phase_1(target, output_dir, deps["subfinder"])
            elif choice == '2': phase_2(target, output_dir, deps["dnsx"])
            elif choice == '3': phase_3(target, output_dir, deps["httpx"])
            elif choice == '4': phase_4(target, output_dir, deps["naabu"])
            elif choice == '5':
                if deps["gowitness"]: phase_5(target, output_dir, deps["gowitness"])
                else: print(f"    {Fore.RED}[!] gowitness not installed.")
            cont = input(f"\n    {Fore.YELLOW}[?] Continue? (y/n): ").lower()
            if cont != 'y': break
        else: print(f"    {Fore.RED}[!] Invalid choice.")
    print(f"\n    {Fore.YELLOW}[*] Ghosting... (NetWriath shutdown)")
    print(f"    {Fore.CYAN}[*] Happy Hunting!")

if __name__ == "__main__":
    main()
