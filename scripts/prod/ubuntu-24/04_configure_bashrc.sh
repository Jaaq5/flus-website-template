#!/bin/bash
###############################################################################
# Style guide: https://google.github.io/styleguide/shellguide.html
#
# 04_configure_bashrc.sh
# Purpose: Backup existing ~/.bashrc and replace with template.
# Usage: ./04_configure_bashrc.sh
# Dependencies: bash, /sources/common.sh, /template-files/.bashrc.sh
###############################################################################

# SOURCES #####################################################################
# shellcheck source=/dev/null
source "$(dirname "$0")/sources/common.sh"

# FUNCTIONS ###################################################################

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
  local template_dir="./template-files"
  local template_file=".bashrc"
  local src="${template_dir}/${template_file}"
  local dest="$HOME/.bashrc"
  local backup="${dest}.backup"

  echo -e "${ORANGE}⚙️ Configuring ~/.bashrc from template...${NC}"

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

  echo -e "Copying new .bashrc from template..."
  cp "$src" "$dest"

  echo -e "Sourcing updated .bashrc..."
  # shellcheck source=/dev/null
  source "$dest"

  echo -e "${GREEN}✅ .bashrc updated successfully!${NC}\n"
}

configure_bashrc
