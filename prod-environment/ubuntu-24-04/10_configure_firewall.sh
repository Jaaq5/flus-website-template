#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 10_configure_firewall.sh
# Purpose: Remove existing ufw/iptables rules, install and configure firewalld,
#          and adjust SSH daemon configuration.
# Usage: ./10_configure_firewall.sh
# Dependencies: sudo, apt-get, firewalld, iptables,
#               ufw, systemctl, sshd
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Info/warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

# Global variable for SSH port, to be set by user
SSH_PORT=""

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
# Purges existing firewalls (ufw or iptables) if found.
# Globals:
#   None (uses `command_exists` which is global but takes no args/globals)
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT.
# Returns:
#   None.
#######################################
purge_firewall() {
  echo -e "Checking for and removing existing firewalls..."

  # Remove UFW if installed
  if command -v ufw >/dev/null 2>&1; then
    echo "Uninstalling ufw..."
    if ! sudo ufw --force reset >/dev/null 2>&1; then
      err "Failed to reset ufw."
    fi
    if ! sudo apt-get purge -y ufw >/dev/null 2>&1; then
      err "Failed to purge ufw."
    fi
    echo -e "ufw uninstalled successfully."
  else
    echo "ufw not found."
  fi

  # Flush iptables if installed
  if command -v iptables >/dev/null 2>&1; then
    echo "Flushing iptables rules..."
    if ! sudo iptables -F >/dev/null 2>&1 ||
      ! sudo iptables -t nat -F >/dev/null 2>&1 ||
      ! sudo iptables -t mangle -F >/dev/null 2>&1 ||
      ! sudo iptables -P INPUT ACCEPT >/dev/null 2>&1 ||
      ! sudo iptables -P FORWARD ACCEPT >/dev/null 2>&1 ||
      ! sudo iptables -P OUTPUT ACCEPT >/dev/null 2>&1; then
      err "Failed to flush iptables rules."
    fi
    echo -e "iptables rules reset successfully."
  else
    echo "iptables not found."
  fi
}

#######################################
# Installs and configures firewalld with basic rules.
# Globals:
#   ORANGE
#   GREEN
#   RED
#   NC
#   SSH_PORT
# Arguments:
#   None
# Outputs:
#   Installs firewalld and configures rules for SSH, HTTP, and HTTPS.
# Returns:
#   Exits with error if installation or configuration fails.
#######################################
install_firewall() {
  echo -e "Checking for and installing firewalld..."

  if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewalld not found. Installing..."
    if ! sudo apt-get install -y -qq firewalld >/dev/null; then
      err "Failed to install firewalld."
      exit 1
    fi
  else
    echo -e "${ORANGE}firewalld is already installed. Ensuring configuration...${NC}"
  fi

  echo "Starting and enabling firewalld..."
  if ! sudo systemctl start firewalld >/dev/null 2>&1; then
    err "Failed to start firewalld."
    exit 1
  fi
  if ! sudo systemctl enable firewalld >/dev/null 2>&1; then
    err "Failed to enable firewalld."
    exit 1
  fi
  echo "firewalld service is active and enabled."

  echo "Configuring default zones..."
  if ! sudo firewall-cmd --set-default-zone=public >/dev/null 2>&1; then
    err "Failed to set default zone to public."
    exit 1
  fi

  echo "Allowing HTTP and HTTPS services..."
  if ! sudo firewall-cmd --zone=public --add-service=http --permanent \
    >/dev/null 2>&1; then
    err "Failed to allow HTTP service."
  fi
  if ! sudo firewall-cmd --zone=public --add-service=https --permanent \
    >/dev/null 2>&1; then
    err "Failed to allow HTTPS service."
  fi

  echo "Configuring SSH access on port ${SSH_PORT}..."
  # Remove general SSH service/port if added to rely purely on rich rules
  sudo firewall-cmd --zone=public --remove-service=ssh --permanent \
    >/dev/null 2>&1 || true
  sudo firewall-cmd --zone=public --remove-port="${SSH_PORT}/tcp" --permanent \
    >/dev/null 2>&1 || true

  # Add rich rule for SSH rate limiting and logging
  if ! sudo firewall-cmd --zone=public --add-rich-rule="rule port port=${SSH_PORT} \
    protocol=tcp limit value=\"2/m\" log prefix=\"SSH_RATE\" level=\"notice\" accept" --permanent \
    >/dev/null 2>&1; then
    err "Failed to add SSH rate limit rule."
    exit 1
  fi

  # Remove ipset if it already exists before creating it to ensure idempotency.
  echo "Ensuring 'sshrange' ipset is in a clean state..."
  if sudo firewall-cmd --zone=public --query-ipset=sshrange >/dev/null 2>&1; then
    echo "Removing existing 'sshrange' ipset to re-create it."
    if ! sudo firewall-cmd --zone=public --remove-ipset=sshrange --permanent \
      >/dev/null 2>&1; then
      err "Failed to remove existing 'sshrange' ipset. Aborting firewall setup."
      exit 1
    fi
  fi

  # Create an ipset for allowed SSH IP ranges
  echo "Creating ipset for allowed SSH IP ranges..."
  if ! sudo firewall-cmd --zone=public --new-ipset=sshrange --type=hash:net --permanent \
    >/dev/null 2>&1; then
    err "Failed to create ipset 'sshrange'."
    exit 1
  fi

  # Add specific IP ranges to the ipset from a file
  # https://lite.ip2location.com/ip-address-ranges-by-country
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local IP_RANGES_FILE="${SCRIPT_DIR}/private/ssh_ip_ranges.sh"

  # Check if the IP ranges file exists
  if [[ ! -f "${IP_RANGES_FILE}" ]]; then
    err "IP ranges file '${IP_RANGES_FILE}' not found."
    exit 1
  fi

  # Source the file to load the SSH_ALLOWED_IP_RANGES array
  # shellcheck disable=SC1090
  source "${IP_RANGES_FILE}"

  # Now, the ipset_entries array (which you had before) needs to be defined from the sourced array.
  # Since we've directly defined SSH_ALLOWED_IP_RANGES, we can use that.
  # If you prefer to keep the local `ipset_entries` variable, you can copy it:
  # local ipset_entries=("${SSH_ALLOWED_IP_RANGES[@]}")

  # Use the SSH_ALLOWED_IP_RANGES array directly
  if [[ ${#SSH_ALLOWED_IP_RANGES[@]} -eq 0 ]]; then
    err "No IP ranges found in '${IP_RANGES_FILE}'."
    exit 1
  fi

  for net in "${SSH_ALLOWED_IP_RANGES[@]}"; do
    echo "Adding ipset entry: ${net}"
    if ! sudo firewall-cmd --zone=public --ipset=sshrange --add-entry="${net}" --permanent \
      >/dev/null 2>&1; then
      err "Failed to add ipset entry ${net}."
    fi
  done

  # Add rich rule to allow SSH from ipset only
  if
    ! sudo firewall-cmd --zone=public --add-rich-rule="rule family=\"ipv4\" \
    source ipset=\"sshrange\" port port=${SSH_PORT} protocol=tcp accept" --permanent \
      >/dev/null 2>&1
  then
    err "Failed to add ipset allow rule for SSH."
    exit 1
  fi

  echo "Blocking ICMP (ping) traffic..."
  if ! sudo firewall-cmd --zone=public --add-rich-rule='rule protocol \
  value="icmp" drop' --permanent >/dev/null 2>&1; then
    err "Failed to block ICMP."
  fi

  # Set default target for the zone to DROP,
  # explicitly block everything not explicitly allowed
  echo "Setting default firewall policy to DROP for public zone..."
  if ! sudo firewall-cmd --zone=public --set-target=DROP --permanent \
    >/dev/null 2>&1; then
    err "Failed to set default target to DROP."
    exit 1
  fi

  echo "Reloading firewalld to apply permanent changes..."
  if ! sudo firewall-cmd --reload >/dev/null 2>&1; then
    err "Failed to reload firewalld."
    exit 1
  fi

  echo -e "${GREEN}firewalld installed and configured successfully!${NC}\n"
}

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

  echo "Replacing ${SSHD_CONFIG} with ${NEW_CONFIG}..."
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

  echo -e "${GREEN}sshd_config replaced and SSH restarted successfully.${NC}"
  echo "Current SSH service status:"
  sudo systemctl status ssh --no-pager || true
  echo ""
}

#######################################
# Main entry point for the script.
# Globals:
#   ORANGE
#   GREEN
#   RED
#   NC
#   SSH_PORT
# Arguments:
#   None
# Outputs:
#   Final status message indicating success.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🧱 Starting firewall configuration...${NC}"

  # Ask for SSH_PORT variable with validation and default 22
  local input_port
  while true; do
    read -rp "Please enter the SSH port (default 22): " input_port
    input_port="${input_port:-22}" # Set default if empty

    if [[ "$input_port" =~ ^[0-9]+$ ]] && ((input_port >= 1)) && ((input_port <= 65535)); then
      SSH_PORT="$input_port"
      echo "SSH port set to: ${SSH_PORT}"
      break
    else
      err "Invalid port number. Please enter a number between 1 and 65535."
    fi
  done

  # Purge any existing firewalls config (UFW, iptables)
  purge_firewall

  # Install and configure firewalld with basic rules
  install_firewall

  # Configure sshd_config for secure settings
  configure_sshd_config

  echo -e "${GREEN}✅ Firewall and SSH configuration completed.${NC}"
}

# Execute the main function
main "$@"
