#!/usr/bin/env bash
# ============================================================
#  N E T   W R I A T H
#  Automated asset discovery for authorized engagements
# ============================================================
#
#  Usage: bash netwriath.sh [options] [domain]
#  Without a domain the interactive menu opens. Run with --help for the options.

VERSION="6.0"

# --- Colors (disabled when the output is not a terminal) ---
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    CYAN=$'\033[0;36m'; WHITE=$'\033[1;37m'; GRAY=$'\033[0;90m'; NC=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; CYAN=""; WHITE=""; GRAY=""; NC=""
fi

# --- Paths ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE="${NETWRIATH_OUTPUT:-$PROJECT_DIR/outputs}"

# --- Options (changed by the command line) ---
ASSUME_YES=0     # -y: no confirmations
FULL_PORTS=0     # --full-ports: all 65535 TCP ports
SKIP_PORTS=0     # --no-ports: skip phase 4
INCLUDE_CDN=0    # --include-cdn: also scan CDN IPs

# --- Run state ---
TARGET_DOMAIN=""; TARGET_DIR=""; REPORT_FILE=""; RAW_DIR=""; LOG_DIR=""; TEMP_DIR=""
HTTPX_BIN=""; HTTPX_PROBLEM=""; NMAP_PROBLEM=""; TOOL_PROBLEM=""
WILDCARD=0; PORT_SCAN_DESC=""; CDN_SKIPPED=0
WEB_DONE=0; PORTS_DONE=0   # 1 when phase 3 / phase 4 actually ran
NOTES=()

# ============================================================
#  Output helpers
# ============================================================

info() { printf '%s[*]%s %s\n' "$CYAN" "$NC" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$GREEN" "$NC" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$NC" "$*"; }
err()  { printf '%s[x]%s %s\n' "$RED" "$NC" "$*" >&2; }

phase_start() { printf '%s[*] Phase %s: %-16s%s' "$YELLOW" "$1" "$2..." "$NC"; }
phase_ok()    { printf '%sSuccess%s%s\n' "$GREEN" "$NC" "${1:+ ${GRAY}($1)${NC}}"; }
phase_warn()  { printf '%sWarning%s %s\n' "$YELLOW" "$NC" "$1"; NOTES+=("$1"); }
phase_fail()  { printf '%sFailed%s %s\n' "$RED" "$NC" "$1"; NOTES+=("$1"); }
phase_skip()  { printf '%sSkipped%s %s\n' "$GRAY" "$NC" "$1"; }

