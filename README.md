# NetWriath 👻

[![tests](https://github.com/umbyx-ai/NetWriath/actions/workflows/tests.yml/badge.svg)](https://github.com/umbyx-ai/NetWriath/actions/workflows/tests.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Bash](https://img.shields.io/badge/bash-Linux%20%7C%20Windows%20(Git%20Bash)-lightgrey)

**NetWriath** is a Bash reconnaissance pipeline for **authorized** security assessments. Give it a domain and it chains four well-known tools:
- **subfinder** finds subdomains.
- **dnsx** resolves them.
- **httpx** probes the web services.
- **Nmap** scans the ports.

It then writes everything into a single Markdown report.

> ⚠️ Phases 3 and 4 send traffic to the target. Only run NetWriath against systems you own or have **written permission** to test. Before the port scan, NetWriath asks you to confirm that you have that permission.

---

## 🖥️ Console Preview

```text
 ███╗   ██╗███████╗████████╗██╗    ██╗██████╗ ██╗ █████╗ ████████╗██╗  ██╗
 ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔══██╗██║██╔══██╗╚══██╔══╝██║  ██║
 ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██████╔╝██║███████║   ██║   ███████║
 ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██╔══██╗██║██╔══██║   ██║   ██║  ██║
 ██║ ╚████║███████╗   ██║   ╚███╔███╔╝██║  ██║██║██║  ██║   ██║   ██║  ██║
 ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
  Automated Asset Discovery Framework // v6.0

 -------------------------------------------------------------------------
 :: [1] Deploy Mission
 :: [2] Purge Database
 :: [3] Disconnect
 -------------------------------------------------------------------------

 Option > 1

 Target > scanme.nmap.org

Init:: Recon on scanme.nmap.org
[*] Phase 1: Discovery...    Success (2 host(s))
[*] Phase 2: Resolution...   Success (1 of 2 hosts resolve, 1 IP(s))
[*] Phase 3: Web probing...  Success (1 live web service(s))
[*] Phase 4: Port scan...
[!] Phase 4 sends packets to 1 IP(s):
        45.33.32.156
    Do you have written authorization to scan them? Type "yes" to continue: yes
    [*] Phase 4: Port scan...    Success (4 open ports on 1 IP(s))
[*] Phase 5: Report...       Success

[+] Mission complete: outputs/scanme.nmap.org/Final_Report.md
```

---

## 🗺️ What each phase does

| Phase | Tool | Type | What you get |
|---|---|---|---|
| 1. Discovery | subfinder | Passive | Subdomains from public sources (certificates, DNS datasets, search engines). Results outside the target domain are dropped. |
| 2. Resolution | dnsx | DNS queries | A records of every host, the **CDN** behind each IP, and a **wildcard DNS** check (if random names resolve, some "subdomains" may not exist). |
| 3. Web probing | httpx | **Active** | Live web services with status code, page title, web server and detected technologies. |
| 4. Port scan | Nmap | **Active** | Open TCP ports with service and version (`-sV`). By default: the top 1000 ports, without the IPs that belong to a CDN. |
| 5. Report | — | — | `Final_Report.md` with a summary, warnings and one table per phase. |

### Why CDN IPs are skipped

An IP from Cloudflare, Akamai or AWS CloudFront is shared with thousands of other websites. Scanning it means scanning infrastructure that does not belong to your target, and that you are not authorized to test. If your scope does include those IPs, use `--include-cdn`.

### When something fails, you know

NetWriath checks the tools before it starts. Each phase reports `Success`, `Warning`, `Failed` or `Skipped`, and the report has a *Warnings* section. A phase that did not run says *"not checked"*; it never says *"none found"*. Every tool's output is saved in `logs/`.

---

## 🚀 Installation

### Requirements

| | Linux (Debian, Ubuntu, Kali...) | Windows |
|---|---|---|
| Shell | Any terminal with Bash | **Git Bash** (comes with [Git for Windows](https://git-scm.com/downloads)) |
| Go 1.21+ | `sudo apt install golang-go` | Installed by `setup.sh` with winget |
| Nmap | `sudo apt install nmap` | Installed by `setup.sh` with winget, or from [nmap.org](https://nmap.org/download.html) (with Npcap) |

`setup.sh` installs subfinder, dnsx and httpx with `go install`. You do not need to install them yourself. macOS should work with `brew install go nmap`, but it is not tested.

### Steps

1. Open a terminal: **Git Bash** on Windows, any terminal on Linux.
2. Clone the repository and enter the folder:
   ```bash
   git clone https://github.com/umbyx-ai/NetWriath.git
   cd NetWriath
   ```
3. Run the setup:
   ```bash
   bash setup.sh
   ```
   It only installs what is missing, so it is safe to run again. It also creates the **`netwriath` command** and adds the Go tools folder (and Nmap, on Windows) to your `PATH`. To update subfinder, dnsx and httpx later, use `bash setup.sh --update`.
4. Open a **new** terminal. The ones that were already open do not see the new `PATH`.
5. Launch NetWriath from any folder:
   ```bash
   netwriath
   ```

### The `netwriath` command

| System | How it works | Where it works |
|---|---|---|
| Windows | `setup.sh` adds the project's `bin` folder to your user `PATH`. `bin\netwriath.cmd` runs `netwriath.sh` with Git Bash. | Git Bash, PowerShell, cmd |
| Linux / macOS | `setup.sh` adds the project's `bin` folder to your `PATH` in `~/.bashrc` (or `~/.zshrc`). | Any terminal |

You can launch it from any folder: the results are always saved in `outputs/` inside the NetWriath folder. Without the command, `bash netwriath.sh` from the project folder still works.

### Uninstall

```bash
bash setup.sh --uninstall
```

This removes the `netwriath` command from your `PATH`. Your results, Nmap and the Go tools are not touched. To remove NetWriath completely, also delete its folder.

---

## 🎯 Usage

### Interactive menu

```bash
netwriath
```

- **[1] Deploy Mission** asks for a target. You can type `example.com`, `https://www.example.com/page` or `*.example.com`; NetWriath extracts the domain. Anything that is not a valid domain is rejected.
- **[2] Purge Database** deletes every saved result, after asking you to confirm.
- **[3] Disconnect** exits.

### Command line

```bash
netwriath [options] domain
```

| Option | Effect |
|---|---|
| `-y`, `--yes` | Asks nothing. You confirm that you are authorized to scan the target. |
| `--full-ports` | Scans all 65535 TCP ports instead of the top 1000 (much slower). |
| `--no-ports` | Skips phase 4: only discovery, DNS and web probing. |
| `--include-cdn` | Also scans IPs that belong to a CDN. |
| `-h`, `--help` | Shows the help. |
| `-V`, `--version` | Shows the version. |

Examples:

```bash
netwriath --no-ports example.com
```
```bash
netwriath -y --full-ports scanme.nmap.org
```

`scanme.nmap.org` is a host that the Nmap project lets everyone scan for testing. Please do not scan it more than a few times a day.

### Where the results go

```text
outputs/
└── example.com/
    ├── Final_Report.md               latest report
    ├── Final_Report_20261117-163555.md   previous runs are kept, never overwritten
    ├── raw/                          subdomains.txt, dnsx.json, httpx.json, nmap.gnmap, ...
    └── logs/                         error output of every tool
```

`outputs/` is in `.gitignore`, so your results are never committed by accident.

### Sample report

```markdown
## Open ports

| IP | Port | Service | Version |
|---|---|---|---|
| 45.33.32.156 | 22/tcp | ssh | OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0) |
| 45.33.32.156 | 53/tcp | domain | Unbound |
| 45.33.32.156 | 80/tcp | http | Apache httpd 2.4.7 ((Ubuntu)) |
| 45.33.32.156 | 9929/tcp | nping-echo | Nping echo |
```

### Getting more subdomains

subfinder works without configuration, but many of its sources (Shodan, Censys, VirusTotal, SecurityTrails...) only answer with a free API key. Add your keys to subfinder's `provider-config.yaml`. Its location is printed by `subfinder -version`.

---

## 🛠️ Troubleshooting

| Problem | Solution |
|---|---|
| `netwriath: command not found` / *"no se reconoce como nombre de un cmdlet"* | Open a **new** terminal after `bash setup.sh`. If it still fails, run `bash setup.sh` again from the NetWriath folder, or launch it with `bash netwriath.sh`. |
| PowerShell asks *"Terminate batch job (Y/N)?"* after Ctrl+C | That is how Windows stops `.cmd` launchers. Answer `Y`. |
| `subfinder: not installed or not in your PATH` | Run `bash setup.sh` and open a **new** terminal. |
| `httpx: '/usr/bin/httpx' is the Python httpx client` (Kali) | Kali's `httpx` package is a different program. Install ProjectDiscovery's with `sudo apt install httpx-toolkit` or `bash setup.sh`; NetWriath finds it by itself. |
| `installed but the system refuses to run it` (Windows 11) | **Smart App Control** or your antivirus is blocking an unsigned program. NetWriath skips the phase that needs it and tells you so in the report (without subfinder it only checks the domain you typed; without dnsx it cannot run). Windows decides with an online reputation check that changes over time, so a fresh build is sometimes allowed: `bash setup.sh --update`. That is a Windows security setting, and NetWriath does not change it. The easiest alternative is to run NetWriath inside **WSL** (Ubuntu or Kali), where it works as on Linux. |
| `nmap: not installed` on Windows, but Nmap is installed | NetWriath looks for it in `C:\Program Files (x86)\Nmap` and `C:\Program Files\Nmap`. If you installed it elsewhere, add that folder to your `PATH`. |
| `nmap exited with code 1` | Read `logs/nmap.err`. On Windows, Nmap needs **Npcap** ([npcap.com](https://npcap.com)). |
| Few or no subdomains | Add API keys to subfinder (see above), and check `logs/subfinder.log`. |

---

## 🧪 Tests

```bash
bash tests/run_tests.sh
```

The tests do not use the network or scan anything; they run the pipeline with fake tools. On Windows they also check the `PATH` changes on a temporary registry key, never on your real `PATH`. GitHub Actions runs them on Linux and Windows with every push, together with ShellCheck.

---

## ⚠️ Disclaimer

NetWriath is intended strictly for authorized security testing and education. Scanning systems without permission is illegal in many countries. You are responsible for complying with the law and with the scope of your engagement. The author assumes no liability for misuse or damages.

## 📄 License

[MIT](LICENSE) © umbyx-ai

*Created by [umbyx-ai](https://github.com/umbyx-ai)* 👻
