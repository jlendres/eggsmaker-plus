#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

LOG="script.log"
APT_LIST="lista-apt-manual.txt"
FLATPAK_LIST="lista-flatpak.txt"

CONFIG_DIR="$HOME/.config/pkg-transfer-debian"
APT_SEL="$CONFIG_DIR/apt_selected.txt"
FLATPAK_SEL="$CONFIG_DIR/flatpak_selected.txt"

APT_RM_SEL="$CONFIG_DIR/apt_remove.txt"
FLATPAK_RM_SEL="$CONFIG_DIR/flatpak_remove.txt"
mkdir -p "$CONFIG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG"
}

check_yad() {
  if ! command -v yad &>/dev/null; then
    echo "YAD no está instalado. Instalando..."
    sudo apt-get update -y
    sudo apt-get install -y yad || {
      echo "No se pudo instalar YAD. Saliendo."
      exit 1
    }
  fi
}

ensure_flatpak() {
  command -v flatpak &>/dev/null
}

recopilar_listas() {
  log "Generando listas..."
  rm -f "$APT_LIST" "$FLATPAK_LIST"

  # --- APT manuales solamente ---
  # apt-mark showmanual lista paquetes marcados como "manual"
  # (Normalmente excluye dependencias instaladas automáticamente.)
  if command -v apt-mark &>/dev/null; then
    apt-mark showmanual 2>/dev/null | sort > "$APT_LIST" || true
  else
    : > "$APT_LIST"
  fi
  ap_cnt=$(wc -l < "$APT_LIST")

  # --- Flatpak ---
  if ensure_flatpak; then
    flatpak list --app --columns=application > "$FLATPAK_LIST" 2>/dev/null || true
  else
    : > "$FLATPAK_LIST"
  fi
  fl_cnt=$(wc -l < "$FLATPAK_LIST")

  log "APT(manual): $ap_cnt | Flatpak: $fl_cnt"
  yad --info \
    --title="Listas generadas" \
    --text="APT (manual): $ap_cnt
Flatpak: $fl_cnt"
}

selector_paquetes() {
  local titulo="$1" lista="$2" sel_prev="$3" tipo="$4"
  local check_status="FALSE"

  while true; do
    if [[ ! -s "$lista" ]]; then
      yad --info --text="La lista de $tipo está vacía."
      return 1
    fi

    local -a opciones=()
    local checked

    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      if [[ -f "$sel_prev" ]] && grep -qxF "$pkg" "$sel_prev"; then
        checked="TRUE"
      else
        checked="$check_status"
      fi
      opciones+=("$checked" "$pkg" "$tipo")
    done < "$lista"

    local seleccion
    local exit_code

    seleccion=$(
      yad --list --checklist \
        --title="$titulo (Búsqueda: escriba para filtrar)" \
        --width=900 --height=650 --center \
        --column="Seleccionar:CHK" --column="Paquete" --column="Tipo" \
        "${opciones[@]}" \
        --print-column=2 --separator=$'\n' \
        --search-column=2 \
        --button="Aplicar:0" \
        --button="Atrás/Cancelar:1" \
        --button="Borrar Seleccionad@s:2" \
        --button="Marcar Todos:3" \
        --button="Desmarcar Todos:4"
    )
    exit_code=$?

    case $exit_code in
      0)
        printf "%s\n" "$seleccion" > "$sel_prev"
        return 0
        ;;
      1)
        return 1
        ;;
      2)
        if [[ -n "${seleccion:-}" ]]; then
          grep -vFf <(echo "$seleccion") "$lista" > "${lista}.tmp" && mv "${lista}.tmp" "$lista"
          if [[ -s "$sel_prev" ]]; then
            grep -vFf <(echo "$seleccion") "$sel_prev" > "${sel_prev}.tmp" && mv "${sel_prev}.tmp" "$sel_prev"
          fi
        else
          yad --info --text="No hay elementos seleccionados para borrar."
        fi
        ;;
      3)
        check_status="TRUE"
        rm -f "$sel_prev"
        ;;
      4)
        check_status="FALSE"
        rm -f "$sel_prev"
        ;;
      *)
        return 1
        ;;
    esac
  done
}

