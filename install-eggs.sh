instalar_entorno_eggs() {
  echo "Verificando componentes base de ISO (Calamares y Eggs)..."

  # 1. Asegurar repositorio oficial de Eggs mediante su comando nativo
  if command -v eggs &>/dev/null; then
    echo "Configurando repositorio de actualización de Eggs..."
    eggs repo install
    if [ "$DISTRO_FAMILY" = "arch" ]; then
      pacman -Sy
    elif [ "$DISTRO_FAMILY" = "debian" ]; then
      apt-get update
    fi
  fi

  # 2. Instalar Calamares si no está presente
  if ! command -v calamares &>/dev/null; then
    echo "Instalando Calamares..."
    if [ "$DISTRO_FAMILY" = "arch" ]; then
      pacman -S --needed --noconfirm calamares
    elif [ "$DISTRO_FAMILY" = "debian" ]; then
      apt-get update && apt-get install -y calamares
    fi
  fi

  # 3. Instalar Penguins Eggs si no está presente
  if ! command -v eggs &>/dev/null; then
    echo "Penguins Eggs no detectado. Instalando..."

    if [ "$DISTRO_FAMILY" = "arch" ]; then
      # Si el repositorio ya fue agregado manualmente previa instalación:
      if pacman -Si penguins-eggs &>/dev/null; then
        pacman -S --needed --noconfirm penguins-eggs
      elif command -v yay &>/dev/null; then
        sudo -u "$REAL_USER" yay -S --noconfirm penguins-eggs
      fi

    elif [ "$DISTRO_FAMILY" = "debian" ]; then
      # Descarga e instalación del .deb de release inicial
      local deb_url
      deb_url=$(curl -s https://api.github.com/repos/pieroproietti/penguins-eggs/releases/latest | grep "browser_download_url.*_amd64.deb" | cut -d : -f 2,3 | tr -d \")

      if [ -n "$deb_url" ]; then
        curl -L "$deb_url" -o /tmp/penguins-eggs.deb
        apt-get update
        apt-get install -y /tmp/penguins-eggs.deb
        rm -f /tmp/penguins-eggs.deb
        # Activa el PPA para futuras actualizaciones vía apt
        eggs repo install
        apt-get update
      fi
    fi
  fi
}
