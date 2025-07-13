#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 09_install_fastfetch.sh
# Purpose: Verify and install the 'fastfetch' system information tool.
# Usage: ./09_install_fastfetch.sh
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
# Install 'fastfetch' package.
# Globals:
#   ORANGE
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT.
# Returns:
#   Exits with error if installation fails.
#######################################
install_fastfetch() {
  echo -e "Checking for fastfetch installation..."

  if command -v fastfetch >/dev/null 2>&1; then
    echo -e "${ORANGE}fastfetch is already installed.${NC}\n"
    return 0
  fi

  echo -e "Installing fastfetch..."

  # Add the 'fastfetch' PPA
  echo -e "Adding fastfetch PPA..."
  if ! sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch >/dev/null 2>&1; then
    err "Failed to add fastfetch PPA."
    exit 1
  fi

  # Update package list after adding PPA
  echo -e "Updating package list after PPA addition..."
  if ! sudo apt-get update -qq >/dev/null 2>&1; then
    err "Failed to update package list after adding fastfetch PPA."
    exit 1
  fi

  # Install fastfetch
  if ! sudo apt-get install -y -qq fastfetch >/dev/null 2>&1; then
    err "Failed to install fastfetch."
    exit 1
  fi

  echo -e "${GREEN}✅ fastfetch installed successfully!${NC}\n"
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
  echo -e "${ORANGE}🔧 Verifying and installing fastfetch...${NC}"
  install_fastfetch
}

main "$@"
