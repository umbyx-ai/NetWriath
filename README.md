# NetWraith 👻

![Python](https://img.shields.io/badge/Python-3.x-blue.svg)
![Go](https://img.shields.io/badge/Go-1.20+-00ADD8.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

**NetWraith** is a high-speed, automated reconnaissance framework designed for cybersecurity professionals and bug bounty hunters. It orchestrates industry-standard discovery tools to map out a target's digital footprint and identify hidden assets in seconds.

---

## 🚀 Features
- **Fast Subdomain Discovery:** Leveraging `subfinder` to identify thousands of subdomains using passive and active sources.
- **Smart Output Management:** Results are neatly organized by target domain in a dedicated `outputs/` folder.
- **Robust Error Handling:** Generates detailed `error_log.txt` with troubleshooting steps if a scan fails.
- **Interactive UI:** A stylized terminal interface with a progress spinner and color-coded status messages.
- **Privacy First:** Built-in `.gitignore` ensures your sensitive scan results are never pushed to version control.

---

## 🛠️ Installation

### 1. Prerequisites (Windows)
Ensure you have the following installed:
- [Python 3.10+](https://www.python.org/downloads/)
- [Go (Golang)](https://go.dev/doc/install)
- [Git](https://git-scm.com/downloads)

### 2. Setup
Clone the repository and run the automated setup script to install all necessary discovery tools:

```powershell
# Clone the project
git clone https://github.com/YOUR_USERNAME/NetWraith.git
cd NetWraith

# Enable script execution (Required for Windows)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Run the installer
.\setup.ps1
```

---

## 🏁 Usage

Start a new reconnaissance mission by running the "Brain" of the framework:

```powershell
py recon.py
```

1. Enter your target domain (e.g., `google.com`) when prompted.
2. Watch NetWraith go to work with real-time status updates.
3. Check the `outputs/` folder for your results.

---

## 📂 Project Structure
```text
NetWraith/
├── recon.py          # The main orchestrator (The Brain)
├── setup.ps1         # Automatic tool installer
├── README.md         # Documentation
├── .gitignore        # Keeps your outputs private
└── outputs/          # Scan results (auto-generated)
    └── target.com/
        ├── subdomains.txt
        └── error_log.txt
```

---

## 🗺️ Roadmap
- [x] Phase 1: High-speed Subdomain Discovery
- [ ] Phase 2: Live Web Server Filtering (`httpx`)
- [ ] Phase 3: Automated Port Scanning (`naabu`)
- [ ] Phase 4: Visual Recon (Automated Screenshots)
- [ ] Phase 5: Markdown/HTML Report Generation

---

## 🤝 Contributing
Contributions are welcome! If you have ideas for new features or improvements, feel free to open an issue or submit a pull request.

## ⚠️ Disclaimer
NetWraith is intended for educational and authorized security testing purposes only. The author is not responsible for any misuse of this tool. Always obtain explicit permission before testing any target.

---
*Created by [Your Name/Handle]* 👻
