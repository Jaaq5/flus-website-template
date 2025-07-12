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
        # Install Fail2Ban
        sudo NEEDRESTART_SUSPEND=1 apt-get install -y -qq fail2ban 1>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error al instalar Fail2Ban.${NC}" >&2
            exit 1
        fi
    fi

    # Paths
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local TEMPLATE_FILE="${SCRIPT_DIR}/jail.local"
    local JAIL_LOCAL="/etc/fail2ban/jail.local"
    local TIMESTAMP=$(date +%F_%H%M%S)

    # Verify template exists
    if [ ! -f "${TEMPLATE_FILE}" ]; then
        echo -e "${RED}Configuration template not found: ${TEMPLATE_FILE}${NC}"
        exit 1
    fi

    # Backup existing configuration
    if [ -f "${JAIL_LOCAL}" ]; then
        echo -e "[INFO] Backing up existing ${JAIL_LOCAL} to ${JAIL_LOCAL}.backup.${TIMESTAMP}"
        sudo cp "${JAIL_LOCAL}" "${JAIL_LOCAL}.backup.${TIMESTAMP}"
    else
        echo -e "[WARN] ${JAIL_LOCAL} not found, backing up default /etc/fail2ban/jail.conf"
        sudo cp /etc/fail2ban/jail.conf "/etc/fail2ban/jail.conf.backup.${TIMESTAMP}"
    fi

    # Copy provided configuration
    echo -e "[INFO] Deploying configuration from ${TEMPLATE_FILE} to ${JAIL_LOCAL}"
    sudo cp "${TEMPLATE_FILE}" "${JAIL_LOCAL}"

    echo -e "${GREEN}[INFO] jail.local creado con parámetros básicos.${NC}"

    # Enable and restart Fail2Ban service
    sudo systemctl enable fail2ban >/dev/null 2>&1
    sudo systemctl restart fail2ban >/dev/null 2>&1
    echo -e "${GREEN}[OK] Fail2Ban service started and configured.${NC}"
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
