#!/bin/bash
###############################################################################
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 03_install_dependencies.sh
# Purpose: Verify and install required system dependencies.
# Usage: ./03_install_dependencies.sh
# Dependencies: sudo, apt-get, dpkg-query, /sources/common.sh
###############################################################################

# SOURCES #####################################################################
# shellcheck source=/dev/null
source "$(dirname "$0")/sources/common.sh"

# FUNCTIONS ###################################################################

#######################################
# Check if a package is installed.
# Globals:
#   None
# Arguments:
#   $1 - package name.
# Returns:
#   0 if installed, non-zero otherwise.
#######################################
is_installed() {
  dpkg-query -Wf='${db:Status-abbrev}' "$1" 2>/dev/null | grep -q '^i'
}

#######################################
# Install a package using apt-get.
# Globals:
#   GREEN
#   NC
# Arguments:
#   $1 - package name
# Outputs:
#   Messages to STDOUT or to STDERR on error.
# Returns:
#   0 if successful, exits non-zero on failure.
#######################################
install_pkg() {
  local pkg="$1"
  echo -e "Installing package: ${pkg}..."
  if ! sudo apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
    err "Failed to install package: ${pkg}"
    exit 1
  fi
  echo -e "${GREEN}Package ${pkg} installed successfully.${NC}"
}

#######################################
# Verify and install missing dependencies.
# Globals:
#   ORANGE
#   GREEN
#   NC
#   PACKAGES
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT or to STDERR on error.
# Returns:
#   0 if successful, exits non-zero on any install failure.
#######################################
check_and_install_dependencies() {

  clear
  echo -e "${ORANGE}🔧 Verifying and installing dependencies...${NC}"

  for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
      echo -e "${ORANGE}Already installed: ${pkg}${NC}"
    else
      install_pkg "$pkg"
    fi
  done
  echo -e "${GREEN}✅ All dependencies are now installed.${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT or to STDERR on error.
# Returns:
#   0 if successful, exits non-zero on failure.
#######################################
main() {
  check_and_install_dependencies
}

main "$@"
