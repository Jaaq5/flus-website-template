#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install.sh
# Purpose: Run all initial production configuration scripts.
# Usage: ./install.sh
# Dependencies: sudo, apt-get, update_system.sh, configure_timezone.sh,
#               dpkg-query, dependencies.sh, install_starship.sh
#               install_ble.sh
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
  local d_script="./dependencies.sh"
  if [[ ! -f "$d_script" ]]; then
    echo -e "${RED}❌ El script $d_script no existe.${NC}" >&2
    exit 1
  fi
  if [[ ! -x "$d_script" ]]; then
    chmod +x "$d_script"
  fi

  "$d_script"
}

#######################################
# Verify/install Starship via install_starship.sh.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT and STDERR
# Returns:
#   Exits non-zero on failure
#######################################
install_starship() {
  local s_script="./install_starship.sh"
  if [[ ! -f "$s_script" ]]; then
    echo -e "${RED}❌ El script $s_script no existe.${NC}" >&2
    exit 1
  fi
  if [[ ! -x "$s_script" ]]; then
    chmod +x "$s_script"
  fi

  "$s_script"
}


#######################################
# Verify/install ble.sh via install_ble.sh.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT and STDERR
# Returns:
#   Exits non-zero on failure
#######################################
install_ble() {
  local b_script="./install_ble.sh"
  if [[ ! -f "$b_script" ]]; then
    echo -e "${RED}❌ El script $b_script no existe.${NC}" >&2
    exit 1
  fi
  if [[ ! -x "$b_script" ]]; then
    chmod +x "$b_script"
  fi

  "$b_script"
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

  install_starship

  install_ble

  echo -e "${GREEN}✅ !Configuración de producción completada con éxito!${NC}\n"
}

main "$@"
