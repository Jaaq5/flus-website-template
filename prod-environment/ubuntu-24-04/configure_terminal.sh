#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# configure_terminal.sh
# Purpose: Ensure TERM is set to xterm-256color and reload ~/.bashrc
# Usage: ./configure_terminal.sh
# Dependencies: bash, grep
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail  

# Color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Ensure TERM is set to xterm-256color in ~/.bashrc.
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT/STDERR.
# Returns:
#   Exits on success or error.
#######################################
configure_term() {
    
    if grep -q 'export TERM=xterm-256color' ~/.bashrc; then
        echo -e "${ORANGE}La configuración TERM ya está en ~/.bashrc${NC}\n"
        exit 0
    else
        echo 'export TERM=xterm-256color' >> ~/.bashrc
        echo -e "TERM=xterm-256color añadido a ~/.bashrc"
    fi

    source ~/.bashrc
    echo -e "${GREEN}term configurado correctamente${NC}"

    echo -e "Sal de la sesión e inicia de nuevo para ver los cambios\n"
}

#######################################
# Main entry point.
# Arguments:
#   None
# Outputs:
#   Summary messages.
# Returns:
#   None; exits on success.
#######################################
main() {
    echo -e "${ORANGE}🔧 Configurando TERM=xterm-256color...${NC}"
    configure_term
}

main "$@"
