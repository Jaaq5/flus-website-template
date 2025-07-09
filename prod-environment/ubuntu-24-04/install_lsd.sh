#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install_lsd.sh
# Purpose: Verify and install the 'lsd' package and configure alias
# Usage: ./install_lsd.sh
# Dependencies: sudo, apt-get
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
# Install 'lsd' package and configure alias.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT.
# Returns:
#   Exits with error if installation fails.
#######################################
install_lsd() {
    echo -e "Verificando instalación de lsd..."

    if command_exists lsd; then
        echo -e "${ORANGE}lsd ya está instalado.${NC}/n"
        return 0
    fi

    echo -e "Instalando lsd..."

    # Install lsd silently
    sudo NEEDRESTART_MODE=a apt-get install -y -qq lsd 1>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error al instalar lsd.${NC}" >&2
        exit 1
    fi

    # Add alias to ~/.bashrc if not already present
    if ! grep -q 'alias ls="lsd"' ~/.bashrc; then
        echo 'alias ls="lsd"' >> ~/.bashrc
        echo -e "Alias 'ls' configurado a 'lsd' en ~/.bashrc"
    fi

    echo -e "${GREEN}lsd instalado correctamente${NC}/n"
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Final status message.
# Returns:
#   None; exits on any error.
#######################################
main() {
    echo -e "${ORANGE}🔧 Verificando e instalando lsd...${NC}"
    install_lsd
}

main "$@"
