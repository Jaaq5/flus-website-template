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
  "201.191.0.0/16"
  "201.192.0.0/14"
  "201.196.0.0/14"
  "201.200.0.0/13"
  "181.193.152.0/21"
  "181.193.160.0/19"
  "181.193.192.0/19"
  "181.193.224.0/19"
  "181.194.0.0/16"
  "181.195.0.0/16"
  "186.176.0.0/16"
  "186.177.0.0/18"
  "186.177.64.0/18"
  "186.177.128.0/18"
)
