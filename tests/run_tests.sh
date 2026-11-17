#!/usr/bin/env bash
# Offline tests for NetWriath: no network, no scanning.
# Usage: bash tests/run_tests.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export NETWRIATH_OUTPUT="$TMP/outputs"
# shellcheck source=netwriath.sh
source "$ROOT/netwriath.sh"

PASS=0; FAIL=0
check() {  # check "description" expected actual
    if [[ "$2" == "$3" ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        printf 'FAIL: %s\n  expected: %q\n  actual:   %q\n' "$1" "$2" "$3"
    fi
}

# --- normalize_target -----------------------------------------------------------
check "plain domain"        "example.com"         "$(normalize_target "example.com")"
check "uppercase + spaces"  "sub.example.com"     "$(normalize_target "  Sub.Example.COM ")"
check "url with path"       "example.com"         "$(normalize_target "https://example.com/a/b?c=1#x")"
check "port and user"       "example.com"         "$(normalize_target "http://user@example.com:8080/")"
check "path traversal cut"  "example.com"         "$(normalize_target "example.com/../..")"
check "wildcard prefix"     "example.com"         "$(normalize_target "*.example.com")"
check "trailing dot"        "example.com"         "$(normalize_target "example.com.")"
check "punycode tld"        "xn--e1afmkfd.xn--p1ai" "$(normalize_target "xn--e1afmkfd.xn--p1ai")"
for bad in ".." "../../NetWriath" "../outputs" "/" "example" "exa mple.com" "-bad.com" \
           "a..b.com" "1.2.3.4" "" "rm -rf" "\$(id).com" "ex_ample.com" "a.com b.com"; do
    if normalize_target "$bad" >/dev/null; then
        check "rejects '$bad'" "rejected" "accepted: $(normalize_target "$bad")"
    else
        check "rejects '$bad'" "rejected" "rejected"
    fi
done

# --- md_cell --------------------------------------------------------------------
check "md_cell pipe"  'a \| b' "$(md_cell 'a | b')"
check "md_cell empty" '-'      "$(md_cell '')"

# --- json_tsv: real dnsx line ---------------------------------------------------
cat > "$TMP/dnsx.json" <<'EOF'
{"host":"example.com","ttl":86,"resolver":["1.0.0.1:53"],"a":["172.66.147.243","104.20.23.154"],"all":["example.com.\t86\tIN\tA\t172.66.147.243"],"status_code":"NOERROR","cdn":true,"cdn-name":"cloudflare","cdn-type":"waf"}
{"host":"mail.example.com","ttl":300,"a":["203.0.113.7"],"status_code":"NOERROR"}
EOF
check "dnsx row 1" $'example.com\t172.66.147.243, 104.20.23.154\tcloudflare' "$(json_tsv "$TMP/dnsx.json" host a cdn-name | sed -n 1p)"
check "dnsx row 2" $'mail.example.com\t203.0.113.7\t'                     "$(json_tsv "$TMP/dnsx.json" host a cdn-name | sed -n 2p)"

# --- json_tsv: httpx line with escapes ------------------------------------------
cat > "$TMP/httpx.json" <<'EOF'
{"timestamp":"2026-11-17T16:00:00Z","url":"https://example.com","input":"example.com","title":"Tom \u0026 Jerry \"Home\" \\ \u003cb\u003e","webserver":"nginx","tech":["Nginx","HSTS"],"status_code":200,"failed":false}
{"url":"http://old.example.com","title":"","status_code":403,"failed":false}
EOF
check "httpx row 1" $'https://example.com\t200\tTom & Jerry "Home" \\ <b>\tnginx\tNginx, HSTS' \
      "$(json_tsv "$TMP/httpx.json" url status_code title webserver tech | sed -n 1p)"
check "httpx row 2" $'http://old.example.com\t403\t\t\t' \
      "$(json_tsv "$TMP/httpx.json" url status_code title webserver tech | sed -n 2p)"

# --- parse_gnmap: real nmap output ----------------------------------------------
printf '%s\n' \
  '# Nmap 7.99 scan initiated' \
  $'Host: 45.33.32.156 (scanme.nmap.org)\tStatus: Up' \
  $'Host: 45.33.32.156 (scanme.nmap.org)\tPorts: 22/open/tcp//ssh//OpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0)/, 80/open/tcp//http//Apache httpd 2.4.7 ((Ubuntu))/, 5357/open/tcp//http//Microsoft HTTPAPI httpd 2.0 (SSDP|UPnP)/, 9929/filtered/tcp//nping-echo///\tIgnored State: closed (996)' \
  > "$TMP/scan.gnmap"
check "gnmap lines"  "3" "$(parse_gnmap "$TMP/scan.gnmap" | wc -l | tr -d ' ')"
check "gnmap ssh"    $'45.33.32.156\t22/tcp\tssh\tOpenSSH 6.6.1p1 Ubuntu 2ubuntu2.13 (Ubuntu Linux; protocol 2.0)' "$(parse_gnmap "$TMP/scan.gnmap" | sed -n 1p)"
check "gnmap pipe"   $'45.33.32.156\t5357/tcp\thttp\tMicrosoft HTTPAPI httpd 2.0 (SSDP|UPnP)' "$(parse_gnmap "$TMP/scan.gnmap" | sed -n 3p)"

# --- setup_target keeps the previous report and stays inside outputs/ -----------
setup_target "example.com"
echo "old report" > "$REPORT_FILE"
setup_target "example.com"
check "previous report archived" "1" "$(find "$TARGET_DIR" -name 'Final_Report_*.md' | wc -l | tr -d ' ')"
check "target dir inside outputs" "$NETWRIATH_OUTPUT/example.com" "$TARGET_DIR"

# --- full report from canned data (fake tools on PATH) --------------------------
FAKE="$TMP/bin"; mkdir -p "$FAKE"
cat > "$FAKE/subfinder" <<'EOF'
#!/usr/bin/env bash
printf 'www.example.com\nWWW.example.com\n*.dev.example.com\nnot-in-scope.org\nghost.example.com\n'
EOF
cat > "$FAKE/dnsx" <<'EOF'
#!/usr/bin/env bash
if [[ " $* " == *" -json "* ]]; then
  echo '{"host":"example.com","a":["104.20.23.154"],"cdn":true,"cdn-name":"cloudflare"}'
  echo '{"host":"www.example.com","a":["203.0.113.7","203.0.113.8"]}'
  echo '{"host":"dev.example.com","a":["203.0.113.8"]}'
fi
EOF
cat > "$FAKE/nmap" <<'EOF'
#!/usr/bin/env bash
while (( $# )); do [[ $1 == -oG ]] && out=$2; [[ $1 == -iL ]] && list=$2; shift; done
cp "$list" "$(dirname "$out")/scanned_ips.txt"
printf 'Host: 203.0.113.7 ()\tPorts: 443/open/tcp//https//nginx 1.25/\n' > "$out"
EOF
chmod +x "$FAKE"/*
PATH="$FAKE:$PATH"
NOTES=(); HTTPX_BIN=""; HTTPX_PROBLEM="not installed"; NMAP_PROBLEM=""; ASSUME_YES=1
setup_target "example.com"
run_mission > "$TMP/mission.log" 2>&1
check "subdomains filtered to scope" $'dev.example.com\nexample.com\nghost.example.com\nwww.example.com' "$(cat "$RAW_DIR/subdomains.txt")"
check "CDN IP not scanned"           $'203.0.113.7\n203.0.113.8' "$(cat "$RAW_DIR/scanned_ips.txt")"
check "report has ports table"       "1" "$(grep -c '| 203.0.113.7 | 443/tcp | https | nginx 1.25 |' "$REPORT_FILE")"
check "report lists unresolved host" "1" "$(grep -c '^- ghost.example.com$' "$REPORT_FILE")"
check "report warns httpx skipped"   "1" "$(grep -c 'Phase 3 skipped' "$REPORT_FILE")"
check "skipped phase is not 'none'"  "1" "$(grep -c 'Live web services:\*\* not checked' "$REPORT_FILE")"
check "ports counted when scanned"   "1" "$(grep -c 'Open ports:\*\* 1$' "$REPORT_FILE")"
check "temp dir removed"             "no" "$([[ -d "$TEMP_DIR" ]] && echo yes || echo no)"

# --- setup.sh: broken PATH line from old versions is removed --------------------
(
    PASS=0; FAIL=0
    HOME="$TMP/home"; mkdir -p "$HOME"
    # shellcheck source=setup.sh
    source "$ROOT/setup.sh"
    RC_FILE="$HOME/.bashrc"
    printf '%s\n' 'alias ll="ls -l"' 'export PATH=$PATH:C:\Users\ana\go/bin' > "$RC_FILE"
    fix_broken_path_lines > /dev/null
    check "broken line removed" 'alias ll="ls -l"' "$(cat "$RC_FILE")"
    add_path_line "/c/Program Files (x86)/Nmap" > /dev/null
    add_path_line "/c/Program Files (x86)/Nmap" > /dev/null
    check "path line added once" "1" "$(grep -c 'Program Files (x86)/Nmap' "$RC_FILE")"
    echo "$PASS $FAIL" > "$TMP/setup_result"
)
read -r sub_pass sub_fail < "$TMP/setup_result"
PASS=$((PASS + sub_pass)); FAIL=$((FAIL + sub_fail))

echo ""
echo "Passed: $PASS   Failed: $FAIL"
(( FAIL == 0 ))
