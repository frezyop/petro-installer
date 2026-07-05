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

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}Installing required dependencies (curl, expect, wget, unzip, etc.)...${RESET}"
    apt update -y
    apt install -y curl expect wget sudo nano tar unzip git jq
    echo -e "${GREEN}Dependencies installed successfully!${RESET}"
}

# Function to install Pterodactyl Panel
install_panel() {
    echo -e "${GREEN}Starting Automated Pterodactyl Panel Installation...${RESET}"
    
    install_dependencies

    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}Please enter your Panel and Admin details:${RESET}"
    
    read -p "1. Panel Domain (e.g., testpanel.frezy.xyz): " PANEL_DOMAIN; echo ""
    read -p "2. Admin Email: " ADMIN_EMAIL; echo ""
    read -p "3. Admin Username: " ADMIN_USERNAME; echo ""
    read -p "4. Admin First Name: " ADMIN_FIRST; echo ""
    read -p "5. Admin Last Name: " ADMIN_LAST; echo ""
    read -p "6. Admin Password (no special characters like $): " ADMIN_PASS; echo ""
    
    echo -e "${YELLOW}==========================================================${RESET}"

    echo -e "${CYAN}Running installer and answering questions automatically...${RESET}"
    
    # Create an expect script with highly unique strings to prevent hanging
    cat << EOF > install_panel.exp
set timeout -1
spawn bash -c "bash <(curl -s https://pterodactyl-installer.se)"

expect {
    "Input 0-6:" { send "0\r"; exp_continue }
    "name (panel):" { send "\r"; exp_continue }
    "username (pterodactyl):" { send "\r"; exp_continue }
    "Password (CHANGE_ME):" { send "\r"; exp_continue }
    "FQDN of this panel" { send "${PANEL_DOMAIN}\r"; exp_continue }
    "Configure UFW" { send "n\r"; exp_continue }
    "Let's Encrypt" { send "n\r"; exp_continue }
    "Assume SSL" { send "y\r"; exp_continue }
    "agree HTTPS request" { send "n\r"; exp_continue }
    "Email address for the initial admin" { send "${ADMIN_EMAIL}\r"; exp_continue }
    "Username for the initial admin" { send "${ADMIN_USERNAME}\r"; exp_continue }
    "First name" { send "${ADMIN_FIRST}\r"; exp_continue }
    "Last name" { send "${ADMIN_LAST}\r"; exp_continue }
    "Password for the initial admin" { send "${ADMIN_PASS}\r"; exp_continue }
    "Proceed" { send "y\r"; exp_continue }
    eof
}
EOF
    
    expect install_panel.exp
    rm install_panel.exp
    
    echo -e "${GREEN}Generating SSL and configuring Nginx for Cloudflare...${RESET}"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /2.pem -out /1.pem -subj "/CN=localhost"
    sed -i "s|^\s*ssl_certificate\s\+.*|    ssl_certificate /1.pem;|" /etc/nginx/sites-available/pterodactyl.conf
    sed -i "s|^\s*ssl_certificate_key\s\+.*|    ssl_certificate_key /2.pem;|" /etc/nginx/sites-available/pterodactyl.conf
    sed -i "s/\b443\b/8443/g; s/\b80\b/8000/g" /etc/nginx/sites-available/pterodactyl.conf
    systemctl restart nginx
    
    echo -e "${YELLOW}==========================================================${RESET}"
    echo -e "${CYAN}CLOUDFLARE TUNNEL SETUP (PANEL)${RESET}"
    echo "1. Go to one.dash.cloudflare.com -> Network -> Tunnels"
    echo "2. Create a Debian tunnel."
    echo "3. Service URL: localhost:8443 (Enable 'No TLS Verify')"
    echo "Paste your Cloudflare install command below:"
    echo -e "${YELLOW}==========================================================${RESET}"
    read -p "Cloudflare Command: " CF_COMMAND; echo ""
    eval $CF_COMMAND
    
    echo -e "${GREEN}Panel Installation Complete for ${PANEL_DOMAIN}! Press ENTER to return to menu.${RESET}"
    read -r
}

