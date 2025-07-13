#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 05_install_starship.sh
# Purpose: Verify and install Starship shell prompt.
# Usage: ./05_install_starship.sh
# Dependencies: bash, curl

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
# Install Starship shell prompt in ~/.local/bin if not installed.
# Globals:
#   ORANGE
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Progress messages to STDOUT/STDERR
# Returns:
#   Exits non-zero on failure
#######################################
install_starship() {
  echo -e "Checking for Starship installation..."

  if command -v starship >/dev/null 2>&1; then
    echo -e "${ORANGE}Starship is already installed.${NC}\n"
    return 0
  fi

  echo -e "Installing Starship..."

  # Ensure local bin directory exists
  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"

  # Download and install
  if ! curl -fsSL https://starship.rs/install.sh |
    sh -s -- --bin-dir "$bin_dir" --yes >/dev/null 2>&1; then
    err "Installation of Starship failed."
    exit 1
  fi

  echo -e "${GREEN}✅ Starship installed successfully in ${bin_dir}.${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Summary message to STDOUT
# Returns:
#   None; exits on failure
#######################################
main() {
  echo -e "${ORANGE}🚀 Verifying and installing Starship...${NC}"
  install_starship
}

# Execute main function
main "$@"
