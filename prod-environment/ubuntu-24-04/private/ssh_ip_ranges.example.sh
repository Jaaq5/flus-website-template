#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
# Make a copy of this file as ssh_ip_ranges.sh
# and define your allowed SSH IP ranges in the array below.
#
# ssh_ip_ranges.example.sh
# Purpose: Define the array of allowed SSH IP ranges.
# Usage: ../10_configure_firewall.sh
# Dependencies: None

# Define the array directly
# Each entry should be enclosed in double quotes.
# shellcheck disable=SC2034
readonly SSH_ALLOWED_IP_RANGES=(
  "100.100.0.0/16"
  "100.100.0.0/14"
)
