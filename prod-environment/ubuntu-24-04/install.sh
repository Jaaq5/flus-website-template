#!/bin/bash
set -euo pipefail

UPDATE_SCRIPT="./update.sh"

if [[ ! -x "$UPDATE_SCRIPT" ]]; then
  chmod +x "$UPDATE_SCRIPT"
fi

echo "🚀 Ejecutando actualización del sistema..."
"$UPDATE_SCRIPT"

echo "📦 Instalando dependencias adicionales..."
# sudo apt install -y curl wget

echo "✅ Instalación completada con éxito."
