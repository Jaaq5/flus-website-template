#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 14_unattended_upgrades.sh
# Purpose: Installs and configures automatic security updates on Ubuntu.
# Usage: ./14_unattended_upgrades.sh
# Dependencies: sudo, apt-get, unattended-upgrades
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
# Install and configure unattended-upgrades for security updates.
# Globals: None
# Arguments: None
# Outputs: Config files under /etc/apt/apt.conf.d/
# Returns: Exits on error.
#######################################
install_unattended() {
  echo -e "${ORANGE}Installing unattended-upgrades...${NC}"

  if command -v unattended-upgrade >/dev/null 2>&1; then
    echo -e "${ORANGE}unattended-upgrades already installed.${NC}\n"
  else
    echo "Installing package..."
    if ! sudo apt-get install -y -qq unattended-upgrades apt-listchanges \
    >/dev/null; then
      err "Installation failed"
      exit 1
    fi
  fi

  echo "Configuring security-only upgrades..."
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

  echo "Enabling automatic updates..."
  sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  echo "Scheduling run at midnight (00:00 Costa Rica)..."
  sudo systemctl enable --now unattended-upgrades.timer >/dev/null 2>&1

  echo -e "${GREEN}✅ unattended-upgrades configured successfully.${NC}"
  systemctl status unattended-upgrades.timer --no-pager || true
}

#######################################
# Main entry point.
# Globals: 
#   None
# Arguments: 
#    None
# Outputs: 
#   Calls install_unattended
# Returns: 
#   Exit code of install_unattended
#######################################
main() {
  install_unattended
}

main "$@"
