# NetWriath 👻

**NetWriath** is a professional, high-speed reconnaissance framework designed for rapid digital footprinting and infrastructure mapping. It automates the discovery lifecycle through a streamlined tactical interface, providing security researchers with consolidated intelligence in seconds.

---

## 🖥️ Console Preview

```text
 ███╗   ██╗███████╗████████╗██╗    ██╗██████╗ ██╗ █████╗ ████████╗██╗  ██╗
 ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔══██╗██║██╔══██╗╚══██╔══╝██║  ██║
 ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██████╔╝██║███████║   ██║   ███████║
 ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██╔══██╗██║██╔══██║   ██║   ██║  ██║
 ██║ ╚████║███████╗   ██║   ╚███╔███╔╝██║  ██║██║██║  ██║   ██║   ██║  ██║
 ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
  Automated Asset Discovery Framework // v4.6

 --------------------------------------------------------------------------
 :: [1] Deploy Mission
 :: [2] Purge Database
 :: [3] Disconnect
 --------------------------------------------------------------------------

 Option > 
```

---

## 🚀 Installation

NetWriath is natively cross-platform. Follow the steps below based on your operating system.

### 1. Installation Prerequisites
These base tools are required to initialize the environment and run the automated setup script.

#### **For Windows Users**
Before running the setup, ensure you have the following foundation tools:
1. **Git for Windows:** [Download & Install here](https://git-scm.com/downloads). (Provides **Git Bash**, which is required).
2. **Go (Golang):** [Download & Install here](https://go.dev/doc/install). 
3. **Nmap:** [Download & Install here](https://nmap.org/download.html).

#### **For Linux Users (Debian/Ubuntu/Kali)**
Run the following command to install the necessary foundations:
```bash
sudo apt update && sudo apt install git golang nmap -y
```

### 2. Deployment & Tool Setup
Once the prerequisites above are installed, open a **Bash** terminal (Git Bash on Windows) and execute:

```bash
# Clone the repository
git clone https://github.com/umbyx-ai/NetWriath.git
cd NetWriath

# Run the automated mission-ready setup
# This installs subfinder, dnsx, httpx, and naabu
bash setup.sh
```

---

## 🏁 Usage
Launch the tactical dashboard:
```bash
bash netwriath.sh
```

---

## 🗺️ Roadmap: Operational Phases
- [x] **Phase 1: Subdomain Discovery**  
  Passive and active enumeration of the target's DNS landscape.
- [x] **Phase 2: Primary IP Resolution**  
  Targeted identification of the primary infrastructure host.
- [x] **Phase 3: Live Web Filtering**  
  Validation of active HTTP/HTTPS endpoints across the discovered surface.
- [x] **Phase 4: Server Port Scanning**  
  Surgical port inventory and service state analysis of the primary host.
- [x] **Phase 5: Synthesis & Reporting**  
  Consolidation of all discovery data into a structured `Final_Report.md`.

---

## ⚠️ Disclaimer
NetWriath is intended strictly for authorized security testing and educational research. The user assumes all responsibility for compliance with local laws. The author assumes no liability for unauthorized use or resulting damages.

*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻
