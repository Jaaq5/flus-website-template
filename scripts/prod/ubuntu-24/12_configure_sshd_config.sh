#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 12_configure_sshd_config.sh
# Purpose: Backup and replace sshd_config, set custom port.
# Usage: Source from main script 10_configure_firewall.sh.
# Dependencies: sudo, systemctl, sshd
#

#######################################
# Configures the sshd_config file by backing up and replacing it.
# Globals:
#   GREEN
#   RED
#   NC
#   SSH_PORT
# Arguments:
#   None
# Outputs:
#   Creates a .backup of the current sshd_config and replaces it.
# Returns:
#   Exits with error if configuration fails.
#######################################
configure_sshd_config() {
  echo -e "Checking sshd_config configuration..."

  local SSHD_CONFIG="/etc/ssh/sshd_config"
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local NEW_CONFIG="${SCRIPT_DIR}/template-files/sshd_config"
  local BACKUP_CONFIG="${SSHD_CONFIG}.backup"

  # Check if original exists
  if [[ ! -f "${SSHD_CONFIG}" ]]; then
    err "Original sshd_config file '${SSHD_CONFIG}' does not exist."
    exit 1
  fi

  echo "Creating backup: ${BACKUP_CONFIG}"
  if ! sudo cp "${SSHD_CONFIG}" "${BACKUP_CONFIG}"; then
    err "Failed to create backup of sshd_config."
    exit 1
  fi

  if [[ ! -f "${NEW_CONFIG}" ]]; then
    err "Replacement sshd_config file '${NEW_CONFIG}' not found."
    exit 1
  fi

  echo "Replacing ${SSHD_CONFIG} with template file..."
  if ! sudo cp "${NEW_CONFIG}" "${SSHD_CONFIG}"; then
    err "Failed to replace sshd_config."
    exit 1
  fi

  echo "Setting SSH Port to ${SSH_PORT} in ${SSHD_CONFIG}..."
  if grep -qE '^Port ' "${SSHD_CONFIG}"; then
    if ! sudo sed -i "s/^Port .*/Port ${SSH_PORT}/" "${SSHD_CONFIG}"; then
      err "Failed to update Port in sshd_config."
      exit 1
    fi
  fi

  echo "Restarting SSH service..."
  if ! sudo systemctl daemon-reload >/dev/null 2>&1; then
    err "Failed to daemon-reload systemctl."
  fi
  if ! sudo systemctl restart ssh >/dev/null 2>&1; then
    err "Failed to restart SSH service. Check logs for details."
    exit 1
  fi

  echo -e "${GREEN}✅ sshd_config replaced and SSH restarted successfully.${NC}\n"
  echo "Current SSH service status:"
  sudo systemctl status ssh --no-pager || true
  echo ""
}
