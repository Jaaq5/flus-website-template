#!/bin/bash
# Style guide used https://google.github.io/styleguide/shellguide.html
#
# install.sh
# Purpose: Run all initial production configuration scripts.
# Usage: ./install.sh
# Dependencies: sudo, apt-get, update_system.sh, configure_timezone.sh, 
#

# Exit immediately if a command fails (-e),
# Treat unset variables as errors (-u),
# and fail the entire script if any command in a pipeline fails (-o pipefail).
set -euo pipefail

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
    echo "❌ El script $update_script no existe." >&2
    exit 1
  fi

  # Make script executable if needed
  if [[ ! -x "$update_script" ]]; then
    chmod +x "$update_script"
  fi

  echo "🚀 Ejecutando actualización del sistema..."
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
    echo "❌ El script $tz_script no existe." >&2
    exit 1
  fi
  if [[ ! -x "$tz_script" ]]; then
    chmod +x "$tz_script"
  fi

  echo "🌐 Configurando zona horaria..."
  "$tz_script"
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

  echo -e "${GREEN}✅ Configuración de producción completada con éxito!${NC}"
}

main "$@"
