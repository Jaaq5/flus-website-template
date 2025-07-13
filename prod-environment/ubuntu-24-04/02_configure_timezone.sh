#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 02_configure_timezone.sh
# Purpose: Verify and configure system timezone to America/Costa_Rica.
# Usage: ./02_configure_timezone.sh
# Dependencies: sudo, timedatectl

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
#   $*: Error message.
# Outputs:
#   Formatted message to STDERR.
#######################################
err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&2
}

#######################################
# Ensure the system timezone is set to America/Costa_Rica.
# Globals:
#   ORANGE
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT and STDERR.
# Returns:
#   Exits with non-zero on failure.
#######################################
configure_timezone() {
  local target="America/Costa_Rica"
  echo -e "Checking current timezone..."

  local current
  current=$(timedatectl | awk '/Time zone/ {print $3}')

  if [[ "$current" == "$target" ]]; then
    echo -e "${ORANGE}Timezone is already set to $target${NC}\n"
    return 0
  fi

  echo -e "Setting timezone to $target..."
  if ! sudo timedatectl set-timezone "$target"; then
    err "Failed to set timezone to $target"
    exit 1
  fi

  echo -e "Verifying updated timezone setting..."
  local updated
  updated=$(timedatectl | awk '/Time zone/ {print $3}')

  if [[ "$updated" == "$target" ]]; then
    echo -e "${GREEN}✅ Timezone successfully set to $target${NC}!\n"
  else
    err "Timezone was not correctly updated to $target\n"
    exit 1
  fi
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Startup message to STDOUT.
# Returns:
#   None; exits on failure.
#######################################
main() {
  clear
  echo -e "${ORANGE}🕙 Configuring system timezone...${NC}"
  configure_timezone
}

# Execute main function
main "$@"
