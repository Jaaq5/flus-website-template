#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 13_install_fail2ban.sh
# Purpose: Installs and configures Fail2Ban with a basic jail for SSH
# Usage: ./13_install_fail2ban.sh
# Dependencies: sudo, apt-get, fail2ban
#

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
# Installs and configures Fail2Ban with a basic SSH jail.
# Globals:
#   ORANGE
#   GREEN
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Installs Fail2Ban, creates jail.local with basic configuration,
#   restarts the service.
# Returns:
#   None.
#######################################
install_fail2ban() {
  echo -e "Installing and configuring Fail2Ban..."

  if command -v fail2ban-client >/dev/null 2>&1; then
    echo -e "${ORANGE}Fail2Ban is already installed.${NC}\n"
    return 0
  fi

  echo "Installing Fail2Ban..."
  if ! sudo apt-get install -y -qq fail2ban >/dev/null 2>&1; then
    err "Failed to install Fail2Ban."
    exit 1
  fi

  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local TEMPLATE_FILE="${SCRIPT_DIR}/private/jail.local"
  local JAIL_LOCAL="/etc/fail2ban/jail.local"

  if [[ ! -f "${TEMPLATE_FILE}" ]]; then
    err "Template file not found: ${TEMPLATE_FILE}"
    exit 1
  fi

  if [[ -f "${JAIL_LOCAL}" ]]; then
    echo "Backing up existing jail.local to jail.local.backup."
    sudo cp "${JAIL_LOCAL}" "${JAIL_LOCAL}.backup"
  else
    echo "jail.local not found. Backing up default jail.conf"
    sudo cp /etc/fail2ban/jail.conf "/etc/fail2ban/jail.conf.backup"
  fi

  echo "Deploying jail.local configuration from template..."
  sudo cp "${TEMPLATE_FILE}" "${JAIL_LOCAL}"
  echo -e "${GREEN}jail.local created with basic parameters.${NC}"

  echo "Enabling and restarting Fail2Ban service..."
  sudo systemctl systemctl enable --now fail2ban >/dev/null 2>&1
  sudo systemctl restart fail2ban >/dev/null 2>&1

  echo -e "${GREEN}✅ Fail2Ban is now active and configured.${NC}\n"
  sudo systemctl status fail2ban --no-pager || true
  echo ""
}

#######################################
# Main entry point for the script.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Final status message indicating success.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🛡️ Starting Fail2Ban installation...${NC}"
  install_fail2ban
}

main "$@"
