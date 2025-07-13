#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# 07_install_lsd.sh
# Purpose: Verify and install the 'lsd' package.
# Usage: ./07_install_lsd.sh
# Dependencies: sudo, apt-get
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
#   $*: Error message.
# Outputs:
#   Formatted message to STDERR.
#######################################
err() {
  echo -e "${RED}[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*${NC}" >&2
}

#######################################
# Install 'lsd' package.
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
install_lsd() {
  echo -e "Checking for lsd installation..."

  if command -v lsd >/dev/null 2>&1; then
    echo -e "${ORANGE}lsd is already installed.${NC}\n"
    return 0
  fi

  echo -e "Installing lsd..."

  if ! sudo apt-get install -y -qq lsd >/dev/null 2>&1; then
    err "Failed to install lsd."
    exit 1
  fi

  echo -e "${GREEN}✅ lsd installed successfully!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Final status message.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🌈 Verifying and installing lsd...${NC}"
  install_lsd
}

# Execute main function
main "$@"