# Function to install Wings with Sub-Menu
install_wings() {
    while true; do
        clear
        show_banner
        echo -e "${CYAN}--- WINGS INSTALLATION MENU ---${RESET}"
        echo "  1) Install Wings on the SAME VPS (as Panel)"
        echo "  2) Install Wings on a DIFFERENT VPS (Remote Node)"
        echo "  3) Go Back to Main Menu"
        echo ""
        read -p "Enter your choice [1-3]: " wings_choice; echo ""
        
        case $wings_choice in
            1|2)
                echo -e "${GREEN}Starting Automated Wings Installation...${RESET}"
                
                install_dependencies

                echo -e "${YELLOW}==========================================================${RESET}"
                read -p "Enter your Node FQDN/Domain (e.g., node.frezy.xyz): " NODE_DOMAIN; echo ""
                echo -e "${YELLOW}==========================================================${RESET}"

                echo -e "${CYAN}Running installer and answering questions automatically...${RESET}"
                
                cat << EOF > install_wings.exp
set timeout -1
spawn bash -c "bash <(curl -s https://pterodactyl-installer.se)"

expect {
    "Input 0-6:" { send "1\r"; exp_continue }
    "virtualization" { send "y\r"; exp_continue }
    "Configure UFW" { send "n\r"; exp_continue }
    "Let's Encrypt" { send "n\r"; exp_continue }
    "Proceed" { send "y\r"; exp_continue }
    eof
}
EOF

                expect install_wings.exp
                rm install_wings.exp
                
                echo -e "${YELLOW}==========================================================${RESET}"
                echo -e "${CYAN}WINGS NODE SETUP${RESET}"
                echo "1. Login to your Panel"
                echo "2. Admin -> Nodes -> Add node"
                echo "   - Daemon Port: 443"
                echo "   - SSL: Not Behind Proxy"
                echo "   - FQDN: ${NODE_DOMAIN}"
                echo "3. Go to the 'Configuration' tab, copy the bash command, and paste it below:"
                echo -e "${YELLOW}==========================================================${RESET}"
                read -p "Wings Auto-Deploy Command: " WINGS_COMMAND; echo ""
                eval $WINGS_COMMAND
                
                echo -e "${GREEN}Patching Wings SSL configuration...${RESET}"
                
                if [ "$wings_choice" == "1" ]; then
                    echo -e "${CYAN}Same VPS selected. Using existing panel SSL certificates...${RESET}"
                    sed -i 's|^\(\s*cert:\s*\).*|\1/1.pem|' /etc/pterodactyl/config.yml
                    sed -i 's|^\(\s*key:\s*\).*|\1/2.pem|' /etc/pterodactyl/config.yml
                elif [ "$wings_choice" == "2" ]; then
                    echo -e "${CYAN}Different VPS selected. Generating new SSL certificates...${RESET}"
                    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /2.pem -out /1.pem -subj "/CN=localhost"
                    sed -i 's|^\(\s*cert:\s*\).*|\1/1.pem|' /etc/pterodactyl/config.yml
                    sed -i 's|^\(\s*key:\s*\).*|\1/2.pem|' /etc/pterodactyl/config.yml
                fi
                
                systemctl restart wings
                
                echo -e "${GREEN}Wings Installation Complete! Check the green heart in Panel. Press ENTER to return to main menu.${RESET}"
                read -r
                break
                ;;
            3)
                return
                ;;
            *)
                echo -e "${RED}Invalid option! Press ENTER to try again.${RESET}"
                read -r
                ;;
        esac
    done
}

# Function to uninstall Panel
uninstall_panel() {
    echo -e "${RED}WARNING: This will delete Pterodactyl Panel web files and Nginx configs!${RESET}"
    read -p "Are you sure you want to uninstall the Panel? (y/n): " confirm; echo ""
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Removing files..."
        rm -rf /var/www/pterodactyl
        rm -f /etc/nginx/sites-available/pterodactyl.conf
        rm -f /etc/nginx/sites-enabled/pterodactyl.conf
        systemctl restart nginx
        echo -e "${GREEN}Panel uninstalled successfully.${RESET}"
    else
        echo "Uninstallation aborted."
    fi
    echo "Press ENTER to return to menu."
    read -r
}

# Function to uninstall Wings
uninstall_wings() {
    echo -e "${RED}WARNING: This will stop Wings and delete its configuration files!${RESET}"
    read -p "Are you sure you want to uninstall Wings? (y/n): " confirm; echo ""
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
    echo "  1) Install Pterodactyl Panel (Auto)"
    echo "  2) Install Wings (Auto)"
    echo "  3) Uninstall Pterodactyl Panel"
    echo "  4) Uninstall Wings"
    echo "  5) Exit"
    echo ""
    read -p "Enter your choice [1-5]: " choice; echo ""
    
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
