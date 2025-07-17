#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 11_purge_firewall.sh
# Purpose: Remove ufw and flush iptables rules.
# Usage: Source from main script 10_configure_firewall.sh.
# Dependencies: sudo, ufw, iptables
#

#######################################
# Purges existing firewalls (ufw or iptables) if found.
# Globals:
#   None
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
    echo -e "iptables rules reset successfully.\n"
  else
    echo -e "iptables not found.\n"
  fi
}
