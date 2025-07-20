#!/bin/bash
###############################################################################
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# common.sh
# Reusable functions/constants: safe flags, colors, err().
###############################################################################

# GLOBALS #####################################################################

# Exit on error, unset variable, or pipeline failure.
set -euo pipefail

# Constants for colored output.
# shellcheck disable=SC2034
readonly GREEN='\033[0;32m' # Success
# shellcheck disable=SC2034
readonly ORANGE='\033[0;33m' # Warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

# FUNCTIONS ###################################################################

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