# confirm "question" -> success only if the answer is y/yes
confirm() {
    local answer
    printf '%s%s (y/N): %s' "$WHITE" "$1" "$NC"
    read -r answer || return 1
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

count_lines() { if [[ -s "$1" ]]; then wc -l < "$1" | tr -d ' '; else echo 0; fi; }

# ============================================================
#  Input validation
# ============================================================

# normalize_target "https://Sub.Example.com/path" -> "sub.example.com"
# Fails for anything that is not a plain domain name, so the result is always
# safe to use as a folder name (no "/", no "..", no spaces).
normalize_target() {
    local t re
    t="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    t="${t#"${t%%[![:space:]]*}"}"    # leading spaces
    t="${t%"${t##*[![:space:]]}"}"    # trailing spaces
    t="${t#*://}"      # scheme
    t="${t%%/*}"       # path
    t="${t%%\?*}"      # query
    t="${t%%#*}"       # fragment
    t="${t##*@}"       # user@
    t="${t%%:*}"       # :port
    t="${t#\*.}"       # *.wildcard
    t="${t%.}"         # trailing dot
    (( ${#t} > 0 && ${#t} <= 253 )) || return 1
    re='^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+([a-z]{2,63}|xn--[a-z0-9-]{1,59})$'
    [[ "$t" =~ $re ]] || return 1
    printf '%s\n' "$t"
}

# Escape text for a Markdown table cell
md_cell() {
    local s="${1//$'\r'/}"
    s="${s//|/\\|}"
    printf '%s' "${s:--}"
}

# ============================================================
#  JSON lines -> TSV (dnsx and httpx speak JSON; no jq needed)
# ============================================================

# json_tsv FILE key1 key2 ...   prints one TSV row per JSON line.
# Strings are unescaped, arrays are joined with ", ", missing keys are empty.
json_tsv() {
    local file="$1"; shift
    awk -v keys="$*" '
    function ucode(h) {
        h = tolower(h)
        if (h == "0026") return "&"
        if (h == "003c") return "<"
        if (h == "003e") return ">"
        if (h == "0027") return "\047"
        if (h == "0022") return "\""
        return "?"
    }
    function jstr(s, i,    out, c, n) {          # s[i] is the opening quote
        out = ""; i++; n = length(s)
        while (i <= n) {
            c = substr(s, i, 1)
            if (c == "\\") {
                c = substr(s, i + 1, 1); i += 2
                if (c == "u") { out = out ucode(substr(s, i, 4)); i += 4 }
                else if (c == "n" || c == "t" || c == "r") out = out " "
                else out = out c
                continue
            }
            if (c == "\"") { JPOS = i + 1; return out }
            out = out c; i++
        }
        JPOS = i; return out
    }
    function jget(s, key,    i, c, out, v) {
        i = index(s, "\"" key "\":")
        if (i == 0) return ""
        i += length(key) + 3
        while (substr(s, i, 1) == " ") i++
        c = substr(s, i, 1)
        if (c == "\"") return jstr(s, i)
        if (c == "[") {
            out = ""; i++
            while (i <= length(s)) {
                c = substr(s, i, 1)
                if (c == "]") break
                if (c == "\"") { v = jstr(s, i); i = JPOS; out = out (out == "" ? "" : ", ") v; continue }
                i++
            }
            return out
        }
        out = ""
        while (i <= length(s)) {
            c = substr(s, i, 1)
            if (c == "," || c == "}") break
            out = out c; i++
        }
        return out
    }
    BEGIN { n = split(keys, K, " ") }
    /^[ \t]*\{/ {
        row = ""
        for (k = 1; k <= n; k++) {
            v = jget($0, K[k]); gsub(/\t/, " ", v)
            row = row (k > 1 ? "\t" : "") v
        }
        print row
    }' "$file"
}

# parse_gnmap FILE  ->  ip<TAB>port/proto<TAB>service<TAB>version  (open ports only)
parse_gnmap() {
    awk -F'\t' '
    /Ports: / {
        ip = $1; sub(/^Host: /, "", ip); sub(/ .*/, "", ip)
        for (i = 1; i <= NF; i++) {
            if ($i !~ /^Ports: /) continue
            p = $i; sub(/^Ports: /, "", p)
            n = split(p, entries, "/, ")
            for (j = 1; j <= n; j++) {
                e = entries[j]; sub(/\/$/, "", e)
                split(e, f, "/")
                if (f[2] == "open") print ip "\t" f[1] "/" f[3] "\t" f[5] "\t" f[7]
            }
        }
    }' "$1"
}

# ============================================================
#  Tools
# ============================================================

add_to_path() {
    [[ -d "$1" ]] || return 0
    case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac
}

go_bin_dir() {
    local dir
    command -v go >/dev/null 2>&1 || return 1
    dir="$(go env GOPATH 2>/dev/null)" || return 1
    [[ -n "$dir" ]] || return 1
    command -v cygpath >/dev/null 2>&1 && dir="$(cygpath -u "$dir")"
    printf '%s/bin\n' "$dir"
}

# Find tools that are installed but not on the PATH of this shell
# (Go binaries, and Nmap on Windows, whose installer does not touch Git Bash).
locate_tools() {
    local gobin
    add_to_path "$HOME/go/bin"
    gobin="$(go_bin_dir)" && add_to_path "$gobin"
    add_to_path "/c/Program Files (x86)/Nmap"
    add_to_path "/c/Program Files/Nmap"
    export PATH
}

# tool_works name args... -> success if the program exists and can be executed.
# Sets TOOL_PROBLEM with a human explanation when it cannot.
tool_works() {
    local rc
    if ! command -v "$1" >/dev/null 2>&1; then
        TOOL_PROBLEM="not installed or not in your PATH (run: bash setup.sh)"
        return 1
    fi
    "$@" >/dev/null 2>&1; rc=$?
    if (( rc == 126 )); then
        TOOL_PROBLEM="installed but the system refuses to run it (on Windows 11, Smart App Control or your antivirus blocks unsigned programs)"
        return 1
    fi
    return 0
}

# Kali and some distros ship the Python "httpx" client under the same name as
# ProjectDiscovery's httpx. Pick the right one.
find_httpx() {
    local candidates=(httpx-toolkit) c out rc gobin
    HTTPX_BIN=""
    HTTPX_PROBLEM="not installed or not in your PATH (run: bash setup.sh)"
    gobin="$(go_bin_dir)" && candidates+=("$gobin/httpx")
    candidates+=("$HOME/go/bin/httpx" httpx)
    for c in "${candidates[@]}"; do
        command -v "$c" >/dev/null 2>&1 || continue
        out="$("$c" -h 2>&1)"; rc=$?
        if grep -q -- '-status-code' <<<"$out"; then
            HTTPX_BIN="$c"
            return 0
        fi
        if (( rc == 126 )); then
            HTTPX_PROBLEM="installed but the system refuses to run it (on Windows 11, Smart App Control or your antivirus blocks unsigned programs)"
        else
            HTTPX_PROBLEM="'$c' is the Python httpx client, not ProjectDiscovery's (on Kali: sudo apt install httpx-toolkit)"
        fi
    done
    return 1
}

check_dependencies() {
    local problems=() fatal=0 p
    locate_tools
    tool_works subfinder -version || { problems+=("subfinder: $TOOL_PROBLEM"); fatal=1; }
    tool_works dnsx -version      || { problems+=("dnsx: $TOOL_PROBLEM"); fatal=1; }
    find_httpx                    || problems+=("httpx: $HTTPX_PROBLEM -> phase 3 will be skipped")
    NMAP_PROBLEM=""
    if (( ! SKIP_PORTS )); then
        if ! tool_works nmap --version; then
            NMAP_PROBLEM="$TOOL_PROBLEM"
            problems+=("nmap: $TOOL_PROBLEM -> phase 4 will be skipped")
        fi
    fi
    (( ${#problems[@]} == 0 )) && return 0

    echo ""
    for p in "${problems[@]}"; do warn "$p"; done
    if (( fatal )); then
        err "NetWriath cannot run without subfinder and dnsx."
        return 1
    fi
    (( ASSUME_YES )) && return 0
    confirm "Continue without those phases?"
}

# ============================================================
#  Mission
# ============================================================

setup_target() {
    local old stamp
    TARGET_DOMAIN="$1"                      # already validated by normalize_target
    TARGET_DIR="$OUTPUT_BASE/$TARGET_DOMAIN"
    REPORT_FILE="$TARGET_DIR/Final_Report.md"
    RAW_DIR="$TARGET_DIR/raw"
    LOG_DIR="$TARGET_DIR/logs"
    TEMP_DIR="$TARGET_DIR/tmp"

    # Keep the previous report instead of deleting it
    if [[ -f "$REPORT_FILE" ]]; then
        stamp="$(date -r "$REPORT_FILE" '+%Y%m%d-%H%M%S' 2>/dev/null || date '+%Y%m%d-%H%M%S')"
        old="$TARGET_DIR/Final_Report_$stamp.md"
        mv -- "$REPORT_FILE" "$old"
        info "Previous report kept as $(basename "$old")"
    fi
    rm -rf -- "$RAW_DIR" "$LOG_DIR" "$TEMP_DIR"
    mkdir -p "$RAW_DIR" "$LOG_DIR" "$TEMP_DIR"

    NOTES=(); WILDCARD=0; CDN_SKIPPED=0; PORT_SCAN_DESC=""; WEB_DONE=0; PORTS_DONE=0
}

cleanup_temp() {
    [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]] && rm -rf -- "$TEMP_DIR"
}

on_interrupt() {
    echo ""
    warn "Interrupted. Temporary files removed."
    cleanup_temp
    exit 130
}

phase_discovery() {
    local raw="$TEMP_DIR/subfinder.txt" re rc n
    phase_start 1 "Discovery"
    subfinder -d "$TARGET_DOMAIN" -silent > "$raw" 2> "$LOG_DIR/subfinder.log"; rc=$?
    re="(^|\\.)${TARGET_DOMAIN//./\\.}\$"
    {
        printf '%s\n' "$TARGET_DOMAIN"
        tr -d '\r' < "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/^\*\.//' | grep -E "$re"
    } | sort -u > "$RAW_DIR/subdomains.txt"
    n="$(count_lines "$RAW_DIR/subdomains.txt")"
    if (( rc != 0 )); then
        phase_fail "subfinder exited with code $rc (see logs/subfinder.log); only $n host(s) to check"
    else
        phase_ok "$n host(s)"
    fi
}

phase_resolution() {
    local rc probes
    phase_start 2 "Resolution"
    dnsx -l "$RAW_DIR/subdomains.txt" -a -cdn -json -silent > "$RAW_DIR/dnsx.json" 2> "$LOG_DIR/dnsx.log"; rc=$?

    # host <TAB> ips <TAB> cdn
    json_tsv "$RAW_DIR/dnsx.json" host a cdn-name | awk -F'\t' '$1 != "" && $2 != ""' | sort -u > "$TEMP_DIR/resolved.tsv"

    # Wildcard DNS: if random names resolve, many "subdomains" may not really exist
    probes="nw-$RANDOM$RANDOM-probe.$TARGET_DOMAIN"$'\n'"nw-$RANDOM$RANDOM-probe.$TARGET_DOMAIN"
    printf '%s\n' "$probes" | dnsx -a -resp-only -silent 2>/dev/null | tr -d '\r' | sort -u > "$TEMP_DIR/wildcard_ips.txt"
    [[ -s "$TEMP_DIR/wildcard_ips.txt" ]] && WILDCARD=1

    # host <TAB> ips <TAB> cdn <TAB> note
    awk -F'\t' -v OFS='\t' -v apex="$TARGET_DOMAIN" '
        FILENAME == ARGV[1] { wild[$1] = 1; nwild++; next }
        {
            note = ""
            if ($1 != apex && nwild > 0) {
                n = split($2, ips, ", "); all = 1
                for (i = 1; i <= n; i++) if (!(ips[i] in wild)) all = 0
                if (all) note = "wildcard?"
            }
            print $1, $2, $3, note
        }' "$TEMP_DIR/wildcard_ips.txt" "$TEMP_DIR/resolved.tsv" > "$RAW_DIR/resolved.tsv"

    # ip <TAB> cdn
    awk -F'\t' -v OFS='\t' '{ n = split($2, ips, ", "); for (i = 1; i <= n; i++) print ips[i], $3 }' "$RAW_DIR/resolved.tsv" \
        | sort -t$'\t' -k1,1 -u | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n > "$RAW_DIR/ips.tsv"

    if (( rc != 0 )); then
        phase_fail "dnsx exited with code $rc (see logs/dnsx.log)"
    elif (( WILDCARD )); then
        phase_warn "wildcard DNS detected: any name under $TARGET_DOMAIN resolves, hosts marked 'wildcard?' may not exist"
    else
        phase_ok "$(count_lines "$RAW_DIR/resolved.tsv") of $(count_lines "$RAW_DIR/subdomains.txt") hosts resolve, $(count_lines "$RAW_DIR/ips.tsv") IP(s)"
    fi
}

phase_web() {
    local rc
    phase_start 3 "Web probing"
    : > "$RAW_DIR/web.tsv"
    if [[ -z "$HTTPX_BIN" ]]; then
        phase_skip "(httpx unavailable, see warnings)"
        NOTES+=("Phase 3 skipped: httpx $HTTPX_PROBLEM")
        return
    fi
    if [[ ! -s "$RAW_DIR/resolved.tsv" ]]; then
        phase_skip "(no host resolved)"
        return
    fi
    cut -f1 "$RAW_DIR/resolved.tsv" > "$TEMP_DIR/hosts.txt"
    "$HTTPX_BIN" -l "$TEMP_DIR/hosts.txt" -silent -nc -json -sc -title -td -server \
        > "$RAW_DIR/httpx.json" 2> "$LOG_DIR/httpx.log"; rc=$?
    WEB_DONE=1
    # url <TAB> status <TAB> title <TAB> server <TAB> tech
    json_tsv "$RAW_DIR/httpx.json" url status_code title webserver tech | awk -F'\t' '$1 != ""' | sort -u > "$RAW_DIR/web.tsv"
    if (( rc != 0 )); then
        phase_fail "httpx exited with code $rc (see logs/httpx.log)"
    else
        phase_ok "$(count_lines "$RAW_DIR/web.tsv") live web service(s)"
    fi
}

phase_ports() {
    local rc answer scan_list="$TEMP_DIR/scan_ips.txt" port_args n
    phase_start 4 "Port scan"
    : > "$RAW_DIR/ports.tsv"

    if (( SKIP_PORTS )); then
        PORT_SCAN_DESC="skipped (--no-ports)"; phase_skip "(--no-ports)"; return
    fi
    if [[ -n "$NMAP_PROBLEM" ]]; then
        PORT_SCAN_DESC="skipped (nmap unavailable)"; phase_skip "(nmap unavailable, see warnings)"
        NOTES+=("Phase 4 skipped: nmap $NMAP_PROBLEM"); return
    fi

    # IPs behind a CDN are shared with thousands of other sites: skip them by default
    if (( INCLUDE_CDN )); then
        cut -f1 "$RAW_DIR/ips.tsv" > "$scan_list"
    else
        awk -F'\t' '$2 == "" { print $1 }' "$RAW_DIR/ips.tsv" > "$scan_list"
        CDN_SKIPPED="$(awk -F'\t' '$2 != ""' "$RAW_DIR/ips.tsv" | wc -l | tr -d ' ')"
    fi
    n="$(count_lines "$scan_list")"
    if (( n == 0 )); then
        if (( CDN_SKIPPED > 0 )); then
            PORT_SCAN_DESC="skipped (all $CDN_SKIPPED IPs are behind a CDN; use --include-cdn to scan them)"
        else
            PORT_SCAN_DESC="skipped (no IP to scan)"
        fi
        phase_skip "(${PORT_SCAN_DESC#skipped (}"; return
    fi

    if (( FULL_PORTS )); then
        port_args=(-p-); PORT_SCAN_DESC="all 65535 TCP ports + service versions"
    else
        port_args=(--top-ports 1000); PORT_SCAN_DESC="top 1000 TCP ports + service versions"
    fi

    # Active step: needs explicit authorization
    if (( ! ASSUME_YES )); then
        echo ""
        warn "Phase 4 sends packets to $n IP(s):"
        sed 's/^/        /' "$scan_list"
        (( CDN_SKIPPED > 0 )) && info "$CDN_SKIPPED IP(s) behind a CDN skipped (use --include-cdn to scan them)."
        printf '%s    Do you have written authorization to scan them? Type "yes" to continue: %s' "$WHITE" "$NC"
        read -r answer
        if [[ "$answer" != "yes" ]]; then
            PORT_SCAN_DESC="skipped (not authorized)"
            printf '    '; phase_skip "(authorization not confirmed)"; return
        fi
        printf '    %s[*] Phase 4: %-16s%s' "$YELLOW" "Port scan..." "$NC"
    fi

    nmap -iL "$scan_list" -Pn --open -sV "${port_args[@]}" \
        -oG "$RAW_DIR/nmap.gnmap" -oN "$LOG_DIR/nmap.txt" > /dev/null 2> "$LOG_DIR/nmap.err"; rc=$?
    PORTS_DONE=1
    [[ -f "$RAW_DIR/nmap.gnmap" ]] && parse_gnmap "$RAW_DIR/nmap.gnmap" > "$RAW_DIR/ports.tsv"
    if (( rc != 0 )); then
        phase_fail "nmap exited with code $rc (see logs/nmap.err)"
    else
        phase_ok "$(count_lines "$RAW_DIR/ports.tsv") open ports on $n IP(s)"
    fi
}

write_report() {
    local host ips cdn note url status title server tech ip port service version
    local n_subs n_res n_web n_ips n_ports n_unres
    n_subs="$(count_lines "$RAW_DIR/subdomains.txt")"
    n_res="$(count_lines "$RAW_DIR/resolved.tsv")"
    n_web="$(count_lines "$RAW_DIR/web.tsv")"
    n_ips="$(count_lines "$RAW_DIR/ips.tsv")"
    n_ports="$(count_lines "$RAW_DIR/ports.tsv")"
    cut -f1 "$RAW_DIR/resolved.tsv" | sort -u > "$TEMP_DIR/resolved_hosts.txt"
    sort -u "$RAW_DIR/subdomains.txt" | comm -23 - "$TEMP_DIR/resolved_hosts.txt" > "$TEMP_DIR/unresolved.txt"
    n_unres="$(count_lines "$TEMP_DIR/unresolved.txt")"

    {
        printf '# NetWriath report: %s\n\n' "$TARGET_DOMAIN"
        printf '| | |\n|---|---|\n'
        printf '| Date | %s |\n' "$(date '+%Y-%m-%d %H:%M (UTC%z)')"
        printf '| NetWriath | v%s |\n' "$VERSION"
        printf '| Port scan | %s |\n\n' "$(md_cell "$PORT_SCAN_DESC")"

        printf '## Summary\n\n'
        printf -- '- **Hosts discovered:** %s\n' "$n_subs"
        printf -- '- **Hosts that resolve:** %s%s\n' "$n_res" "$( (( WILDCARD )) && echo ' (wildcard DNS detected)')"
        printf -- '- **Unique IPs:** %s%s\n' "$n_ips" "$( (( CDN_SKIPPED > 0 )) && echo " ($CDN_SKIPPED behind a CDN, not scanned)")"
        if (( WEB_DONE )); then
            printf -- '- **Live web services:** %s\n' "$n_web"
        else
            printf -- '- **Live web services:** not checked (phase 3 skipped)\n'
        fi
        if (( PORTS_DONE )); then
            printf -- '- **Open ports:** %s\n\n' "$n_ports"
        else
            printf -- '- **Open ports:** not scanned (phase 4 skipped)\n\n'
        fi

        if (( ${#NOTES[@]} > 0 )); then
            printf '## Warnings\n\n'
            for note in "${NOTES[@]}"; do printf -- '- %s\n' "$note"; done
            printf '\n'
        fi

        printf '## Hosts\n\n'
        if [[ -s "$RAW_DIR/resolved.tsv" ]]; then
            printf '| Host | IPs | CDN | Notes |\n|---|---|---|---|\n'
            while IFS=$'\t' read -r host ips cdn note; do
                printf '| %s | %s | %s | %s |\n' "$(md_cell "$host")" "$(md_cell "$ips")" "$(md_cell "$cdn")" "$(md_cell "$note")"
            done < "$RAW_DIR/resolved.tsv"
        else
            printf 'No host resolved.\n'
        fi
        if (( n_unres > 0 )); then
            printf '\n<details><summary>%s host(s) without an A record</summary>\n\n' "$n_unres"
            sed 's/^/- /' "$TEMP_DIR/unresolved.txt"
            printf '\n</details>\n'
        fi
        printf '\n'

        printf '## Web services\n\n'
        if [[ -s "$RAW_DIR/web.tsv" ]]; then
            printf '| URL | Status | Title | Server | Technologies |\n|---|---|---|---|---|\n'
            while IFS=$'\t' read -r url status title server tech; do
                printf '| %s | %s | %s | %s | %s |\n' "$(md_cell "$url")" "$(md_cell "$status")" \
                    "$(md_cell "$title")" "$(md_cell "$server")" "$(md_cell "$tech")"
            done < "$RAW_DIR/web.tsv"
        elif (( WEB_DONE )); then
            printf 'None found.\n'
        else
            printf 'Not checked: phase 3 was skipped.\n'
        fi
        printf '\n'

        printf '## Open ports\n\n'
        if [[ -s "$RAW_DIR/ports.tsv" ]]; then
            printf '| IP | Port | Service | Version |\n|---|---|---|---|\n'
            while IFS=$'\t' read -r ip port service version; do
                printf '| %s | %s | %s | %s |\n' "$(md_cell "$ip")" "$(md_cell "$port")" \
                    "$(md_cell "$service")" "$(md_cell "${version//|//}")"
            done < "$RAW_DIR/ports.tsv"
        elif (( PORTS_DONE )); then
            printf 'None found.\n'
        else
            printf 'Not scanned: %s.\n' "$(md_cell "$PORT_SCAN_DESC")"
        fi
        printf '\n---\n\n_Generated by NetWriath v%s. Raw data in `raw/`, tool logs in `logs/`._\n' "$VERSION"
    } > "$REPORT_FILE"
}

run_mission() {
    echo ""
    printf '%sInit:: Recon on %s%s%s\n' "$RED" "$WHITE" "$TARGET_DOMAIN" "$NC"
    phase_discovery
    phase_resolution
    phase_web
    phase_ports
    phase_start 5 "Report"
    write_report
    cleanup_temp
    phase_ok
    echo ""
    if (( ${#NOTES[@]} > 0 )); then
        warn "Mission finished with ${#NOTES[@]} warning(s): $REPORT_FILE"
    else
        ok "Mission complete: $REPORT_FILE"
    fi
}

# run_target "user input" -> validates, checks tools and runs the five phases
run_target() {
    local target
    if ! target="$(normalize_target "$1")"; then
        err "'$1' is not a valid domain. Use something like: example.com"
        return 1
    fi
    check_dependencies || return 1
    setup_target "$target"
    run_mission
}

purge_outputs() {
    local n
    n="$(find "$OUTPUT_BASE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    if (( n == 0 )); then
        info "Nothing to purge."
        return
    fi
    warn "This deletes the results of $n target(s) in $OUTPUT_BASE."
    if confirm "Delete them?"; then
        rm -rf -- "${OUTPUT_BASE:?}"/*
        ok "Purge successful."
    else
        info "Nothing deleted."
    fi
}

# ============================================================
#  Interface
# ============================================================

usage() {
    cat <<EOF
NetWriath v$VERSION - automated asset discovery for authorized engagements

Usage: bash netwriath.sh [options] [domain]

Without a domain, the interactive menu opens.

Options:
  -y, --yes          do not ask anything (you confirm you are authorized to scan)
      --full-ports   scan all 65535 TCP ports instead of the top 1000
      --no-ports     skip the port scan (phases 1-3 only)
      --include-cdn  also scan IPs that belong to a CDN (shared with other sites)
  -h, --help         show this help
  -V, --version      show the version

Examples:
  bash netwriath.sh example.com
  bash netwriath.sh --no-ports example.com
  bash netwriath.sh -y --full-ports scanme.nmap.org
EOF
}

banner() {
    clear 2>/dev/null
    printf '%s' "$RED"
    cat <<'EOF'
 ███╗   ██╗███████╗████████╗██╗    ██╗██████╗ ██╗ █████╗ ████████╗██╗  ██╗
 ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔══██╗██║██╔══██╗╚══██╔══╝██║  ██║
 ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██████╔╝██║███████║   ██║   ███████║
 ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██╔══██╗██║██╔══██║   ██║   ██║  ██║
 ██║ ╚████║███████╗   ██║   ╚███╔███╔╝██║  ██║██║██║  ██║   ██║   ██║  ██║
 ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
EOF
    printf '%s  Automated Asset Discovery Framework // v%s%s\n\n' "$WHITE" "$VERSION" "$NC"
}

menu() {
    local option target
    while true; do
        banner
        printf ' %s-------------------------------------------------------------------------%s\n' "$RED" "$NC"
        printf ' %s:: [1] Deploy Mission%s\n' "$WHITE" "$NC"
        printf ' %s:: [2] Purge Database%s\n' "$WHITE" "$NC"
        printf ' %s:: [3] Disconnect%s\n' "$RED" "$NC"
        printf ' %s-------------------------------------------------------------------------%s\n\n' "$RED" "$NC"
        printf ' %sOption > %s' "$WHITE" "$NC"
        read -r option || exit 0

        case "$option" in
            1)
                printf '\n %sTarget > %s' "$WHITE" "$NC"
                read -r target || exit 0
                [[ -z "$target" ]] && continue
                run_target "$target"
                printf '\n %sPress Enter to return...%s' "$WHITE" "$NC"
                read -r _
                ;;
            2)
                echo ""
                purge_outputs
                sleep 1
                ;;
            3)
                printf '\n %s[*] Disconnecting...%s\n' "$YELLOW" "$NC"
                exit 0
                ;;
            *)
                printf '\n %s[!] Unknown command%s\n' "$YELLOW" "$NC"
                sleep 1
                ;;
        esac
    done
}

main() {
    local target=""
    while (( $# > 0 )); do
        case "$1" in
            -y|--yes)      ASSUME_YES=1 ;;
            --full-ports)  FULL_PORTS=1 ;;
            --no-ports)    SKIP_PORTS=1 ;;
            --include-cdn) INCLUDE_CDN=1 ;;
            -h|--help)     usage; exit 0 ;;
            -V|--version)  echo "NetWriath v$VERSION"; exit 0 ;;
            -*)            err "Unknown option: $1"; usage >&2; exit 2 ;;
            *)
                if [[ -n "$target" ]]; then err "Only one domain at a time."; exit 2; fi
                target="$1"
                ;;
        esac
        shift
    done

    trap on_interrupt INT TERM
    if [[ -n "$target" ]]; then
        run_target "$target"
        exit $?
    fi
    menu
}

# Run only when executed, not when sourced (the tests source this file)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
