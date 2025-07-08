#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install_starship.sh
# Purpose: Verify and install starship package.
# Usage: install_starship.sh
# Dependencies: sudo, apt-get
#

# Exit immediately if a command fails (-e),
# Treat unset variables as errors (-u),
# and fail the entire script if any command in a pipeline fails (-o pipefail).
set -euo pipefail  # Exit on error, unset variable, or pipeline failure

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
# Installs Starship shell prompt in ~/.local/bin if not installed.
# Globals:
#   PATH
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT.
# Returns:
#   Exits with error if installation fails.
#######################################
install_starship() {
    echo -e "Verificando instalación de Starship..."

    if command_exists starship; then
        echo -e "${ORANGE}Starship ya está instalado.${NC}"
        #starship --version
        return 0
    fi

    echo -e "Instalando Starship..."

    mkdir -p ~/.local/bin

    curl -fsSL https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin --yes > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al instalar Starship.${NC}" >&2
        exit 1
    fi

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH=$PATH:$HOME/.local/bin' >> ~/.bashrc
        echo -e "${GREEN}Ruta ~/.local/bin añadida a ~/.bashrc${NC}"
    fi

    if ! grep -q 'eval "$(starship init bash)"' ~/.bashrc; then
        echo 'eval "$(starship init bash)"' >> ~/.bashrc
        echo -e "${GREEN}Inicialización de Starship añadida a ~/.bashrc${NC}"
    fi

    echo -e "${GREEN}Starship instalado correctamente..${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Summary message
# Returns:
#   None; exits on any error
#######################################
main() {
  echo -e "${ORANGE}🔧 Verificando e instalando Starship...${NC}"
  install_starship
  
}

main "$@"