#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 01_update_system.sh
# Purpose: Update and upgrade Ubuntu system packages.
# Usage: ./01_update_system.sh
# Dependencies: sudo, apt-get

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Warning
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
# Update and clean up system packages.
# Globals:
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT.
# Returns:
#   Exits on failure of any apt operation.
#######################################
update_system() {
  echo -e "Updating package list..."
  if ! sudo apt-get update -qq >/dev/null; then
    err "Failed to update package list."
    exit 1
  fi

  echo -e "Upgrading installed packages..."
  if ! sudo apt-get upgrade -y -qq >/dev/null; then
    err "Failed to upgrade installed packages."
    exit 1
  fi

  echo -e "Removing unnecessary packages..."
  if ! sudo apt-get autoremove -y -qq >/dev/null; then
    err "Failed to remove unnecessary packages."
    exit 1
  fi

  echo -e "${GREEN}✅ System successfully updated!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Final success message to STDOUT.
#######################################
main() {
  clear
  echo -e "${ORANGE}📦 Running system update...${NC}"
  update_system
}

# Execute the main function
main "$@"
