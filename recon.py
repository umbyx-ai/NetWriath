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
    ║             {Fore.YELLOW}N E T   W R A I T H{Fore.CYAN}                  ║
    ║        {Style.BRIGHT}{Fore.WHITE}Automated Asset Discovery Tool{Fore.CYAN}            ║
    ╚══════════════════════════════════════════════════╝
    """
    print(banner)

def log_error(output_dir, description, error_msg, stdout=None):
    """Creates a log file explaining the failure."""
    log_path = os.path.join(output_dir, "error_log.txt")
    with open(log_path, "a") as f:
        f.write(f"--- ERROR REPORT: {description} ---\n")
        f.write(f"Reason: Command returned a non-zero exit code.\n")
        f.write(f"Error Message: {error_msg}\n")
        if stdout:
            f.write(f"Standard Output: {stdout}\n")
        f.write("\n[Possible Fixes]\n")
        f.write("1. Check if you have an active internet connection.\n")
        f.write("2. Verify the tool is installed by running it manually in PowerShell.\n")
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
            return None
            
        return result.stdout
    except Exception as e:
        spinner.stop()
        print(f"{Fore.RED}[!] SYSTEM ERROR: {e}")
        log_error(output_dir, description, str(e))
        return None

def check_dependencies():
    """Checks if subfinder is available in PATH or default Go bin."""
    print(f"{Fore.CYAN}[*] Checking dependencies...")
    result = subprocess.run("where subfinder", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        return "subfinder"
    
    go_bin_path = os.path.join(os.environ["USERPROFILE"], "go", "bin", "subfinder.exe")
    if os.path.exists(go_bin_path):
        print(f"{Fore.YELLOW}[*] Found subfinder at: {go_bin_path}")
        return go_bin_path
        
    return None

def main():
    print_banner()
    
    # 0. Check Dependencies
    subfinder_bin = check_dependencies()
    if not subfinder_bin:
        print(f"{Fore.RED}[!] subfinder is NOT in your PATH. Please run setup.ps1 and RESTART.")
        return

    # 1. Get Target
    target = input(f"{Fore.WHITE}[?] Enter target domain: ").strip()
    if not target: return

    # 2. Setup Output Directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = os.path.join(script_dir, "outputs", target)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"{Fore.CYAN}[*] Created output directory: {output_dir}")

    # 3. Run Subdomain Discovery
    subdomains_file = os.path.join(output_dir, "subdomains.txt")
    subfinder_cmd = f"{subfinder_bin} -d {target} -o {subdomains_file}"
    
    run_command(subfinder_cmd, f"Running Subfinder on {target}", output_dir)

    # 4. Check results
    if os.path.exists(subdomains_file) and os.path.getsize(subdomains_file) > 0:
        with open(subdomains_file, 'r') as f:
            count = len(f.readlines())
        print(f"{Fore.GREEN}[+] Success! Found {count} subdomains in: {subdomains_file}")
    else:
        print(f"{Fore.RED}[!] Scan failed to produce results. Check error_log.txt.")

if __name__ == "__main__":
    main()
