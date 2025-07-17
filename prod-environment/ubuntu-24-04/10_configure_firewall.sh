#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# 10_configure_firewall.sh
# Purpose: Remove existing ufw/iptables rules, install and configure firewalld,
#          and adjust SSH daemon configuration.
# Usage: ./10_configure_firewall.sh
# Dependencies: sudo, apt-get, firewalld, iptables,
#               ufw, systemctl, sshd, 11_purge_firewall.sh,
#               12_configure_sshd_config.sh
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Warning
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

  if command -v firewall-cmd >/dev/null 2>&1; then
    echo -e "${ORANGE}firewalld is already installed.${NC}"
    return 0
  else
    echo "firewalld not found. Installing..."
    if ! sudo apt-get install -y -qq firewalld >/dev/null; then
      err "Failed to install firewalld."
      exit 1
    fi
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
  echo -e "firewalld service is active and enabled.\n"

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

  echo "Ensuring 'sshrange' ipset is in a clean state..."
  # Attempt to remove existing ipset first, and handle if it's invalid or doesn't exist.
  # Use a subshell to avoid `set -e` exiting immediately if query/remove fails.
  (
    if sudo firewall-cmd --zone=public --query-ipset=sshrange \
      >/dev/null 2>&1; then
      echo "  'sshrange' ipset found. Attempting to remove it..."
      if ! sudo firewall-cmd --zone=public --remove-ipset=sshrange --permanent \
        >/dev/null 2>&1; then
        err "  Warning: Failed to gracefully remove existing 'sshrange' ipset."
        err "  You may need to manually clean up /etc/firewalld/ipsets/sshrange.xml \
        and/or references in /etc/firewalld/zones/public.xml"
        # We don't exit here immediately as we'll try to reload next,
        # which will fully confirm state.
        return 1 # Indicate failure in subshell
      fi
    else
      echo "'sshrange' ipset not found or query failed (likely not present)."
    fi
  )

  # Always try to reload after attempting to remove.
  # A failed reload here means a deeper issue.
  echo "Attempting firewalld reload to confirm clean state before creating ipset..."
  if ! sudo firewall-cmd --reload >/dev/null 2>&1; then
    err "  Critical: Firewalld reload failed. \
    This typically means the permanent configuration is corrupted."
    err "  Please manually fix firewalld configuration errors before re-running this script."
    err "  Check logs: 'sudo journalctl -u firewalld' and manually remove invalid entries."
    err "  Common fix: 'sudo systemctl stop firewalld', \
    remove /etc/firewalld/ipsets/sshrange.xml and any rich rules referring to \
    'sshrange' in /etc/firewalld/zones/public.xml, then 'sudo systemctl start firewalld'."
    exit 1
  fi

  # Create an ipset for allowed SSH IP ranges
  echo "Creating ipset for allowed SSH IP ranges..."
  if ! sudo firewall-cmd --zone=public --new-ipset=sshrange --type=hash:net --permanent \
    >/dev/null 2>&1; then
    # This error here now means a true conflict, not a corrupt state
    err "Failed to create ipset 'sshrange' after clean up attempt."
    err "It might still exist or there's another issue."
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
  # Check if the ICMP drop rule already exists before adding
  if sudo firewall-cmd --zone=public --query-rich-rule='rule protocol value="icmp" drop' \
    >/dev/null 2>&1; then
    echo "ICMP drop rule already exists. Skipping."
  else
    if ! sudo firewall-cmd --zone=public \
      --add-rich-rule='rule protocol value="icmp" drop' --permanent \
      >/dev/null 2>&1; then
      err "Failed to block ICMP."
    fi
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

  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Source and run purge_firewall
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/11_purge_firewall.sh"
  purge_firewall

  install_firewall

  # Source and run configure_sshd_config
  # shellcheck source=/dev/null
  source "${SCRIPT_DIR}/12_configure_sshd_config.sh"
  configure_sshd_config
}

main "$@"
