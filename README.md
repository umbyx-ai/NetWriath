# NetWriath 👻

**NetWriath** is a complete, high-speed reconnaissance framework designed for cybersecurity professionals and bug bounty hunters. It automates the entire discovery process—from subdomain mapping to visual evidence and final reporting—all within a single, stylized dashboard.

## 🛠️ Tech Stack
- **Python:** The "Orchestrator." Powers the Mission Control Dashboard, logic flow, and stylized terminal UI.
- **Go (Golang):** The "Engine." Powering high-performance discovery tools (`subfinder`, `dnsx`, `httpx`, `naabu`, `gowitness`).
- **PowerShell:** The "Installer." Automates environment setup and dependency management for Windows.

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

3. **Automated Setup:**
   Run the installer to download all necessary Go discovery tools:
   ```powershell
   .\setup.ps1
   ```

4. **Launch Mission Control:**
   ```powershell
   py recon.py
   ```

---

## 🏁 Usage

NetWriath is built for flexibility and speed:

### Interactive Dashboard
Launch the Mission Control Dashboard to run specific phases, manage targets, or clear scan data:
```powershell
py recon.py
```

### Automated Full Scan
Bypass the menu and run a complete end-to-end reconnaissance mission:
```powershell
py recon.py -d target.com --full
```

---

## 🗺️ Roadmap
- [x] **Phase 1: Subdomain Discovery** (`subfinder`)  
  Passive and active enumeration of the target's digital footprint.
- [x] **Phase 2: IP Resolution** (`dnsx`)  
  High-speed DNS mapping of every discovered asset.
- [x] **Phase 3: Live Web Filtering** (`httpx`)  
  Identification of active web servers and service status.
- [x] **Phase 4: Port Scanning** (`naabu`)  
  Automated port discovery and common service identification.
- [x] **Phase 5: Visual Recon** (`gowitness`)  
  Automated screenshot capturing of all discovered web interfaces.
- [x] **Phase 6: Consolidated Reporting** (NetWriath Engine)  
  Generation of a human-readable `Final_Summary.txt` report.

---

## ⚠️ Disclaimer
NetWriath is intended for educational and authorized security testing purposes only. Always obtain explicit permission before scanning any target. The author assumes no liability for misuse of this tool.

*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻
