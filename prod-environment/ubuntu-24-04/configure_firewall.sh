#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# configure_firewall.sh
# Purpose: Remove existing ufw/iptables, install and configure firewalld
# Usage: ./configure_firewall.sh
# Dependencies: sudo, apt-get, firewalld
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail  

# Color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Checks if a command exists on the system.
# Arguments:
#   $1 - Command to check.
# Returns:
#   0 if command exists, non-zero otherwise.
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Purges existing firewalls (ufw or iptables) if found.
# Arguments:
#   None
# Outputs:
#   Removes previous firewall configurations.
# Returns:
#   None.
#######################################
purge_firewall() {
    echo -e "Comprobando y eliminando firewalls existentes..."

    # Remove UFW if installed
    if command_exists ufw; then
        echo "Desinstalando ufw..."
        sudo ufw --force reset 1>/dev/null 2>&1
        sudo apt-get purge -y ufw 1>/dev/null 2>&1
        echo -e "ufw desinstalado correctamente"
    fi
  
    # Flush iptables if installed
    if command_exists iptables; then
        echo "Desinstalando iptables..."
        sudo iptables -F 1>/dev/null 2>&1
        sudo iptables -t nat -F 1>/dev/null 2>&1
        sudo iptables -t mangle -F 1>/dev/null 2>&1
        sudo iptables -P INPUT ACCEPT 1>/dev/null 2>&1
        sudo iptables -P OUTPUT ACCEPT 1>/dev/null 2>&1
        
        # Check if /etc/iptables/rules.v4 exists before saving
        if [ -f /etc/iptables/rules.v4 ]; then
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null || true
        fi

        sudo apt-get purge -y iptables 1>/dev/null 2>&1 || true
        echo -e "iptables desinstalado correctamente"
    fi
}

#######################################
# Installs and configures firewalld with basic rules.
# Arguments:
#   None
# Outputs:
#   Installs firewalld and configures rules for SSH, HTTP, and HTTPS.
# Returns:
#   None.
#######################################
install_firewall() {
    echo -e "Verificando e instalando firewalld..."

    # Check if firewalld is installed
    if command_exists firewalld; then
        echo -e "${ORANGE}firewalld ya está instalado.${NC}"
        return 0
    else
        # Install firewalld
        sudo NEEDRESTART_SUSPEND=1 apt-get install -y -qq firewalld 1>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error al instalar firewalld.${NC}" >&2
            exit 1
        fi
    
        # Start and enable firewalld
        sudo systemctl start firewalld 1>/dev/null 2>&1
        sudo systemctl enable firewalld 1>/dev/null 2>&1

        echo "Configurando zonas predeterminadas..."
        
        # Set default zone to 'public'
        sudo firewall-cmd --set-default-zone=public 1>/dev/null 2>&1

        echo "Permitiendo SSH, HTTP y HTTPS..."

        # Allow SSH, HTTP, and HTTPS traffic
        sudo firewall-cmd --zone=public --add-service=ssh --permanent 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=http --permanent 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=https --permanent 1>/dev/null 2>&1

        # Reload firewalld to apply changes
        sudo firewall-cmd --reload 1>/dev/null 2>&1

        # Limit SSH connections
        sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" service name="ssh" limit value="5/m" accept' --permanent 1>/dev/null 2>&1

        # Block ICMP (ping)
        # sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" drop protocol value="icmp"' --permanent 1>/dev/null 2>&1

        # Reload again after optional rules
        sudo firewall-cmd --reload 1>/dev/null 2>&1
        
        # Save configurations permanently
        sudo firewall-cmd --runtime-to-permanent 1>/dev/null 2>&1
        
        echo -e "${GREEN}firewalld instalado correctamente${NC}\n"
    fi
}

#######################################
# Main entry point for the script.
# Arguments:
#   None
# Outputs:
#   Final status message indicating success.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🧱 Iniciando configuración de firewall...${NC}"

  # Purge any existing firewalls (UFW, iptables)
  purge_firewall
  
  # Install and configure firewalld with basic rules
  install_firewall
}

# Execute the main function
main "$@"