instalar_paquetes() {
  local had_any=0

  if [[ -s "$APT_SEL" ]]; then
    had_any=1
    log "Instalando paquetes APT (manual) seleccionados..."
    sudo apt-get update -y

    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      log "apt-get install: $pkg"
      if ! sudo apt-get install -y --no-install-recommends "$pkg"; then
        log "ERROR: No se pudo instalar $pkg (apt)"
      fi
    done < "$APT_SEL"
  fi

  if [[ -s "$FLATPAK_SEL" ]]; then
    had_any=1
    if ensure_flatpak; then
      log "Instalando apps Flatpak seleccionadas..."
      while IFS= read -r app; do
        [[ -n "$app" ]] || continue
        log "flatpak install: $app"
        if ! flatpak install -y "$app"; then
          log "ERROR: No se pudo instalar $app (flatpak)"
        fi
      done < "$FLATPAK_SEL"
    else
      yad --warning --text="No se pudo instalar/usar Flatpak. Omite Flatpak."
    fi
  fi

  if [[ $had_any -eq 0 ]]; then
    yad --info --text="No hay selección guardada para instalar."
  else
    yad --info --text="Instalación finalizada. Revisa $LOG para detalles."
  fi
}

desinstalar_paquetes() {
  local had_any=0

  if [[ -s "$APT_RM_SEL" ]]; then
    had_any=1
    log "Desinstalando paquetes APT seleccionados..."
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      log "apt-get purge: $pkg"
      if ! sudo apt-get purge -y "$pkg"; then
        log "ERROR: No se pudo desinstalar $pkg (apt)"
      fi
    done < "$APT_RM_SEL"

    # Limpia dependencias huérfanas
    sudo apt-get autoremove -y || true
  fi

  if [[ -s "$FLATPAK_RM_SEL" ]]; then
    had_any=1
    if ensure_flatpak; then
      log "Desinstalando apps Flatpak seleccionadas..."
      while IFS= read -r app; do
        [[ -n "$app" ]] || continue
        log "flatpak uninstall: $app"
        if ! flatpak uninstall -y "$app"; then
          log "ERROR: No se pudo desinstalar $app (flatpak)"
        fi
      done < "$FLATPAK_RM_SEL"
    else
      yad --warning --text="Flatpak no disponible."
    fi
  fi

  if [[ $had_any -eq 0 ]]; then
    yad --info --text="No hay selección guardada para desinstalar."
  else
    yad --info --text="✅ Desinstalación finalizada. Revisa $LOG para detalles."
  fi
}

instalar_menu() {
  while true; do
    local opcion
    opcion=$(
      yad --list --title="Menú de Instalación" --width=520 --height=340 \
          --column="Acción" --column="Descripción" \
          "Recopilar" "Recopilar paquetes instalados (APT manual) y Flatpak" \
          "Seleccionar" "Marcar/desmarcar qué paquetes instalar" \
          "Instalar" "Instalar según selección guardada" \
          "Salir" "Volver al menú principal" \
          --single-click
    )

    case "${opcion:-}" in
      Recopilar*) recopilar_listas ;;
      Seleccionar*)
        selector_paquetes "Seleccionar paquetes APT (manual)" "$APT_LIST" "$APT_SEL" "apt" || true
        selector_paquetes "Seleccionar aplicaciones Flatpak" "$FLATPAK_LIST" "$FLATPAK_SEL" "flatpak" || true
        ;;
      Instalar*) instalar_paquetes ;;
      Salir*|"") clear; return ;;
    esac
  done
}

desinstalar_menu() {
  while true; do
    local opcion
    opcion=$(
      yad --list --title="Menú de Desinstalación" \
          --width=540 --height=350 --center \
          --column="Acción" --column="Descripción" \
          "Recopilar" "Generar listas de paquetes (APT manual) y Flatpak" \
          "Seleccionar" "Marcar qué paquetes desinstalar" \
          "Desinstalar" "Eliminar los paquetes seleccionados" \
          "Salir" "Volver al menú principal" \
          --single-click
    )

    case "${opcion:-}" in
      Recopilar*) recopilar_listas ;;
      Seleccionar*)
        selector_paquetes "APT(manual): marcar para DESINSTALAR" "$APT_LIST" "$APT_RM_SEL" "apt" || true
        selector_paquetes "Flatpak: marcar para DESINSTALAR" "$FLATPAK_LIST" "$FLATPAK_RM_SEL" "flatpak" || true
        ;;
      Desinstalar*) desinstalar_paquetes ;;
      Salir*|"") clear; return ;;
    esac
  done
}

main_menu_launcher() {
  while true; do
    local opcion
    opcion=$(
      yad --list --title="Gestor de Paquetes (Debian + Flatpak)" \
          --width=420 --height=210 --center \
          --column="Acción" --column="Descripción" \
          "Instalar" "Gestionar instalación de paquetes (APT manual / Flatpak)" \
          "Desinstalar" "Gestionar desinstalación de paquetes (APT manual / Flatpak)" \
          "Salir" "Salir del gestor" \
          --single-click
    )

    case "${opcion:-}" in
      Instalar*) instalar_menu ;;
      Desinstalar*) desinstalar_menu ;;
      Salir*|"") clear; exit 0 ;;
    esac
  done
}

check_yad
main_menu_launcher
