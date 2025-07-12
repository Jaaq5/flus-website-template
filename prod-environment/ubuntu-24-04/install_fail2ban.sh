#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install_fail2ban.sh
# Purpose: Installs and configures Fail2Ban with a basic jail for SSH
# Usage: ./install_fail2ban.sh
# Dependencies: sudo, apt-get, fail2ban
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
#   $1 - Command name.
# Returns:
#   0 if it exists, >0 if it doesn't.
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Installs and configures Fail2Ban with a basic SSH jail.
# Arguments:
#   None
# Outputs:
#   Installs Fail2Ban, creates jail.local with basic configuration, restarts the service.
# Returns:
#   None.
#######################################
install_fail2ban() {
    echo -e "[INFO] Instalando y configurando Fail2Ban..."

    # Install package if not already installed
    if command_exists fail2ban-client; then
        echo -e "${ORANGE}Fail2Ban ya está instalado.${NC}\n"
        return 0
    else
        # Install firewalld
        sudo NEEDRESTART_SUSPEND=1 apt-get install -y -qq fail2ban 1>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error al instalar Fail2Ban.${NC}" >&2
            exit 1
        fi

    # Copy base configuration
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

    # Write minimal configuration
    sudo tee /etc/fail2ban/jail.local >/dev/null <<EOF
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s
EOF

    echo -e "${GREEN}[INFO] jail.local creado con parámetros básicos.${NC}"

    # Restart service
    sudo systemctl enable fail2ban >/dev/null 2>&1
    sudo systemctl restart fail2ban >/dev/null 2>&1
    echo -e "${GREEN}[OK] Fail2Ban iniciado y configurado.${NC}"
    sudo systemctl status fail2ban --no-pager
    echo ""
    
}

#######################################
# Main
#######################################
main() {
    echo -e "${ORANGE}🛡️ Comenzando instalación de Fail2Ban...${NC}"
    install_fail2ban
}

main "$@"
