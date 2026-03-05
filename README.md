# NetWriath 👻

**NetWriath** is a professional, high-speed reconnaissance framework designed for rapid digital footprinting and infrastructure mapping. It automates the discovery lifecycle through a streamlined tactical interface, providing security researchers with consolidated, actionable intelligence in seconds.

---

## 🚀 Installation

### 1. Prerequisites
Ensure the following tools are accessible in your system path:
- [Git](https://git-scm.com/downloads) (Includes **Git Bash** for Windows)
- [Subfinder](https://github.com/projectdiscovery/subfinder)
- [Dnsx](https://github.com/projectdiscovery/dnsx)
- [Httpx](https://github.com/projectdiscovery/httpx)
- [Naabu](https://github.com/projectdiscovery/naabu)

### 2. Deployment
```bash
# Clone the repository
git clone https://github.com/umbyx-ai/NetWriath.git
cd NetWriath

# Initialize environment
bash setup.sh
```

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

## 🏁 Usage
Execute the main controller to enter the tactical dashboard:
```bash
bash netwriath.sh
```

### Dashboard Operations:
- **[1] Deploy Mission:** Executes the full automated reconnaissance chain.
- **[2] Purge Database:** Irreversibly deletes all stored scan results.
- **[3] Disconnect:** Safely terminates the operational session.

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
