#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# menu.sh
# Purpose: Menu interface to run specific system scripts.
# Usage: ./menu.sh
# Dependencies: bash, chmod, clear, read, sleep
#               ./01_update_system.sh
#               ./02_configure_timezone.sh
#               ./03_install_dependencies.sh
#               ./04_configure_bashrc.sh
#               ./05_install_starship.sh
#               ./06_install_ble.sh
#               ./07_install_lsd.sh
#               ./08_install_bat.sh
#               ./09_install_fastfetch.sh
#               ./10_configure_firewall.sh
#               ./13_install_fail2ban.sh
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Info/warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

#######################################
# Print an error message to STDERR with timestamp and color.
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
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Menu to STDOUT.
#######################################
show_menu() {
  echo -e "${ORANGE}========= SYSTEM SETUP MENU =========${NC}"
  echo "1) Exit"
  echo "2) Update System"
  echo "3) Configure Timezone"
  echo "4) Install Dependencies (curl, make, etc.)"
  echo "5) Configure .bashrc"
  echo "6) Install Starship Prompt"
  echo "7) Install ble.sh Editor"
  echo "8) Install lsd (ls replacement)"
  echo "9) Install bat (cat replacement)"
  echo "10) Install fastfetch (system info)"
  echo "11) Configure Firewall (firewalld, SSH)"
  echo "12) Install Fail2Ban (SSH brute-force protection)"
  echo "13) Install Unattended Upgrades (security updates)"
  echo "14) Install Postfix (send-only MTA)"
  echo -e "${ORANGE}=====================================${NC}"
  echo -n "Select an option: "
}

#######################################
# Pause and wait for 'q' key press.
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Prompt to STDOUT.
#######################################
press_q_to_continue() {
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
# Generic function to run a script.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   $1: Path to the script to run.
# Outputs:
#   Execution messages to STDOUT/STDERR.
# Returns:
#   Exits on script execution failure.
#######################################
run_script() {
  local script_path="$1"
  clear # Clear screen before running script

  if [[ ! -f "$script_path" ]]; then
    err "The script file '$script_path' does not exist."
    exit 1
  fi

  # Ensure the script is executable
  if ! chmod +x "$script_path"; then
    err "Failed to make '$script_path' executable."
    exit 1
  fi

  # Execute the script
  # echo -e "${ORANGE}--- Running ${script_path##*/} ---${NC}"
  "$script_path"
  echo -e "${ORANGE}--- Finished ${script_path##*/} ---${NC}"
  press_q_to_continue
}

#######################################
# Main menu loop.
# Globals:
#   GREEN
#   ORANGE
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Interactive shell menu
# Returns:
#   None; exits on option 1.
#######################################
main() {
  while true; do
    clear
    show_menu
    read -r option
    case "$option" in
    1)
      echo -e "${GREEN}Exiting... Goodbye!${NC}"
      exit 0
      ;;
    2)
      run_script "./01_update_system.sh"
      ;;
    3)
      run_script "./02_configure_timezone.sh"
      ;;
    4)
      run_script "./03_install_dependencies.sh"
      ;;
    5)
      run_script "./04_configure_bashrc.sh"
      ;;
    6)
      run_script "./05_install_starship.sh"
      ;;
    7)
      run_script "./06_install_ble.sh"
      ;;
    8)
      run_script "./07_install_lsd.sh"
      ;;
    9)
      run_script "./08_install_bat.sh"
      ;;
    10)
      run_script "./09_install_fastfetch.sh"
      ;;
    11)
      run_script "./10_configure_firewall.sh"
      ;;
    12)
      run_script "./13_install_fail2ban.sh"
      ;;
      13)
      run_script "./14_unattended_upgrades.sh"
      ;;
    14)
      run_script "./15_install_postfix.sh"
      ;;
    *)
      echo -e "${RED}Invalid option: $option. Please try again.${NC}"
      sleep 2 # Shorter sleep for a snappier feel
      ;;
    esac
  done
}

main "$@"
