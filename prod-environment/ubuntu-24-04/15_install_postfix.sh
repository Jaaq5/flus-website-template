#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 15_install_postfix.sh
# Purpose: Installs and configures Postfix as send-only MTA, 
#          then sends a test email.
# Usage: sudo ./15_install_postfix.sh
# Dependencies: sudo, apt-get, postfix, mailutils
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

# Update this recipient email before running the script
readonly DEST_EMAIL="jaaq5@hotmail.com"

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
# Installs and configures Postfix as a send-only SMTP server.
# Sends a test email to DEST_EMAIL to verify functionality.
# Globals:
#   DEST_EMAIL
# Arguments:
#   None
# Outputs:
#   Status messages and test email result.
# Returns:
#   Exits script if installation or mail send fails.
#######################################
install_postfix() {
  echo -e "${ORANGE}📧 Installing Postfix send-only MTA...${NC}"

  if command -v postfix >/dev/null 2>&1; then
    echo -e "${ORANGE}Postfix is already installed.${NC}"
  else
    echo "Installing postfix and mailutils (for mail command)..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq postfix mailutils \
    >/dev/null 2>&1 || {
      err "Failed to install Postfix or mailutils."
      exit 1
    }
  fi

  echo "Configuring Postfix for send-only mode..."
  sudo postconf -e 'inet_interfaces = loopback-only'
  sudo postconf -e 'mydestination = localhost'
  sudo postconf -e "myorigin = $(hostname -f)"

  echo -e "${GREEN}Postfix configured for send-only operation.${NC}"

  echo "Enabling and starting postfix service..."
  sudo systemctl enable --now postfix >/dev/null 2>&1
  echo -e "${GREEN}Postfix service is running.${NC}"
  sudo systemctl status postfix --no-pager || true

  echo "Sending test email to ${DEST_EMAIL}..."
  echo "This is a test mail from $(hostname -f) at $(date)" | \
    mail -s "Postfix setup complete" "${DEST_EMAIL}" || {
      err "Test email failed to send."
      exit 1
    }

  echo -e "${GREEN}✅ Test email sent to ${DEST_EMAIL}.${NC}"
}

#######################################
# Main entry point.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Calls install_postfix
# Returns:
#   Returns exit code from install_postfix.
#######################################
main() {
  install_postfix
}

main "$@"
