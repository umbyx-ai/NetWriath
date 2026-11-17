#!/usr/bin/env bash
# NetWriath setup: installs the tools NetWriath needs (Go, Nmap, subfinder, dnsx, httpx).
# Works on Linux, macOS and Windows (Git Bash). Safe to run again: it only installs
# what is missing or broken.
#
# Usage: bash setup.sh            install what is missing
#        bash setup.sh --update   also update subfinder, dnsx and httpx to the latest version

if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; CYAN=$'\033[0;36m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; CYAN=""; NC=""
fi

ok()   { printf '%s[OK]%s %s\n' "$GREEN" "$NC" "$*"; }
info() { printf '%s[*]%s %s\n' "$CYAN" "$NC" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$NC" "$*"; }
err()  { printf '%s[ERROR]%s %s\n' "$RED" "$NC" "$*"; }

case "$OSTYPE" in
    msys*|cygwin*) OS=windows ;;
    darwin*)       OS=macos ;;
    *)             OS=linux ;;
esac

case "$(basename "${SHELL:-bash}")" in
    zsh) RC_FILE="$HOME/.zshrc" ;;
    *)   RC_FILE="$HOME/.bashrc" ;;
esac

MARK="# added by NetWriath setup"
MIN_GO_MINOR=21   # Go >= 1.21 downloads the newer toolchain the tools need by itself
UPDATE=0
FAILED=()
WARNINGS=0
BLOCKED_MSG="the system refuses to run it (on Windows 11: Smart App Control or your antivirus blocks unsigned programs)"

GO_TOOLS=(
    "subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "dnsx|github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "httpx|github.com/projectdiscovery/httpx/cmd/httpx@latest"
)

# --- PATH handling -----------------------------------------------------------------

in_path() { case ":$PATH:" in *":$1:"*) return 0 ;; *) return 1 ;; esac; }

# Add a directory to the PATH of this run only (e.g. right after winget installs something)
add_session_path() { [[ -d "$1" ]] && ! in_path "$1" && PATH="$PATH:$1"; export PATH; }

# Add a directory to PATH now and, permanently, in the shell startup file.
add_path_line() {
    local dir="$1"
    in_path "$dir" || PATH="$PATH:$dir"
    export PATH
    if ! grep -qF "\"\$PATH:$dir\"" "$RC_FILE" 2>/dev/null; then
        [[ -s "$RC_FILE" ]] && printf '\n' >> "$RC_FILE"
        printf 'export PATH="$PATH:%s"  %s\n' "$dir" "$MARK" >> "$RC_FILE"
        ok "Added $dir to your PATH in $RC_FILE"
    fi
}

# Older versions of this script wrote the Windows-style GOPATH into .bashrc
# ("export PATH=$PATH:C:\Users\you\go/bin"). Bash eats the backslashes and the
# entry becomes "C:Usersyougo/bin", which points nowhere. Remove those lines.
fix_broken_path_lines() {
    local pattern='^export PATH=\$PATH:[A-Za-z]:\\.*/bin$'
    [[ -f "$RC_FILE" ]] || return 0
    grep -qE "$pattern" "$RC_FILE" || return 0
    cp -- "$RC_FILE" "$RC_FILE.netwriath.bak"
    grep -vE "$pattern" "$RC_FILE.netwriath.bak" > "$RC_FILE"
    ok "Removed a broken PATH line left by an older NetWriath setup (backup: $RC_FILE.netwriath.bak)"
}

# --- Checks ------------------------------------------------------------------------

# tool_state NAME GOBIN -> 0 works, 1 missing, 2 installed but blocked by the system
tool_state() {
    local name="$1" gobin="$2" c rc out result=1 candidates
    if [[ $name == httpx ]]; then
        candidates=(httpx-toolkit "$gobin/httpx" httpx)   # "httpx" may be the Python client
    else
        candidates=("$gobin/$name" "$name")
    fi
    for c in "${candidates[@]}"; do
        command -v "$c" >/dev/null 2>&1 || continue
        out="$("$c" -h 2>&1)"; rc=$?
        if (( rc == 126 )); then result=2; continue; fi
        [[ $name != httpx ]] && return 0
        grep -q -- '-status-code' <<<"$out" && return 0
    done
    return $result
}

winget_install() {
    if ! command -v winget >/dev/null 2>&1; then
        err "winget is not available. Install $1 by hand."
        return 1
    fi
    info "Installing $1 with winget..."
    winget install --id "$1" -e --silent --accept-package-agreements --accept-source-agreements
}

