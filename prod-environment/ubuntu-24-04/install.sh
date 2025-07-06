#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install.sh
# Purpose: Run all initial production configuration scripts.
# Usage: ./install.sh
# Dependencies: sudo, apt-get, update_system.sh, configure_timezone.sh,
#               dpkg-query, dependencies.sh, 
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
# Execute the update script to refresh the system.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Echo messages to STDOUT.
#   Errors from update.sh or apt commands to STDERR.
# Returns:
#   Exits non-zero on failure.
#######################################
run_update() {
  local update_script="./update_system.sh"

  # Ensure update.sh exists
  if [[ ! -f "$update_script" ]]; then
    echo -e "${RED}❌ El script $update_script no existe.${NC}" >&2
    exit 1
  fi

  # Make script executable if needed
  if [[ ! -x "$update_script" ]]; then
    chmod +x "$update_script"
  fi

  echo -e "${ORANGE}🚀 Ejecutando actualización del sistema...${NC}"
  "$update_script"
}

#######################################
# Configure system timezone using a helper script.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Echo messages to STDOUT/STDERR.
# Returns:
#   Exits non-zero on failure.
#######################################
configure_timezone() {
  local tz_script="./configure_timezone.sh"
  if [[ ! -f "$tz_script" ]]; then
    echo -e "${RED}❌ El script $tz_script no existe.${NC}" >&2
    exit 1
  fi
  if [[ ! -x "$tz_script" ]]; then
    chmod +x "$tz_script"
  fi

  echo -e "${ORANGE}🌐 Configurando zona horaria...${NC}"
  "$tz_script"
}

#######################################
# Verify/install dependencies via dependencies.sh.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT and STDERR
# Returns:
#   Exits non-zero on failure
#######################################
install_dependencies() {
  local script="./dependencies.sh"
  if [[ ! -f "$script" ]]; then
    echo -e "${RED}❌ El script $script no existe.${NC}" >&2
    exit 1
  fi
  if [[ ! -x "$script" ]]; then
    chmod +x "$script"
  fi

  echo -e "\n${ORANGE}🔧 Verificando e instalando dependencias...${NC}"
  "$script"
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

  # Clear the terminal screen for better visibility
  clear

  run_update

  configure_timezone

  install_dependencies

  echo -e "${GREEN}✅ Configuración de producción completada con éxito!${NC}\n"
}

main "$@"
