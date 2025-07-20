#!/bin/bash
###############################################################################
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 01_update_system.sh
# Update and upgrade Ubuntu system packages.
# Usage: ./01_update_system.sh
# Dependencies: sudo, apt-get, /sources/common.sh
###############################################################################

# SOURCES #####################################################################
# shellcheck source=/dev/null
source "$(dirname "$0")/sources/common.sh"

# FUNCTIONS ###################################################################

#######################################
# Update and clean up system packages.
# Globals:
#   GREEN
#   ORANGE
#   RED
#   NC
# Arguments:
#   None
# Outputs:
#   Messages to STDOUT or to STDERR on error.
# Returns:
#   0 if successful, 1 if any command fails.
#######################################
update_system() {
	clear
	echo -e "${ORANGE}📦 Running system update...${NC}"
	echo -e "Updating package list..."
	if ! sudo apt-get update -qq >/dev/null 2>&1; then
		err "❌ Failed to update package list."
		exit 1
	fi

	echo -e "Upgrading installed packages..."
	if ! sudo apt-get upgrade -y -qq >/dev/null 2>&1; then
		err "❌ Failed to upgrade installed packages."
		exit 1
	fi

	echo -e "Removing unnecessary packages..."
	if ! sudo apt-get autoremove -y -qq >/dev/null 2>&1; then
		err "❌ Failed to remove unnecessary packages."
		exit 1
	fi

	echo -e "${GREEN}✅ System successfully updated!${NC}\n"
}

update_system
