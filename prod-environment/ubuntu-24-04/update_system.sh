#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# update_system.sh
# Purpose: Update and upgrade Ubuntu system packages.
# Usage: ./update.sh
# Dependencies: sudo, apt-get
# 

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Define color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Update and clean up system packages.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Spanish echo messages to STDOUT.
#   Errors from apt commands to STDERR.
# Returns:
#   Exits with non-zero on failure of any apt operation.
#######################################
update_system() {
  echo -e "Actualizando la lista de paquetes disponibles..."
  sudo NEEDRESTART_SUSPEND=1 apt-get update -qq 1>/dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error al actualizar la lista de paquetes.${NC}" >&2
    exit 1
  fi

  echo -e "Actualizando los paquetes instalados..."
  sudo NEEDRESTART_SUSPEND=1 apt-get upgrade -y -qq 1>/dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error al actualizar los paquetes instalados.${NC}" >&2
    exit 1
  fi

  echo -e "Eliminando paquetes innecesarios..."
  sudo NEEDRESTART_SUSPEND=1 apt-get autoremove -y -qq 1>/dev/null
  if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error al eliminar paquetes innecesarios.${NC}" >&2
    exit 1
  fi

  echo -e "${GREEN}¡Sistema actualizado correctamente!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Final success message to STDOUT.
# Returns:
#   None; exits on update_system failure.
#######################################
main() {
  echo -e "${ORANGE}🚀 Ejecutando actualización del sistema...${NC}"
  update_system
}

main "$@"