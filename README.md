# NetWriath 👻

**NetWriath** is a high-speed, automated reconnaissance framework designed to map out a target's digital footprint in seconds. It orchestrates industry-standard security tools into a single, stylized dashboard.

## 🛠️ Tech Stack
- **Python:** The "Brain" of the framework. Handles mission control, CLI arguments, and the stylized UI.
- **Go (Golang):** Powering the high-performance discovery engines (`subfinder`, `dnsx`, `httpx`, `naabu`).
- **PowerShell:** Automates the environment setup and dependency management for Windows.

---

## 🚀 Installation (Windows)

1. **Clone & Enter:**
   ```powershell
   git clone https://github.com/umbyx-ai/NetWriath.git
   cd NetWriath
   ```

2. **Enable Scripts:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   ```

3. **Install Tools:**
   ```powershell
   .\setup.ps1
   ```

4. **Launch:**
   ```powershell
   py recon.py
   ```

---

## 🗺️ Roadmap: The 6 Phases

- [x] **Phase 1: Subdomain Discovery** (`subfinder`)  
  Identifies thousands of hidden subdomains using passive and active sources.
- [x] **Phase 2: IP Resolution** (`dnsx`)  
  Maps every discovered subdomain to its corresponding IP address.
- [x] **Phase 3: Live Web Filtering** (`httpx`)  
  Probes subdomains to identify which ones are hosting active web servers.
- [x] **Phase 4: Port Scanning** (`naabu`)  
  Scans targets for the top 100 open ports and identifies common services.
- [ ] **Phase 5: Visual Recon** (Roadmap)  
  Automated screenshots of every live web server found.
- [ ] **Phase 6: Reporting** (Roadmap)  
  Generation of a unified Markdown/HTML report of all findings.

---

## ⚠️ Disclaimer
NetWriath is intended for educational and authorized security testing only. Always obtain explicit permission before scanning any target. The author is not responsible for any misuse.

*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻
