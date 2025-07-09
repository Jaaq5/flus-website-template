#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install_bat.sh
# Purpose: Verify and install the 'bat' package and configure alias
# Usage: ./install_bat.sh
# Dependencies: sudo, apt-get

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Checks if a command exists on the system
# Arguments:
#   $1 - Command to check
# Returns:
#   0 if the command exists, non-zero otherwise
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Install 'bat' package (batcat) and configure alias
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT
# Returns:
#   Exits with error if installation fails
#######################################
install_bat() {
    echo -e "Verificando instalación de bat..."

    if command_exists batcat; then
        echo -e "${ORANGE}bat ya está instalado como 'batcat'${NC}\n"
        return 0
    fi

    echo -e "Instalando bat..."

    # Install 'bat' silently and suppress needrestart messages
    sudo NEEDRESTART_MODE=a apt-get install -y -qq bat 1>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error al instalar bat${NC}" >&2
        exit 1
    fi

    # Add alias to ~/.bashrc if not already present
    if ! grep -q 'alias cat="batcat"' ~/.bashrc; then
        echo 'alias cat="batcat"' >> ~/.bashrc
        echo -e "Alias 'cat' configurado a 'batcat' en ~/.bashrc"
    fi

    echo -e "${GREEN}bat instalado correctamente${NC}\n"
}
#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Summary message.
# Returns:
#   None; exits on any error.
#######################################
main() {
    echo -e "${ORANGE}🔧 Verificando e instalando bat...${NC}"
    install_bat
}

main "$@"
