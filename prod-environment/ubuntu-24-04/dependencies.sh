#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# dependencies.sh
# Purpose: Verify and install required system dependencies.
# Usage: ./dependencies.sh
# Dependencies: sudo, apt-get, dpkg-query
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

# List of required packages
packages=(git curl make gawk vim nano)

#######################################
# Check if a package is installed.
# Globals:
#   None
# Arguments:
#   $1 - package name
# Returns:
#   0 if installed, non-zero otherwise
#######################################
is_installed() {
  dpkg-query -Wf'${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}

#######################################
# Install a package using apt-get.
# Globals:
#   None
# Arguments:
#   $1 - package name
# Outputs:
#   Informational and/or error messages
# Returns:
#   Exits non-zero on failure
#######################################
install_pkg() {
  local pkg="$1"
  echo -e "Instalando paquete: ${pkg}..."
  sudo NEEDRESTART_MODE=a apt-get install -y -qq "$pkg" 1>/dev/null
  if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Paquete ${pkg} instalado correctamente${NC}"
  else
    echo -e "${RED}Error al instalar paquete: ${pkg}${NC}" >&2
    exit 1
  fi

  echo -e "${GREEN}!Dependencias instaladas correctamente!${NC}\n"
}

#######################################
# Verify and install missing dependencies.
# Globals:
#   packages
# Arguments:
#   None
# Outputs:
#   Echo status messages
# Returns:
#   Exits non-zero on any install failure
#######################################
check_and_install_dependencies() {
  for pkg in "${packages[@]}"; do
    if is_installed "$pkg"; then
      echo -e "${ORANGE}Ya está instalado: ${pkg}${NC}"
    else
      install_pkg "$pkg"
    fi
  done
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
  echo -e "${ORANGE}🔧 Verificando e instalando dependencias...${NC}"
  check_and_install_dependencies
  
}

main "$@"
