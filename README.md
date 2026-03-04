# NetWriath 👻

![Python](https://img.shields.io/badge/Python-3.x-blue.svg)
![Go](https://img.shields.io/badge/Go-1.20+-00ADD8.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**NetWriath** is a high-speed, automated reconnaissance framework designed for cybersecurity professionals and bug bounty hunters. It orchestrates industry-standard discovery tools to map out a target's digital footprint and identify hidden assets in seconds.

---

## 🚀 Features
- **Interactive Mission Control:** A stylish, menu-driven dashboard to run specific scan phases or manage multiple targets.
- **Automated Mode:** Run full reconnaissance missions directly from the command line for fast results.
- **Fast Subdomain Discovery:** Leveraging `subfinder` to identify thousands of subdomains.
- **Live Web Filtering:** Integrated `httpx` support to identify active web servers with status codes.
- **Performance Tracking:** Real-time timers tell you exactly how long each phase takes to complete.
- **Robust Error Handling:** Generates detailed `error_log.txt` with timestamps for troubleshooting.
- **Privacy First:** Built-in `.gitignore` ensures your sensitive scan results are never pushed to GitHub.

---

## 🛠️ Installation

### 1. Prerequisites (Windows)
Ensure you have the following installed:
- [Python 3.10+](https://www.python.org/downloads/)
- [Go (Golang)](https://go.dev/doc/install)
- [Git](https://git-scm.com/downloads)

### 2. Setup
Clone the repository and run the automated setup script:

```powershell
# Clone the project
git clone https://github.com/umbyx-ai/NetWriath.git
cd NetWriath

# Enable script execution (Required for Windows)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Run the installer
.\setup.ps1
```

---

## 🏁 Usage

NetWriath supports two modes of operation:

### Option A: Interactive Dashboard (Recommended)
Simply run the script and follow the on-screen menu:
```powershell
py recon.py
```

### Option B: Automated Fast Scan
Skip the menu and run a full reconnaissance mission immediately:
```powershell
py recon.py -d target.com --full
```

### Options:
- `-d, --domain`: Specify the target domain directly.
- `--full`: Automatically run all scan phases.
- `-h, --help`: Show the help menu.

---

## 📂 Project Structure
```text
NetWriath/
├── recon.py          # The main orchestrator (Mission Control)
├── setup.ps1         # Automatic tool installer
├── README.md         # Documentation
├── .gitignore        # Keeps your outputs private
└── outputs/          # Scan results (auto-generated)
    └── target.com/
        ├── subdomains.txt
        ├── live_sites.txt
        └── error_log.txt
```

---

## 🗺️ Roadmap
- [x] Phase 1: High-speed Subdomain Discovery
- [x] Phase 2: Live Web Server Filtering (`httpx`)
- [ ] Phase 3: Automated Port Scanning (`naabu`)
- [ ] Phase 4: Visual Recon (Automated Screenshots)
- [ ] Phase 5: Markdown/HTML Report Generation

---

## 🤝 Contributing
Contributions are welcome! If you have ideas for new features or improvements, feel free to open an issue or submit a pull request.

## ⚠️ Disclaimer
NetWriath is intended for educational and authorized security testing purposes only. The author is not responsible for any misuse of this tool. Always obtain explicit permission before testing any target.

---
*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻
