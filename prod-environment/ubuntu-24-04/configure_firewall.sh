#!/bin/bash
# Style guide https://google.github.io/styleguide/shellguide.html
#
# configure_firewall.sh
# Purpose: Remove existing ufw/iptables, install and configure firewalld
# Usage: ./configure_firewall.sh
# Dependencies: sudo, apt-get, firewalld
#

# Exit on error, unset variable, or pipeline failure
set -euo pipefail

# Color codes for terminal output
GREEN='\033[0;32m'   # Success
ORANGE='\033[0;33m'  # Warning
RED='\033[0;31m'     # Error
NC='\033[0m'         # No color (reset)

#######################################
# Checks if a command exists on the system.
# Arguments:
#   $1 - Command to check.
# Returns:
#   0 if command exists, non-zero otherwise.
#######################################
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# Purges existing firewalls (ufw or iptables) if found.
# Arguments:
#   None
# Outputs:
#   Removes previous firewall configurations.
# Returns:
#   None.
#######################################
purge_firewall() {
    echo -e "Comprobando y eliminando firewalls existentes..."

    # Remove UFW if installed
    if command_exists ufw; then
        echo "Desinstalando ufw..."
        sudo ufw --force reset 1>/dev/null 2>&1
        sudo apt-get purge -y ufw 1>/dev/null 2>&1
        echo -e "ufw desinstalado correctamente"
    fi
  
    # Flush iptables if installed
    if command_exists iptables; then
        echo "Limpiando reglas de iptables..."
        sudo iptables -F 1>/dev/null 2>&1
        sudo iptables -t nat -F 1>/dev/null 2>&1
        sudo iptables -t mangle -F 1>/dev/null 2>&1
        sudo iptables -P INPUT ACCEPT 1>/dev/null 2>&1
        sudo iptables -P OUTPUT ACCEPT 1>/dev/null 2>&1
        
        # Check if /etc/iptables/rules.v4 exists before saving
        if [ -f /etc/iptables/rules.v4 ]; then
            sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null || true
        fi

        echo -e "Reglas de iptables restablecidas  correctamente"
    fi
}

#######################################
# Installs and configures firewalld with basic rules.
# Arguments:
#   None
# Outputs:
#   Installs firewalld and configures rules for SSH, HTTP, and HTTPS.
# Returns:
#   None.
#######################################
install_firewall() {
    echo -e "Verificando e instalando firewalld..."

    # Check if firewalld is installed
    if command_exists firewall-cmd; then
        echo -e "${ORANGE}firewalld ya está instalado.${NC}\n"
        return 0
    else
        # Install firewalld
        sudo NEEDRESTART_SUSPEND=1 apt-get install -y -qq firewalld 1>/dev/null
        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Error al instalar firewalld.${NC}" >&2
            exit 1
        fi
    
        # Start and enable firewalld
        sudo systemctl start firewalld 1>/dev/null 2>&1
        sudo systemctl enable firewalld 1>/dev/null 2>&1

        echo "Configurando zonas predeterminadas..."
        
        # Set default zone to 'public'
        sudo firewall-cmd --set-default-zone=public 1>/dev/null 2>&1

        echo "Permitiendo SSH, HTTP y HTTPS..."

        # Allow SSH, HTTP, and HTTPS traffic
        sudo firewall-cmd --zone=public --add-service=ssh 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=http 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --add-service=https 1>/dev/null 2>&1

        # Limit SSH connections to 2/m and save log
        sudo firewall-cmd --zone=public --add-rich-rule='rule service name="ssh" limit value="2/m" log prefix="SSH_RATE" level="notice" accept' 1>/dev/null 2>&1
        # Run in terminal: sudo grep "SSH_RATE" /var/log/firewalld

        # Create range for accepted ips
        sudo firewall-cmd --zone=public --new-ipset=sshrange --type=hash:net 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --ipset=sshrange --add-entry=201.191.0.0/16 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --ipset=sshrange --add-entry=201.192.0.0/14 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --ipset=sshrange --add-entry=201.196.0.0/14 1>/dev/null 2>&1
        sudo firewall-cmd --zone=public --ipset=sshrange --add-entry=201.200.0.0/13 1>/dev/null 2>&1
        # Apply rule
        sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source ipset="sshrange" service name="ssh" accept' 1>/dev/null 2>&1
        
        # Block ICMP (ping)
        sudo firewall-cmd  --zone=public --add-rich-rule='rule protocol value="icmp" drop' 1>/dev/null 2>&1

        # Block everything not autorized
        sudo firewall-cmd --zone=public --set-target=DROP 1>/dev/null 2>&1

        # Reload firewalld to apply changes
        sudo firewall-cmd --reload 1>/dev/null 2>&1
        
        # Save configurations permanently
        sudo firewall-cmd --runtime-to-permanent 1>/dev/null 2>&1
        
        echo -e "${GREEN}firewalld instalado correctamente${NC}\n"
    fi
}

