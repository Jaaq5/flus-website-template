#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# menu.sh
# Purpose: Menu interface to run specific system scripts.
# Usage: ./menu.sh
# Dependencies: bash, chmod, clear, read, ./01_update_system.sh
#               ./02_configure_timezone.sh

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

#######################################
# Print an error message to STDERR with timestamp.
# Globals:
#   RED
#   NC
# Arguments:
#   $*: Error message
# Outputs:
#   Formatted message to STDERR.
#######################################
err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&2
}

#######################################
# Display the menu options.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Menu to STDOUT.
#######################################
show_menu() {
  echo -e "${ORANGE}========= MENU =========${NC}"
  echo "1) Exit"
  echo "2) Update system"
  echo "======================="
  echo -n "Select an option: "
}

#######################################
# Run the system update script.
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Execution messages to STDOUT/STDERR.
#######################################
run_update_system() {
  local script="./01_update_system.sh"

  if [[ ! -f "$script" ]]; then
    err "The file '$script' does not exist."
    exit 1
  fi

  chmod +x "$script"
  #"$script"

  echo -e "${GREEN}Press 'q' to return to the menu.${NC}"
  local input
  while true; do
    read -r -n1 input
    if [[ "$input" == "q" ]]; then
      break
    fi
  done
}

#######################################
# Main menu loop.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Interactive shell menu
#######################################
main() {
  while true; do
    clear
    show_menu
    read -r option
    case "$option" in
    1)
      echo -e "${GREEN}Exiting...${NC}"
      exit 0
      ;;
    2)
      run_update_system
      ;;
    *)
      echo -e "${RED}Invalid option. Please try again.${NC}"
      sleep 3
      ;;
    esac
  done
}

main
