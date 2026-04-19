#!/bin/bash

# ============================================================
#  N E T   W R I A T H  (v5.7 Ultimate Edition)
# ============================================================

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# --- Variables ---
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE="$PROJECT_DIR/outputs"

# --- Helper Functions ---

check_dependencies() {
    for tool in subfinder dnsx httpx nmap; do
        if ! command -v $tool &> /dev/null; then
            echo -e "${YELLOW}[!] Dependency Missing: $tool${NC}"
            exit 1
        fi
    done
}

setup_target() {
    TARGET_DOMAIN=$1
    TARGET_DIR="$OUTPUT_BASE/$TARGET_DOMAIN"
    REPORT_FILE="$TARGET_DIR/Final_Report.md"
    TEMP_DIR="$TARGET_DIR/tmp"

    if [ -d "$TARGET_DIR" ]; then
        echo -e "\n${YELLOW}[!] Overlap Detected For $TARGET_DOMAIN.${NC}"
        echo -ne "    ${WHITE}Purge Existing? (Y/N): ${NC}"
        read choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            rm -rf "$TARGET_DIR"
        fi
    fi

    mkdir -p "$TARGET_DIR" "$TEMP_DIR"
}

run_mission() {
    echo -e "\n${RED}Init:: Stealth Recon On ${WHITE}$TARGET_DOMAIN${NC}"
    
    # 1. Subdomains
    echo -ne "${YELLOW}[*] Phase 1: Discovery...  ${NC}"
    echo "$TARGET_DOMAIN" > "$TEMP_DIR/subs.txt"
    subfinder -d "$TARGET_DOMAIN" -silent >> "$TEMP_DIR/subs.txt" 2>/dev/null
    sed -i 's/\r//' "$TEMP_DIR/subs.txt"
    sort -u "$TEMP_DIR/subs.txt" -o "$TEMP_DIR/subs.txt"
    echo -e "${GREEN}Success${NC}"

    # 2. Comprehensive IP Resolution
    echo -ne "${YELLOW}[*] Phase 2: Resolution... ${NC}"
    dnsx -l "$TEMP_DIR/subs.txt" -a -resp -nc -silent | tr -d '\r' > "$TEMP_DIR/resolved_raw.txt" 2>/dev/null
    
    > "$TEMP_DIR/resolved_clean.txt"
    while read -r line; do
        [ -z "$line" ] && continue
        domain=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n 1)
        [ ! -z "$ip" ] && echo "$domain/$ip" >> "$TEMP_DIR/resolved_clean.txt"
    done < "$TEMP_DIR/resolved_raw.txt"
    
    grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" "$TEMP_DIR/resolved_clean.txt" | sort -u | tr -d '\r' > "$TEMP_DIR/unique_ips.txt"
    echo -e "${GREEN}Success${NC}"

    # 3. Live Web Filtering
    echo -ne "${YELLOW}[*] Phase 3: Filtering...  ${NC}"
    httpx -l "$TEMP_DIR/subs.txt" -silent | tr -d '\r' > "$TEMP_DIR/live.txt" 2>/dev/null
    echo -e "${GREEN}Success${NC}"

    # 4. Port Scanning
    echo -ne "${YELLOW}[*] Phase 4: Inventory...  ${NC}"
    rm -rf "$TEMP_DIR/port_results"
    mkdir -p "$TEMP_DIR/port_results"
    
    if [ -s "$TEMP_DIR/unique_ips.txt" ]; then
        nmap -iL "$TEMP_DIR/unique_ips.txt" -Pn --open -T4 -F -oG "$TEMP_DIR/nmap_raw.txt" > /dev/null 2>&1
        
        while read -r line; do
            if echo "$line" | grep -q "Ports:"; then
                ip=$(echo "$line" | awk '{print $2}')
                ports=$(echo "$line" | grep -oE "[0-9]+/open" | cut -d/ -f1 | tr '\n' ',' | sed 's/,$//')
                if [ ! -z "$ports" ]; then
                    echo "$ports" | tr ',' '\n' > "$TEMP_DIR/port_results/$ip.txt"
                fi
            fi
        done < "$TEMP_DIR/nmap_raw.txt"
    fi
    echo -e "${GREEN}Success${NC}"

    # 5. Data Synthesis & Reporting
    echo -ne "${YELLOW}[*] Phase 5: Synthesis...  ${NC}"
    {
        BORDER="================================================================"
        THIN="  ----------------------------------------------------------------"

        # Header block
        echo "$BORDER"
        printf "  NETWRIATH v5.7  //  %s\n" "$TARGET_DOMAIN"
        printf "  %s\n" "$(date)"
        echo "$BORDER"
        echo ""

        # Subdomains
        echo "  >> SUBDOMAINS"
        echo "$THIN"
        if [ -s "$TEMP_DIR/subs.txt" ]; then
            while read -r sub; do
                echo "     $sub"
            done < "$TEMP_DIR/subs.txt"
        else
            echo "     none"
        fi

        echo ""

        # Resolved Assets — dynamic column padding
        echo "  >> RESOLVED ASSETS"
        echo "$THIN"
        if [ -s "$TEMP_DIR/resolved_clean.txt" ]; then
            max_host=8
            while read -r line; do
                h=$(echo "$line" | cut -d/ -f1)
                l=${#h}
                [ $l -gt $max_host ] && max_host=$l
            done < "$TEMP_DIR/resolved_clean.txt"

            printf "     %-${max_host}s   IP\n" "HOSTNAME"
            printf '     '; printf '%0.s-' $(seq 1 $((max_host + 18))); echo ""

            while read -r line; do
                h=$(echo "$line" | cut -d/ -f1)
                ip=$(echo "$line" | cut -d/ -f2)
                printf "     %-${max_host}s   %s\n" "$h" "$ip"
            done < "$TEMP_DIR/resolved_clean.txt"
        else
            echo "     none"
        fi

        echo ""

        # Live Hosts
        echo "  >> LIVE HOSTS"
        echo "$THIN"
        if [ -s "$TEMP_DIR/live.txt" ]; then
            while read -r live; do
                echo "     $live"
            done < "$TEMP_DIR/live.txt"
        else
            echo "     none"
        fi

        echo ""

        # Open Ports
        echo "  >> OPEN PORTS"
        echo "$THIN"
        found_any_port=0
        if [ -d "$TEMP_DIR/port_results" ]; then
            for ip_file in $(ls "$TEMP_DIR/port_results"/*.txt 2>/dev/null | sort -V); do
                ip_addr=$(basename "$ip_file" .txt)
                if [ -s "$ip_file" ]; then
                    found_any_port=1
                    echo "     [ $ip_addr ]"
                    while read -r port; do
                        port_clean=$(echo "$port" | tr -d '\r')
                        [ ! -z "$port_clean" ] && echo "       [+] $port_clean"
                    done < "$ip_file"
                    echo ""
                fi
            done
        fi
        [ $found_any_port -eq 0 ] && echo "     none"

        echo ""
        echo "$BORDER"
        echo "  netwriath v5.7 // scan complete"
        echo "$BORDER"

    } > "$REPORT_FILE"
    
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}Success${NC}"
    echo -e "\n${GREEN}[+] Mission Complete: $REPORT_FILE${NC}"
}

# --- ELITE TERMINAL UI ---

while true; do
    clear
    echo -e "${RED} ███╗   ██╗███████╗████████╗██╗    ██╗██████╗ ██╗ █████╗ ████████╗██╗  ██╗"
    echo -e " ████╗  ██║██╔════╝╚══██╔══╝██║    ██║██╔══██╗██║██╔══██╗╚══██╔══╝██║  ██║"
    echo -e " ██╔██╗ ██║█████╗     ██║   ██║ █╗ ██║██████╔╝██║███████║   ██║   ███████║"
    echo -e " ██║╚██╗██║██╔══╝     ██║   ██║███╗██║██╔══██╗██║██╔══██║   ██║   ██║  ██║"
    echo -e " ██║ ╚████║███████╗   ██║   ╚███╔███╔╝██║  ██║██║██║  ██║   ██║   ██║  ██║"
    echo -e " ╚═╝  ╚═══╝╚══════╝   ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝${NC}"
    echo -e " ${WHITE} Automated Asset Discovery Framework // v5.7${NC}"
    echo -e ""
    echo -e " ${RED}-------------------------------------------------------------------------${NC}"
    echo -e " ${WHITE}:: [1] Deploy Mission${NC}"
    echo -e " ${WHITE}:: [2] Purge Database${NC}"
    echo -e " ${RED}:: [3] Disconnect${NC}"
    echo -e " ${RED}-------------------------------------------------------------------------${NC}"
    echo ""
    echo -ne " ${WHITE}Option > ${NC}"
    read OPTION

    case $OPTION in
        1)
            echo ""
            echo -ne " ${WHITE}Target > ${NC}"
            read TARGET
            [ -z "$TARGET" ] && continue
            setup_target "$TARGET"
            run_mission
            echo ""
            echo -ne " ${WHITE}Press Enter To Return...${NC}"
            read
            ;;
        2)
            echo -e "\n ${YELLOW}[!] Purging Local Database...${NC}"
            rm -rf "$OUTPUT_BASE"/*
            sleep 1
            echo -e " ${YELLOW}[+] Purge Successful${NC}"
            sleep 1
            ;;
        3)
            echo -e "\n ${YELLOW}[*] Disconnecting From Mainframe...${NC}"
            exit 0
            ;;
        *)
            echo -e "\n ${YELLOW}[!] Unknown Command${NC}"
            sleep 1
            ;;
    esac
done
