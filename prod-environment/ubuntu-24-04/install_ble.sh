#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install_ble.sh
# Purpose: Verify and install ble.sh command-line editor.
# Usage: install_ble.sh
# Dependencies: git, make
#

# Exit immediately if a command fails (-e),
# Treat unset variables as errors (-u),
# and fail the entire script if any command in a pipeline fails (-o pipefail).
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
#   0 if command exists, 1 if not.
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Installs ble.sh if not already installed.
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT.
# Returns:
#   Exits with error if installation fails.
#######################################
install_ble() {
    echo -e "Verificando instalación de ble.sh..."

    if [ -d ~/.local/share/blesh ]; then
        echo -e "${ORANGE}ble.sh ya está instalado.${NC}"
        return 0
    fi

    echo -e "Instalando ble.sh..."

    # Clone the ble.sh repository
    echo "Clonando el repositorio de ble.sh..."
    git clone --recursive https://github.com/akinomyoga/ble.sh.git ~/.local/src/ble.sh > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al clonar el repositorio de ble.sh.${NC}" >&2
        exit 1
    fi
    echo -e "Repositorio de ble.sh clonado correctamente."

    # Build and install ble.sh
    cd ~/.local/src/ble.sh

    echo "Construyendo ble.sh..."
    if ! make > /dev/null 2>&1; then
        echo -e "${RED}Error al construir ble.sh.${NC}" >&2
        exit 1
    fi
    echo -e "ble.sh construido exitosamente."

    echo "Instalando ble.sh..."
    if ! make install > /dev/null 2>&1; then
        echo -e "${RED}Error al instalar ble.sh.${NC}" >&2
        exit 1
    fi

    # Add ble.sh configuration to ~/.bashrc
    if ! grep -q 'source ~/.local/share/blesh/ble.sh --noattach' ~/.bashrc; then
        echo '[[ $- == *i* ]] && source ~/.local/share/blesh/ble.sh --noattach' >> ~/.bashrc
        echo -e "Configuración de ble.sh añadida a ~/.bashrc"
    fi

    # Add ble-attach line at the end of ~/.bashrc
    if ! grep -q '[[ ! ${BLE_VERSION-} ]] || ble-attach' ~/.bashrc; then
        echo '[[ ! ${BLE_VERSION-} ]] || ble-attach' >> ~/.bashrc
        echo -e "Línea de attachment de ble.sh añadida a ~/.bashrc"
    fi

    echo -e "${GREEN}!ble.sh instalado correctamente!${NC}\n"
}

#######################################
# Main entry point.
# Arguments:
#   None
# Outputs:
#   Summary message
# Returns:
#   None; exits on any error
#######################################
main() {
    echo -e "${ORANGE}🔧 Verificando e instalando ble.sh...${NC}"
    install_ble
    
}

main "$@"
