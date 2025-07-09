#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# install.sh
# Purpose: Run all initial production configuration scripts
# Usage: ./install.sh
# Dependencies: sudo, apt-get, dpkg-query
#               update_system.sh, configure_timezone.sh,
#               dependencies.sh, install_starship.sh,
#               install_ble.sh, install_lsd.sh, install_bat.sh,
#               configure_terminal.sh
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail  

# Color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Info/warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Run a script file: verify existence, make executable, and execute.
# Arguments:
#   $1 - Script filename (with path)
# Outputs:
#   Error messages to STDERR if missing or non-executable
# Returns:
#   Exits non-zero on failure
#######################################
run_script() {
  local script="$1"

  # Check if the script file exists
  if [[ ! -f "$script" ]]; then
    echo -e "${RED}❌ El script $script no existe.${NC}" >&2
    exit 1
  fi

  # Make the script executable if it isn't already
  if [[ ! -x "$script" ]]; then
    chmod +x "$script"
  fi

  # Execute the script
  "$script"
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Progress and summary messages to STDOUT/STDERR
# Returns:
#   None; exits on any error
#######################################
main() {

  # Clear the terminal screen for better visibility
  clear

  # Add where the custom configuration starts in .bashrc
  if ! grep -qF '#Custom configuration starts here' ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '#Custom configuration starts here' >> ~/.bashrc
  fi

  # Run each configuration script in order
  run_script "./update_system.sh"
  run_script "./configure_timezone.sh"
  run_script "./dependencies.sh"
  run_script "./install_starship.sh"
  run_script "./install_ble.sh"
  run_script "./install_lsd.sh"
  run_script "./install_bat.sh"
  run_script "./configure_terminal.sh"

  echo -e "${GREEN}✅ ¡Configuración de producción finalizada!${NC}"
}

main "$@"
