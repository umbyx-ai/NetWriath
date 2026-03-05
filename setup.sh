#!/bin/bash

# NetWriath Setup Script (Bash Version)
# Works on Linux and Windows (via Git Bash)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}--- Starting NetWriath Setup ---${NC}"

# Function to check and install tools (simplified for cross-platform)
check_tool() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}[OK] $1 is already installed.${NC}"
    else
        echo -e "${YELLOW}[!] $1 is missing.${NC}"
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
            echo -e "${YELLOW}[*] Windows detected. Attempting install via winget...${NC}"
            # Mapping common command names to winget IDs
            case $1 in
                python) winget install --id Python.Python.3 --silent --accept-package-agreements --accept-source-agreements ;;
                go)     winget install --id GoLang.Go --silent --accept-package-agreements --accept-source-agreements ;;
                nmap)   winget install --id Insecure.Nmap --silent --accept-package-agreements --accept-source-agreements ;;
                git)    winget install --id Git.Git --silent --accept-package-agreements --accept-source-agreements ;;
            esac
        else
            echo -e "${RED}[ERROR] Please install $1 manually using your package manager (apt, pacman, brew, etc.)${NC}"
        fi
    fi
}

# 1. Check/Install Core Tools
tools=("python" "go" "nmap" "git")
for tool in "${tools[@]}"; do
    check_tool "$tool"
done

# 2. Install specialized recon tools via Go
echo -e "${CYAN}Installing specialized recon tools via Go...${NC}"

go_tools=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    "github.com/sensepost/gowitness@latest"
)

for tool_path in "${go_tools[@]}"; do
    tool_name=$(echo "$tool_path" | awk -F/ '{print $NF}' | cut -d@ -f1)
    echo -e "${YELLOW}[*] Installing $tool_name...${NC}"
    go install "$tool_path"
done

# 3. Ensure Go bin is in PATH
# Get GOPATH (default is ~/go)
GO_BIN=$(go env GOPATH)/bin
if [[ ":$PATH:" != *":$GO_BIN:"* ]]; then
    echo -e "${YELLOW}[*] Adding $GO_BIN to PATH...${NC}"
    # For Bash
    echo "export PATH=\$PATH:$GO_BIN" >> ~/.bashrc
    export PATH=$PATH:$GO_BIN
fi

echo -e "\n${GREEN}--- Setup Complete! ---${NC}"
echo -e "${CYAN}Please RESTART your terminal to ensure all tools are ready.${NC}"
