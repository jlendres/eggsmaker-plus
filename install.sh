#!/bin/bash
# ==============================================================================
# Script de Instalación de Eggsmaker
# ==============================================================================

set -euo pipefail

# Verificar permisos de superusuario
if [ "$EUID" -ne 0 ]; then
  echo "Error: Este script debe ejecutarse con sudo o como root." >&2
  exit 1
fi

# Obtener el directorio donde se encuentra este script install.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Instalando Eggsmaker..."

# 1. Copiar el ejecutable principal
if [ -f "$SCRIPT_DIR/eggsmaker" ]; then
  cp "$SCRIPT_DIR/eggsmaker" /usr/local/bin/eggsmaker
  chmod +x /usr/local/bin/eggsmaker
  echo "  [✓] Ejecutable copiado a /usr/local/bin/eggsmaker"
else
  echo "  [!] Advertencia: No se encontró el archivo 'eggsmaker' en $SCRIPT_DIR"
fi

# 2. Copiar el icono a /usr/share/pixmaps
mkdir -p /usr/share/pixmaps

# Busca assets/eggsmaker.png o assets/eggmaker.png por si varía el nombre
ICON_SOURCE=""
if [ -f "$SCRIPT_DIR/assets/eggsmaker.png" ]; then
  ICON_SOURCE="$SCRIPT_DIR/assets/eggsmaker.png"
elif [ -f "$SCRIPT_DIR/assets/eggmaker.png" ]; then
  ICON_SOURCE="$SCRIPT_DIR/assets/eggmaker.png"
fi

if [ -n "$ICON_SOURCE" ]; then
  cp "$ICON_SOURCE" /usr/share/pixmaps/eggsmaker.png
  chmod 644 /usr/share/pixmaps/eggsmaker.png
  echo "  [✓] Icono copiado a /usr/share/pixmaps/eggsmaker.png"
else
  echo "  [!] Advertencia: No se encontró el icono en assets/eggsmaker.png ni assets/eggmaker.png"
fi

# 3. Crear el lanzador .desktop en el sistema
DESKTOP_FILE="/usr/share/applications/eggsmaker.desktop"
cat << 'EOF' > "$DESKTOP_FILE"
[Desktop Entry]
Name=Eggsmaker
Comment=Suite para administración de Penguins Eggs y Paquetes
Exec=sudo /usr/local/bin/eggsmaker
Icon=eggsmaker
Terminal=true
Type=Application
Categories=System;Utility;
EOF

chmod 644 "$DESKTOP_FILE"
echo "  [✓] Lanzador creado en $DESKTOP_FILE"

# Actualizar base de datos de escritorio si existe el comando
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database -q /usr/share/applications || true
fi

echo "==> Instalación completada con éxito."