ensure_go() {
    local version minor
    [[ $OS == windows ]] && add_session_path "/c/Program Files/Go/bin"
    if ! command -v go >/dev/null 2>&1; then
        case $OS in
            windows) winget_install GoLang.Go && add_session_path "/c/Program Files/Go/bin" ;;
            macos)   err "Go is missing. Install it with: brew install go" ;;
            linux)   err "Go is missing. Install it with: sudo apt install golang-go  (or from https://go.dev/dl)" ;;
        esac
    fi
    if ! command -v go >/dev/null 2>&1; then
        FAILED+=("Go")
        return 1
    fi
    version="$(go env GOVERSION 2>/dev/null)"          # e.g. go1.27.0
    minor="$(printf '%s' "$version" | sed -E 's/^go1\.([0-9]+).*/\1/')"
    if [[ "$minor" =~ ^[0-9]+$ ]] && (( minor < MIN_GO_MINOR )); then
        err "$version is too old: the tools need Go 1.$MIN_GO_MINOR or newer. Get it from https://go.dev/dl"
        FAILED+=("Go (too old)")
        return 1
    fi
    ok "Go: $version"
}

ensure_nmap() {
    local dir
    if [[ $OS == windows ]] && ! command -v nmap >/dev/null 2>&1; then
        for dir in "/c/Program Files (x86)/Nmap" "/c/Program Files/Nmap"; do
            [[ -x "$dir/nmap.exe" ]] && { add_path_line "$dir"; break; }
        done
        if ! command -v nmap >/dev/null 2>&1; then
            winget_install Insecure.Nmap
            for dir in "/c/Program Files (x86)/Nmap" "/c/Program Files/Nmap"; do
                [[ -x "$dir/nmap.exe" ]] && { add_path_line "$dir"; break; }
            done
        fi
    fi
    if command -v nmap >/dev/null 2>&1; then
        ok "Nmap: $(nmap --version 2>/dev/null | head -n 1)"
        return 0
    fi
    case $OS in
        windows) err "Nmap is missing. Install it from https://nmap.org/download.html (with Npcap)." ;;
        macos)   err "Nmap is missing. Install it with: brew install nmap" ;;
        linux)   err "Nmap is missing. Install it with: sudo apt install nmap" ;;
    esac
    FAILED+=("Nmap")
}

install_go_tools() {
    local gobin entry name pkg state
    gobin="$(go env GOPATH)/bin"
    command -v cygpath >/dev/null 2>&1 && gobin="$(cygpath -u "$gobin")"
    in_path "$gobin" || PATH="$PATH:$gobin"

    for entry in "${GO_TOOLS[@]}"; do
        name="${entry%%|*}"; pkg="${entry#*|}"
        tool_state "$name" "$gobin"; state=$?
        if (( state == 0 && ! UPDATE )); then
            ok "$name is already installed"
            continue
        fi
        if (( state == 2 && ! UPDATE )); then
            warn "$name is installed but $BLOCKED_MSG."
            warn "NetWriath will skip the phase that needs it. See 'Troubleshooting' in the README."
            WARNINGS=$((WARNINGS + 1))
            continue
        fi
        info "Installing $name (this can take a few minutes)..."
        if ! go install "$pkg"; then
            err "go install failed for $name"
            FAILED+=("$name")
            continue
        fi
        tool_state "$name" "$gobin"; state=$?
        if (( state == 2 )); then
            warn "$name was installed but $BLOCKED_MSG."
            warn "NetWriath will skip the phase that needs it. See 'Troubleshooting' in the README."
            WARNINGS=$((WARNINGS + 1))
        else
            ok "$name installed"
        fi
    done

    # Make the Go bin folder permanent unless the PATH already had it
    case ":$ORIGINAL_PATH:" in
        *":$gobin:"*) ;;
        *) add_path_line "$gobin" ;;
    esac
}

check_httpx_name() {
    local found out rc
    found="$(command -v httpx 2>/dev/null)"
    [[ -n "$found" ]] || return 0
    out="$("$found" -h 2>&1)"; rc=$?
    (( rc == 126 )) && return 0      # blocked: already reported
    if ! grep -q -- '-status-code' <<<"$out"; then
        warn "'$found' is the Python httpx client, not ProjectDiscovery's."
        warn "NetWriath finds the right one by itself (httpx-toolkit or the one in your Go folder)."
    fi
}

# --- Main --------------------------------------------------------------------------

main() {
    case "${1:-}" in
        --update) UPDATE=1 ;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        "") ;;
        *) err "Unknown option: $1"; exit 2 ;;
    esac

    ORIGINAL_PATH="$PATH"
    printf '%s--- NetWriath setup (%s) ---%s\n' "$CYAN" "$OS" "$NC"
    fix_broken_path_lines
    ensure_nmap
    if ensure_go; then
        install_go_tools
        check_httpx_name
    fi

    echo ""
    if (( ${#FAILED[@]} > 0 )); then
        err "Setup incomplete. Missing: ${FAILED[*]}"
        err "Fix the errors above and run 'bash setup.sh' again."
        exit 1
    fi
    if (( WARNINGS > 0 )); then
        printf '%s--- Setup complete, with %s warning(s): read them above ---%s\n' "$YELLOW" "$WARNINGS" "$NC"
    else
        printf '%s--- Setup complete ---%s\n' "$GREEN" "$NC"
    fi
    info "Open a NEW terminal (or run: source $RC_FILE) and launch: bash netwriath.sh"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