#######################################
# Configures the sshd_config file to enhance security.
# Arguments:
#   None
# Outputs:
#   Updates the sshd_config file with secure settings.
# Returns:
#   None.
#######################################
configure_sshd_config() {
    echo -e "Verificando configuración de sshd_config..."

    # File location
    SSHD_CONFIG="/etc/ssh/sshd_config"

    # Check if the file exists
    if [ ! -f "$SSHD_CONFIG" ]; then
        echo -e "${RED}El archivo $SSHD_CONFIG no existe.${NC}\n"
        exit 1
    fi

    # Ensure PasswordAuthentication is set to "no"
    if ! grep -q "^PasswordAuthentication no" "$SSHD_CONFIG"; then
        echo "Desactivando autenticación por contraseña..."
        sudo sed -i '/^#PasswordAuthentication yes/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD_CONFIG"
    fi

    # Ensure PermitRootLogin is set to "prohibit-password"
    if ! grep -q "^PermitRootLogin prohibit-password" "$SSHD_CONFIG"; then
        echo "Desactivando acceso como root por contraseña..."
        sudo sed -i '/^#PermitRootLogin/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^PermitRootLogin .*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
    fi

    # Ensure KbdInteractiveAuthentication is set to "no"
    if ! grep -q "^KbdInteractiveAuthentication no" "$SSHD_CONFIG"; then
        echo "Desactivando autenticación interactiva..."
        sudo sed -i '/^#KbdInteractiveAuthentication yes/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^KbdInteractiveAuthentication .*/KbdInteractiveAuthentication no/' "$SSHD_CONFIG"
    fi

    # Ensure PubkeyAuthentication is set to "yes"
    if ! grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG"; then
        echo "Habilitando autenticación por clave pública..."
        sudo sed -i '/^#PubkeyAuthentication yes/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^PubkeyAuthentication .*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
    fi

    # Disable PAM authentication
    if ! grep -q "^UsePAM no" "$SSHD_CONFIG"; then
        echo "Desactivando autenticación PAM..."
        sudo sed -i '/^#UsePAM yes/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^UsePAM .*/UsePAM no/' "$SSHD_CONFIG"
    fi

    # Set MaxAuthTries to 5
    if ! grep -q "^MaxAuthTries 5" "$SSHD_CONFIG"; then
        echo "Estableciendo MaxAuthTries a 5..."
        sudo sed -i '/^#MaxAuthTries.*/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^MaxAuthTries .*/MaxAuthTries 5/' "$SSHD_CONFIG"
    fi

    # Set MaxSessions to 5
    if ! grep -q "^MaxSessions 5" "$SSHD_CONFIG"; then
        echo "Estableciendo MaxSessions a 5..."
        sudo sed -i '/^#MaxSessions.*/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^MaxSessions .*/MaxSessions 5/' "$SSHD_CONFIG"
    fi

    # Set ClientAliveInterval to 600 (10 minutes)
    if ! grep -q "^ClientAliveInterval 600" "$SSHD_CONFIG"; then
        echo "Estableciendo ClientAliveInterval a 600 segundos..."
        sudo sed -i '/^#ClientAliveInterval.*/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^ClientAliveInterval .*/ClientAliveInterval 600/' "$SSHD_CONFIG"
    fi

    # Set ClientAliveCountMax to 0
    if ! grep -q "^ClientAliveCountMax 0" "$SSHD_CONFIG"; then
        echo "Estableciendo ClientAliveCountMax a 0..."
        sudo sed -i '/^#ClientAliveCountMax.*/s/^#//' "$SSHD_CONFIG"
        sudo sed -i 's/^ClientAliveCountMax .*/ClientAliveCountMax 0/' "$SSHD_CONFIG"
    fi

    # Restart SSH service to apply changes
    echo -e "Reiniciando servicio SSH..."
    sudo systemctl restart sshd
}

#######################################
# Main entry point for the script.
# Arguments:
#   None
# Outputs:
#   Final status message indicating success.
# Returns:
#   None; exits on any error.
#######################################
main() {
  echo -e "${ORANGE}🧱 Iniciando configuración de firewall...${NC}"

  # Purge any existing firewalls (UFW, iptables)
  purge_firewall
  
  # Install and configure firewalld with basic rules
  install_firewall

   # Configure sshd_config for secure settings
   configure_sshd_config
}

# Execute the main function
main "$@"
