#!/bin/bash
# Script de Instalación Integrado de Eggsmaker

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root (sudo ./install.sh)"
   exit 1
fi

echo "==> Instalando suite Eggsmaker..."

# 1. Copiar script ejecutable a la raíz de binaries
BIN_DEST="/usr/local/bin/eggsmaker"
cp -f "./eggsmaker" "$BIN_DEST"
chmod 755 "$BIN_DEST"
chown root:root "$BIN_DEST"

# 2. Crear archivo .desktop para la integración en el Menú de Aplicaciones
DESKTOP_FILE="/usr/share/applications/eggsmaker.desktop"

cat << 'EOF' > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Eggsmaker
Name[es]=Eggsmaker
Comment=Herramientas de gestión y creación de ISOs con Penguins Eggs
Comment[es]=Herramientas de gestión y creación de ISOs con Penguins Eggs
Exec=pkexec /usr/local/bin/eggsmaker
Icon=system-software-install
Terminal=false
Categories=System;Utility;Settings;
StartupNotify=true
EOF

chmod 644 "$DESKTOP_FILE"

# 3. Regla Polkit para permitir ejecución con elevación de privilegios gráfica
POLKIT_POLICY="/usr/share/polkit-1/actions/org.eggsmaker.policy"

cat << 'EOF' > "$POLKIT_POLICY"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="org.eggsmaker.pkexec">
    <description>Ejecutar Eggsmaker con privilegios de administrador</description>
    <message>Se requieren privilegios de superusuario para ejecutar Eggsmaker</message>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>auth_admin</allow_active>
    </defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/usr/local/bin/eggsmaker</annotate>
    <annotate key="org.freedesktop.policykit.exec.allow_gui">true</annotate>
  </action>
</policyconfig>
EOF

chmod 644 "$POLKIT_POLICY"

# 4. Actualizar las bases de datos del sistema
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi

echo "==> ¡Instalación completada con éxito!"
echo "Puede encontrar Eggsmaker en la categoría 'Herramientas' / 'Sistema' del menú de aplicaciones."
