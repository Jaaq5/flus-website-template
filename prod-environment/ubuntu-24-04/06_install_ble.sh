#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 06_install_ble.sh
# Purpose: Verify and install ble.sh command-line editor.
# Usage: ./06_install_ble.sh
# Dependencies: git, make
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
# Installs ble.sh if not already installed.
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
install_ble() {
  echo -e "Checking for ble.sh installation..."

  if [ -d ~/.local/share/blesh ]; then
    echo -e "${ORANGE}ble.sh is already installed.${NC}\n"
    return 0
  fi

  echo -e "Installing ble.sh..."

  # Clone the ble.sh repository
  echo "Cloning ble.sh repository..."
  if ! git clone --recursive https://github.com/akinomyoga/ble.sh.git ~/.local/src/ble.sh >/dev/null 2>&1; then
    err "Failed to clone ble.sh repository."
    exit 1
  fi
  echo "ble.sh repository cloned successfully."

  # Change to the ble.sh directory
  if ! cd ~/.local/src/ble.sh; then
    err "Failed to change directory to ~/.local/src/ble.sh."
    exit 1
  fi

  echo "Building ble.sh..."
  if ! make >/dev/null 2>&1; then
    err "Failed to build ble.sh."
    exit 1
  fi
  echo "ble.sh built successfully."

  echo "Installing ble.sh..."
  if ! make install >/dev/null 2>&1; then
    err "Failed to install ble.sh."
    exit 1
  fi

  echo -e "${GREEN}✅ ble.sh installed successfully!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Summary message
# Returns:
#   None; exits on any error
#######################################
main() {
  echo -e "${ORANGE}🔧 Verifying and installing ble.sh...${NC}"
  install_ble
}

# Execute main function
main "$@"
