#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# 08_install_bat.sh
# Purpose: Verify and install the 'bat' package
# Usage: ./08_install_bat.sh
# Dependencies: sudo, apt-get

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
# Install 'bat' package (batcat).
# Globals:
#   ORANGE
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT.
# Returns:
#   Exits with error if installation fails.
#######################################
install_bat() {
  echo -e "Checking for bat installation..."

  if command -v batcat >/dev/null 2>&1; then
    echo -e "${ORANGE}bat is already installed as 'batcat'.${NC}\n"
    return 0
  fi

  echo -e "Installing bat..."

  if ! sudo apt-get install -y -qq bat >/dev/null; then
    err "Failed to install bat."
    exit 1
  fi

  echo -e "${GREEN}✅ bat installed successfully!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Summary message.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🦇 Verifying and installing bat...${NC}"
  install_bat
}

# Execute main function
main "$@"
