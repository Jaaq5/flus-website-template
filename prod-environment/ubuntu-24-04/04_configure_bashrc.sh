#!/bin/bash
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 04_configure_bashrc.sh
# Purpose: Backup existing ~/.bashrc and replace with template.
# Usage: ./04_configure_bashrc.sh
# Dependencies: bash, files-templates/.bashrc.sh

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Constants for colored output
readonly GREEN='\033[0;32m'  # Success
readonly ORANGE='\033[0;33m' # Info/warning
readonly RED='\033[0;31m'    # Error
readonly NC='\033[0m'        # No color (reset)

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
# Backup ~/.bashrc and install new template.
# Globals:
#   ORANGE
#   GREEN
#   NC
# Arguments:
#   None
# Outputs:
#   Status messages to STDOUT/STDERR.
# Returns:
#   Exits non-zero on failure.
#######################################
configure_bashrc() {
  local template_dir="./files-templates"
  local template_file=".bashrc"
  local src="${template_dir}/${template_file}"
  local dest="$HOME/.bashrc"
  local backup="${dest}.backup"

  echo -e "Checking for template file at ${src}..."
  if [[ ! -f "$src" ]]; then
    err "Template file '${src}' not found."
    exit 1
  fi

  echo -e "Backing up existing .bashrc to ${backup}..."
  if [[ -f "$dest" ]]; then
    cp "$dest" "$backup"
  else
    echo -e "${ORANGE}No existing ~/.bashrc found; skipping backup.${NC}"
  fi

  echo -e "Installing new .bashrc from template..."
  cp "$src" "$dest"

  echo -e "Sourcing updated .bashrc..."
  # shellcheck source=/dev/null
  source "$dest"

  echo -e "${GREEN}✅ .bashrc configured successfully!${NC}\n"
}

#######################################
# Main entry point.
# Globals:
#   ORANGE
#   NC
# Arguments:
#   None
# Outputs:
#   Startup message to STDOUT.
#######################################
main() {
  echo -e "${ORANGE}⚙️ Configuring ~/.bashrc from template...${NC}"
  configure_bashrc
}

# Execute main function
main "$@"
