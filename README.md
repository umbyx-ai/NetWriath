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

NetWriath is natively cross-platform and supports both **Windows** and **Linux** environments.

### 1. Prerequisites

#### **Windows Users**
Ensure you have the following installed:
- [Git for Windows](https://git-scm.com/downloads) (Required for **Git Bash**)
- [Go (Golang)](https://go.dev/doc/install)
- [Nmap](https://nmap.org/download.html)

#### **Linux Users (Debian/Ubuntu/Kali)**
Install the base requirements via your package manager:
```bash
sudo apt update && sudo apt install git golang nmap -y
```

### 2. Deployment
Regardless of your OS, execute the following commands in a **Bash** terminal:

```bash
# Clone the repository
git clone https://github.com/umbyx-ai/NetWriath.git
cd NetWriath

# Run the automated setup (installs Go discovery tools)
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
