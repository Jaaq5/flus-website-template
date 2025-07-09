#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# configure_timezone.sh
# Purpose: Verify and configure system timezone to America/Costa_Rica.
# Usage: ./configure_timezone.sh
# Dependencies: sudo, timedatectl
#

# Exit immediately if a command fails (-e),
# Treat unset variables as errors (-u),
# and fail the entire script if any command in a pipeline fails (-o pipefail).
set -euo pipefail

# Define color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Ensure the system timezone is set to America/Costa_Rica.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Echo messages to STDOUT.
#   Errors to STDERR.
# Returns:
#   0 if timezone is correctly set or updated successfully.
#   Exits with non-zero on failure.
#######################################
configure_timezone() {
  local target="America/Costa_Rica"
  echo -e "Verificando la zona horaria actual..."

  local current
  current=$(timedatectl | awk '/Time zone/ {print $3}')

  if [[ "$current" == "$target" ]]; then
    echo -e "${ORANGE}La zona horaria ya está configurada en $target${NC}\n"
    return 0
  fi

  echo -e "Configurando la zona horaria a $target..."
  sudo timedatectl set-timezone "$target"

  echo -e "Verificando la nueva configuración de zona horaria..."
  local updated
  updated=$(timedatectl | awk '/Time zone/ {print $3}')

  if [[ "$updated" == "$target" ]]; then
    echo -e "${GREEN}Zona horaria configurada correctamente a $target${NC}\n"
  else
    echo -e "${RED}Error al configurar la zona horaria${NC}\n" >&2
    exit 1
  fi
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT/STDERR.
# Returns:
#   None; exits on failures.
#######################################
main() {
  echo -e "${ORANGE}🌐 Configurando zona horaria...${NC}"
  configure_timezone
}

main "$@"
