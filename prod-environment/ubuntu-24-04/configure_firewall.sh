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
ORANGE='\033[0;33m'  # Warning
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
        echo "Limpiando reglas de iptables..."
        sudo iptables -F 1>/dev/null 2>&1
        sudo iptables -t nat -F 1>/dev/null 2>&1
        sudo iptables -t mangle -F 1>/dev/null 2>&1
        sudo iptables -P INPUT ACCEPT 1>/dev/null 2>&1
        sudo iptables -P OUTPUT ACCEPT 1>/dev/null 2>&1
        
        # Check if /etc/iptables/rules.v4 exists before saving
        if [ -f /etc/iptables/rules.v4 ]; then
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null || true
        fi

        echo -e "Reglas de iptables restablecidas  correctamente"
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
    if command_exists firewall-cmd; then
        echo -e "${ORANGE}firewalld ya está instalado.${NC}\n"
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
        #sudo firewall-cmd --zone=public --add-service=ssh 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --remove-service=ssh 1>/dev/null 2>&1 || true
        sudo firewall-cmd --zone=public --add-port=${SSH_PORT}/tcp 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=http 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=https 1>/dev/null 2>&1

        # Limit SSH connections to 2 per minute and log attempts
        sudo firewall-cmd --zone=public \
            --add-rich-rule="rule port port=${SSH_PORT} protocol=tcp limit value=\"2/m\" log prefix=\"SSH_RATE\" level=\"notice\" accept"

        # Create an ipset for allowed IP ranges
        sudo firewall-cmd --zone=public --new-ipset=sshrange --type=hash:net
        for net in \
            201.191.0.0/16 \
            201.192.0.0/14 \
            201.196.0.0/14 \
            201.200.0.0/13
        do
            sudo firewall-cmd --zone=public --ipset=sshrange --add-entry="${net}"
        done

        # Allow only those IP ranges on the dynamic SSH port
        sudo firewall-cmd --zone=public \
            --add-rich-rule="rule family=\"ipv4\" source ipset=\"sshrange\" port port=${SSH_PORT} protocol=tcp accept"

        # Block ICMP (ping)
        sudo firewall-cmd  --zone=public --add-rich-rule='rule protocol value="icmp" drop' 1>/dev/null 2>&1

        # Block everything not autorized
        sudo firewall-cmd --zone=public --set-target=DROP 1>/dev/null 2>&1

        # Reload firewalld to apply changes
        sudo firewall-cmd --reload 1>/dev/null 2>&1
        
        # Save configurations permanently
        sudo firewall-cmd --runtime-to-permanent 1>/dev/null 2>&1
        
        echo -e "${GREEN}firewalld instalado correctamente${NC}\n"
    fi
}

#######################################
# Configures the sshd_config file by backing up and replacing it.
# Arguments:
#   None
# Outputs:
#   Creates a .backup of the current sshd_config and replaces it.
# Returns:
#   None.
#######################################
configure_sshd_config() {
    echo -e "Verificando configuración de sshd_config..."

    local SSHD_CONFIG="/etc/ssh/sshd_config"
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local NEW_CONFIG="${SCRIPT_DIR}/sshd_config"

    # Check if original exists
    if [ ! -f "${SSHD_CONFIG}" ]; then
        echo -e "${RED}El archivo ${SSHD_CONFIG} no existe.${NC}\n"
        exit 1
    fi

    echo "Creando copia de seguridad: ${SSHD_CONFIG}.backup"
    sudo cp "${SSHD_CONFIG}" "${SSHD_CONFIG}.backup"

    if [ ! -f "${NEW_CONFIG}" ]; then
        echo -e "${RED}No se encontró el archivo de reemplazo: ${NEW_CONFIG}.${NC}\n"
        exit 1
    fi

    echo "Reemplazando ${SSHD_CONFIG} con ${NEW_CONFIG}..."
    sudo cp "${NEW_CONFIG}" "${SSHD_CONFIG}"

    # Check if Port is set in sshd_config
    if grep -qE '^Port ' "${SSHD_CONFIG}"; then
      sudo sed -i "s/^Port .*/Port ${SSH_PORT}/" "${SSHD_CONFIG}"
    else
      sudo sed -i "1a Port ${SSH_PORT}" "${SSHD_CONFIG}"
    fi
    sudo systemctl daemon-reload 1>/dev/null 2>&1
    sudo systemctl restart ssh.service 1>/dev/null 2>&1

    echo -e "${GREEN}sshd_config reemplazado y SSH reiniciado correctamente.${NC}"
    sudo systemctl status ssh.service --no-pager
    echo ""
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

  if [ -f "$(dirname "${BASH_SOURCE[0]}")/.env" ]; then
    set -o allexport
    source "$(dirname "${BASH_SOURCE[0]}")/.env"
    set +o allexport
  else
    echo "${ORANGE}No se encontró .env — usando puerto por defecto 22${NC}"
    SSH_PORT=${SSH_PORT:-22}
  fi

  # Purge any existing firewalls (UFW, iptables)
  purge_firewall
  
  # Install and configure firewalld with basic rules
  install_firewall

   # Configure sshd_config for secure settings
   configure_sshd_config
}

# Execute the main function
main "$@"
