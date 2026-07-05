#!/bin/bash

# Color variables
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Function to display the banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "=========================================================================="
    echo "  ____ _____ ____   ___    ___ _   _ ____ _____  _    _     _     _____ ____  "
    echo " |  _ \_   _|  _ \ / _ \  |_ _| \ | / ___|_   _|/ \  | |   | |   | ____|  _ \ "
    echo " | |_) || | | |_) | | | |  | ||  \| \___ \ | | / _ \ | |   | |   |  _| | |_) |"
    echo " |  __/ | | |  _ <| |_| |  | || |\  |___) || |/ ___ \| |___| |___| |___|  _ < "
    echo " |_|    |_| |_| \_\\\___/  |___|_| \_|____/ |_/_/   \_\_____|_____|_____|_| \_\\"
    echo "                                                                          "
    echo "=========================================================================="
    echo -e "${YELLOW}                             Made by Frezy                                ${CYAN}"
    echo "=========================================================================="
    echo -e "${RESET}"
}

# Function to install Pterodactyl Panel
install_panel() {
    echo -e "${GREEN}Starting Pterodactyl Panel Installation...${RESET}"
    apt update && apt install curl -y
    
    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}When the installer prompts you, use these details:${RESET}"
    echo "- Domain: testpanel.frezy.xyz"
    echo "- Configure Firewall (ufw): n / false"
    echo "- HTTPS using Let's Encrypt: n / false"
    echo "- Assume SSL: y / true"
    echo "- Agree HTTPS request: n / false"
    echo -e "${YELLOW}==========================================================${RESET}"
    sleep 5
    
    bash <(curl -s https://pterodactyl-installer.se)
    
    echo -e "${GREEN}Generating SSL and configuring Nginx for Cloudflare...${RESET}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /2.pem -out /1.pem -subj "/CN=localhost"
    sed -i 's|^\s*ssl_certificate\s\+.*|    ssl_certificate /1.pem;|' /etc/nginx/sites-available/pterodactyl.conf
    sed -i 's|^\s*ssl_certificate_key\s\+.*|    ssl_certificate_key /2.pem;|' /etc/nginx/sites-available/pterodactyl.conf
    sed -i 's/\b443\b/8443/g; s/\b80\b/8000/g' /etc/nginx/sites-available/pterodactyl.conf
    systemctl restart nginx
    
    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}CLOUDFLARE TUNNEL SETUP (PANEL)${RESET}"
    echo "1. Go to one.dash.cloudflare.com -> Network -> Tunnels"
    echo "2. Create a Debian tunnel."
    echo "3. Service URL: localhost:8443 (Enable 'No TLS Verify')"
    echo "Paste your Cloudflare install command below:"
    echo -e "${YELLOW}==========================================================${RESET}"
    read -p "Cloudflare Command: " CF_COMMAND
    eval $CF_COMMAND
    
    echo -e "${GREEN}Panel Installation Complete! Press ENTER to return to menu.${RESET}"
    read -r
}

# Function to install Wings
install_wings() {
    echo -e "${GREEN}Starting Wings Installation...${RESET}"
    apt update && apt install curl -y
    
    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}When prompted by the installer, choose option 1 (Wings).${RESET}"
    echo "- Unsupported type of virtualization: y"
    echo "- UFW, DB user, Let's Encrypt: n"
    echo -e "${YELLOW}==========================================================${RESET}"
    sleep 5
    
    bash <(curl -s https://pterodactyl-installer.se)
    
    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}WINGS NODE SETUP${RESET}"
    echo "1. Login to your Panel"
    echo "2. Admin -> Nodes -> Add node"
    echo "   - Daemon Port: 443"
    echo "   - SSL: Not Behind Proxy"
    echo "   - FQDN: node.frezy.xyz"
    echo "3. Go to the 'Configuration' tab, copy the bash command, and paste it below:"
    echo -e "${YELLOW}==========================================================${RESET}"
    read -p "Wings Auto-Deploy Command: " WINGS_COMMAND
    eval $WINGS_COMMAND
    
    echo -e "${GREEN}Patching Wings SSL configuration...${RESET}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /2.pem -out /1.pem -subj "/CN=localhost"
    sed -i 's|^\(\s*cert:\s*\).*|\1/1.pem|' /etc/pterodactyl/config.yml
    sed -i 's|^\(\s*key:\s*\).*|\1/2.pem|' /etc/pterodactyl/config.yml
    systemctl restart wings
    
    echo -e "${GREEN}Wings Installation Complete! Press ENTER to return to menu.${RESET}"
    read -r
}

# Function to uninstall Panel
uninstall_panel() {
    echo -e "${RED}WARNING: This will delete Pterodactyl Panel web files and Nginx configs!${RESET}"
    read -p "Are you sure you want to uninstall the Panel? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Removing files..."
        rm -rf /var/www/pterodactyl
        rm -f /etc/nginx/sites-available/pterodactyl.conf
        rm -f /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        echo -e "${GREEN}Panel uninstalled successfully. (Note: Database was not deleted to prevent accidental data loss).${RESET}"
    else
        echo "Uninstallation aborted."
    fi
    echo "Press ENTER to return to menu."
    read -r
}

# Function to uninstall Wings
uninstall_wings() {
    echo -e "${RED}WARNING: This will stop Wings and delete its configuration files!${RESET}"
    read -p "Are you sure you want to uninstall Wings? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Stopping and removing Wings..."
        systemctl stop wings
        systemctl disable wings
        rm -f /usr/local/bin/wings
        rm -f /etc/systemd/system/wings.service
        rm -rf /etc/pterodactyl
        systemctl daemon-reload
        echo -e "${GREEN}Wings uninstalled successfully.${RESET}"
    else
        echo "Uninstallation aborted."
    fi
    echo "Press ENTER to return to menu."
    read -r
}

# Main Menu Loop
while true; do
    show_banner
    echo -e "${CYAN}Choose an option from the menu below:${RESET}"
    echo "  1) Install Pterodactyl Panel"
    echo "  2) Install Wings"
    echo "  3) Uninstall Pterodactyl Panel"
    echo "  4) Uninstall Wings"
    echo "  5) Exit"
    echo ""
    read -p "Enter your choice [1-5]: " choice
    
    case $choice in
        1) install_panel ;;
        2) install_wings ;;
        3) uninstall_panel ;;
        4) uninstall_wings ;;
        5) 
            echo -e "${GREEN}Exiting installer. Goodbye, Frezy!${RESET}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Invalid option! Press ENTER to try again.${RESET}"
            read -r
            ;;
    esac
done
