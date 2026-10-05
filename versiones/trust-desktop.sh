#!/bin/bash
set -euo pipefail

LAUNCHER="/usr/share/applications/install-system.desktop"

# Intenta actualizar cachés de .desktop (sin asumir DE específico)
# (No todos los sistemas tienen todos los comandos; los ignoramos si fallan)
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications >/dev/null 2>&1 || true
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q >/dev/null 2>&1 || true
fi

# También refrescar iconos por si aplica
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  # directorios típicos; ignoramos errores
  gtk-update-icon-cache -f /usr/share/icons/* >/dev/null 2>&1 || true
  gtk-update-icon-cache -f /usr/local/share/icons/* >/dev/null 2>&1 || true
fi

# "Trust" (opcional/específico). Si no existe o no aplica, simplemente se ignora.
# Se mantiene similar a tu lógica, pero ya no depende de plasmashell/xfce.
if command -v gio >/dev/null 2>&1; then
    if [ -f "$LAUNCHER" ]; then
      gio set "$LAUNCHER" metadata::trusted yes 2>/dev/null || true
    if command -v sha256sum >/dev/null 2>&1; then
      gio set "$LAUNCHER" metadata::xfce-exe-checksum "$(sha256sum "$LAUNCHER" | awk '{print $1}')" 2>/dev/null || true
    fi
  fi
fi
