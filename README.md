# NetWriath
=======
# NetWraith 👻

A modular, automated reconnaissance framework for cybersecurity professionals. NetWraith orchestrates high-speed discovery tools to map out a target's digital footprint and identify hidden assets.

## 🚀 Features
- **Subdomain Discovery:** Uses `subfinder` to identify thousands of subdomains.
- **Automated Logging:** Detailed `error_log.txt` generated if a scan fails.
- **Modular Output:** Results are organized by target domain in the `outputs/` folder.
- **Live Status:** Interactive UI with a progress spinner.

## 📋 Prerequisites (Windows)
Before running the setup, ensure you have the following installed:
- [Python 3.x](https://www.python.org/downloads/)
- [Go (Golang)](https://go.dev/doc/install)
- [Git](https://git-scm.com/downloads)

## 🛠️ Installation

1. **Clone the Repository:**
   ```powershell
   git clone https://github.com/YOUR_USERNAME/NetWraith.git
   cd NetWraith
   ```

2. **Enable Script Execution:**
   Windows restricts PowerShell scripts by default. Run this to allow the setup script:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

3. **Run the Setup Script:**
   This script will automatically install the necessary discovery tools via Go.
   ```powershell
   .\setup.ps1
   ```
   *Note: You may need to restart your terminal after the setup completes.*

## 🏁 Usage

To start a new reconnaissance mission:
```powershell
py recon.py
```
Simply enter the target domain (e.g., `google.com`) when prompted.

## 📂 Project Structure
```text
NetWraith/
├── recon.py          # The main orchestrator (The Brain)
├── setup.ps1         # Automatic tool installer
├── README.md         # Documentation
└── outputs/          # Scan results (auto-generated)
    └── target.com/
        ├── subdomains.txt
        └── error_log.txt
```

## ⚠️ Disclaimer
This tool is for educational and authorized security testing purposes only. Never use this tool on targets you do not have explicit permission to test.
>>>>>>> c7a2e25 (Initial commit: NetWraith Alpha)
