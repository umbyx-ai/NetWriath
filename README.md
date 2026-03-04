# NetWriath 👻

**NetWriath** is a high-speed, automated reconnaissance framework for cybersecurity professionals. It orchestrates industry-standard discovery tools to map out a target's digital footprint in seconds.

## 🛠️ Tech Stack
- **Python:** The "Brain" of the framework. Handles orchestration, user input, CLI arguments, and the stylized terminal interface.
- **Go (Golang):** Powering the high-performance discovery engines (`subfinder`, `httpx`). All core tools are built in Go for maximum speed.
- **PowerShell:** Automates the entire installation and dependency management process for Windows systems.

---

## 🚀 Quick Start (Windows)

1. **Clone & Enter:**
   ```powershell
   git clone https://github.com/umbyx-ai/NetWriath.git
   cd NetWriath
   ```

2. **Enable Scripts:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

3. **Install Dependencies:**
   ```powershell
   .\setup.ps1
   ```
   *Note: Restart your terminal after the setup finishes.*

4. **Run NetWriath:**
   ```powershell
   py recon.py
   ```

---

## 🏁 Usage
- **Interactive Mode:** Run `py recon.py` and follow the menu.
- **Automated Mode:** `py recon.py -d target.com --full`

---

## 🗺️ Roadmap
- [x] Phase 1: Subdomain Discovery
- [x] Phase 2: Live Web Filtering
- [ ] Phase 3: Automated Port Scanning
- [ ] Phase 4: Visual Recon
- [ ] Phase 5: Reporting

---
*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻

## ⚠️ Disclaimer
Educational and authorized testing only. Obtain explicit permission before scanning any target.
