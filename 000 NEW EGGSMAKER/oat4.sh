#!/bin/bash
# Copiar y reemplazar trust-desktop.sh al inicio
SRC="/home/jorge/trust-desktop.sh"
DST="/etc/penguins-eggs.d/scripts/trust-desktop.sh"

if [[ -f "$SRC" ]]; then
  sudo cp -f "$SRC" "$DST"
else
  echo "No existe el archivo fuente: $SRC"
  exit 1
fi

# Configuración
ISO_DIR="/home/eggs"

# Colores terminal
VERDE='\033[0;32m'; AZUL='\033[0;34m'; ROJO='\033[0;31m'; NC='\033[0m'

DID_RUN=0  # 1 si se ejecuta remaster/remaster --clone

echo -e "${VERDE}===========================================${NC}"
echo -e "        Eggsmaker-OA-Tools-TUI             "
echo -e "${AZUL}    OA-TOOLS - Version: $(eggs version)    ${NC}"
echo -e "${VERDE}===========================================${NC}"

# 1) Cambios en la configuración
read -p "¿Desea hacer cambios en la configuración? (s/n): " RESP_CONFIG
if [[ "$RESP_CONFIG" == "s" ]]; then
    sudo eggs config
fi

# 2) Grabado de configuración del escritorio actualizada
read -p "¿Desea grabar la configuración del escritorio actualizada? (s/n): " RESP_GRABAR

# Según tu regla:
# - si fue "s" en pregunta 1 y "s" en pregunta 2 => sigue
# - si fue "s" en pregunta 1 y "n" en pregunta 2 => pasa a clonar
# - si fue "n" en pregunta 1 => pasa a clonar igualmente
# En la práctica: si RESP_GRABAR es s o n, igual se llega a pregunta 4 (clonar).
# Pero seguimos el cuestionario tal como lo pediste:
# => siempre se pregunta clonar (pregunta 4) cuando corresponde.
# (Aquí lo implementamos preguntando clonar siempre después de grabar, sin usar remaster sin motivo.)

# 3/4) Clonar o no (pregunta por remaster/remaster --clone)
read -p "¿Desea clonar el sistema? (s/n): " RESP_CLONAR

echo -e "${AZUL}Iniciando limpieza y remasterización...${NC}"
sudo eggs kill
sudo eggs tools clean

START_TIME=$(date +%s)

if [[ "$RESP_CLONAR" == "s" ]]; then
    # MUY IMPORTANTE: si se clona, SOLO remaster --clone y se omite remaster
    sudo eggs remaster --clone
else
    # Si NO se clona, se ejecuta remaster estándar
    sudo eggs remaster
fi

END_TIME=$(date +%s)
DID_RUN=1

# 5) Copia (solo si se ejecutó remaster o remaster --clone)
# 3) Copia (se pregunta igual)
if [[ "$DID_RUN" == "1" ]]; then

    # Asegurar entorno gráfico (KDE a veces requiere XAUTHORITY explícito)
    export DISPLAY="${DISPLAY:-:0}"
    export XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}"

    ISO_FILE=$(ls -t "$ISO_DIR"/*.iso 2>/dev/null | head -n 1)

    pedir_destino() {
        local d=""
        # Intento 1: yad (si existe)
        if command -v yad >/dev/null 2>&1; then
            d=$(yad --file --directory --title="Seleccione la carpeta de destino" 2>/dev/null)
            d=$(echo "$d" | head -n 1)
        fi

        # Intento 2: zenity
        if [[ -z "$d" ]] && command -v zenity >/dev/null 2>&1; then
            d=$(zenity --file-selection --directory --title="Seleccione la carpeta de destino" 2>/dev/null)
            d=$(echo "$d" | head -n 1)
        fi

        # Intento 3: kdialog
        if [[ -z "$d" ]] && command -v kdialog >/dev/null 2>&1; then
            d=$(kdialog --getexistingdirectory "Seleccione la carpeta de destino" 2>/dev/null)
            d=$(echo "$d" | head -n 1)
        fi

        echo "$d"
    }

    while true; do
        echo -e "${AZUL}Abriendo selector de destino...${NC}"
        DESTINO="$(pedir_destino)"

        # Si el selector falló (DESTINO vacío), no lo tratamos como "omitido":
        # repetimos el cuestionario hasta que el usuario elija una carpeta o cancele desde el diálogo.
        if [[ -z "$DESTINO" ]]; then
            read -p "No se pudo seleccionar carpeta (selector falló o se cerró). ¿Desea omitir la copia? (s/n): " OMT
            if [[ "$OMT" == "s" ]]; then
                echo "Copia omitida por el usuario."
                break
            else
                continue
            fi
        fi

        if [[ -n "$ISO_FILE" ]]; then
            echo "Copiando ISO a $DESTINO..."
            rsync --progress -h "$ISO_FILE" "$DESTINO"
        else
            echo -e "${ROJO}No se encontró ISO en $ISO_DIR. Copiando artefactos disponibles...${NC}"
            rsync --progress -ah "$ISO_DIR"/ "$DESTINO"/
        fi

        read -p "¿Desea realizar otra copia? (s/n): " OTRA
        if [[ "$OTRA" != "s" ]]; then
            break
        fi
    done
fi

# 6) Limpieza final
read -p "¿Desea eliminar los archivos temporales (eggs kill)? (s/n): " LIMPIAR
if [[ "$LIMPIAR" == "s" ]]; then
    sudo eggs kill
    echo "Archivos temporales eliminados."
fi

echo -e "${VERDE}Proceso finalizado. ¡Hasta pronto!${NC}"
