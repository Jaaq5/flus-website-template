#!/bin/bash
###############################################################################
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 02_configure_timezone.sh
# Verify and configure system timezone to America/Costa_Rica.
# Usage: ./02_configure_timezone.sh
# Dependencies: sudo, timedatectl, /sources/common.sh
###############################################################################

# SOURCES #####################################################################
# shellcheck source=/dev/null
source "$(dirname "$0")/sources/common.sh"

# FUNCTIONS ###################################################################

#######################################
# Ensure the system timezone is set to America/Costa_Rica.
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
configure_timezone() {
	clear
	echo -e "${ORANGE}🕙 Configuring system timezone...${NC}"
	local target="America/Costa_Rica"
	echo -e "Checking current timezone..."

	local current
	current=$(timedatectl | awk '/Time zone/ {print $3}')

	if [[ "$current" == "$target" ]]; then
		echo -e "${ORANGE}Timezone is already set to $target${NC}\n"
		return 0
	fi

	echo -e "Setting timezone to $target..."
	if ! sudo timedatectl set-timezone "$target"; then
		err "Failed to set timezone to $target"
		exit 1
	fi

	echo -e "Verifying updated timezone setting..."
	local updated
	updated=$(timedatectl | awk '/Time zone/ {print $3}')

	if [[ "$updated" == "$target" ]]; then
		echo -e "${GREEN}✅ Timezone successfully set to $target!${NC}\n"
	else
		err "Timezone was not correctly updated to $target\n"
		exit 1
	fi
}

configure_timezone
