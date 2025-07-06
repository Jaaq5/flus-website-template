#!/bin/bash

# Define color codes
GREEN='\033[0;32m'      # Success
ORANGE='\033[0;33m'     # Warning
RED='\033[0;31m'        # Fail
NC='\033[0m'            # No color (reset)

# Main function to update the system
update_system() {
    echo -e "${ORANGE}Actualizando la lista de paquetes disponibles...${NC}"
    sudo apt update
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Lista de paquetes actualizada correctamente.${NC}"
    else
        echo -e "${RED}Error al actualizar la lista de paquetes.${NC}"
        exit 1
    fi

    echo -e "${ORANGE}Actualizando los paquetes instalados...${NC}"
    sudo apt upgrade -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Paquetes actualizados correctamente.${NC}"
    else
        echo -e "${RED}Error al actualizar los paquetes instalados.${NC}"
        exit 1
    fi

    echo -e "${ORANGE}Eliminando paquetes innecesarios...${NC}"
    sudo apt autoremove -y
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Paquetes innecesarios eliminados correctamente.${NC}"
    else
        echo -e "${RED}Error al eliminar paquetes innecesarios.${NC}"
        exit 1
    fi
}

# Execute the main update function
update_system

# Final success message
echo -e "${GREEN}¡El sistema ha sido actualizado con éxito!${NC}"

