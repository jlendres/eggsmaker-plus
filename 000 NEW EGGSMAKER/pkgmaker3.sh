#!/bin/bash

# =====================================
# Gestor de Paquetes Unificado (Bash)
# Incluye funciones de instalación y desinstalación
# para pacman, yay (AUR) y flatpak.
# =====================================

set -o errexit
set -o nounset
set -o pipefail

LOG="script.log"
PACMAN_LIST="lista-pacman.txt"
YAY_LIST="lista-yay.txt"
FLATPAK_LIST="lista-flatpak.txt"

CONFIG_DIR="$HOME/.config/pkg-transfer"
PACMAN_SEL="$CONFIG_DIR/pacman_selected.txt"
YAY_SEL="$CONFIG_DIR/yay_selected.txt"
FLATPAK_SEL="$CONFIG_DIR/flatpak_selected.txt"

PACMAN_RM_SEL="$CONFIG_DIR/pacman_remove.txt"
YAY_RM_SEL="$CONFIG_DIR/yay_remove.txt"
FLATPAK_RM_SEL="$CONFIG_DIR/flatpak_remove.txt"
mkdir -p "$CONFIG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG"
}

check_yad() {
  if ! command -v yad &>/dev/null; then
    echo "YAD no está instalado. Instalando..."
    sudo pacman -S --noconfirm yad || {
      echo "No se pudo instalar YAD. Saliendo."
      exit 1
    }
  fi
}

ensure_yay() {
  command -v yay &>/dev/null
}

ensure_flatpak() {
  command -v flatpak &>/dev/null
}

recopilar_listas() {
  log "Generando listas de paquetes instalados..."
  rm -f "$PACMAN_LIST" "$YAY_LIST" "$FLATPAK_LIST"

  pacman -Qqetn | sort | grep -vwE '^(base|base-devel)$' > "$PACMAN_LIST"
  pc_cnt=$(wc -l < "$PACMAN_LIST")

  pacman -Qqetm | sort > "$YAY_LIST"
  yay_cnt=$(wc -l < "$YAY_LIST")

  if ensure_flatpak; then
    flatpak list --app --columns=application > "$FLATPAK_LIST"
  else
    : > "$FLATPAK_LIST"
  fi
  fl_cnt=$(wc -l < "$FLATPAK_LIST")

  log "Pacman: $pc_cnt | Yay: $yay_cnt | Flatpak: $fl_cnt"

  yad --info \
    --title="Listas generadas" \
    --text="Pacman: $pc_cnt
Yay: $yay_cnt
Flatpak: $fl_cnt"
}

selector_paquetes() {
  local titulo="$1" lista="$2" sel_prev="$3" tipo="$4"
  local check_status="FALSE"
  local button_text="Aplicar"

  if [[ "$tipo" == "pacman" && "$titulo" =~ "Seleccionar" ]]; then
    if [[ "$titulo" == "Seleccionar paquetes Pacman" ]]; then
      check_status="TRUE"
      button_text="Continuar"
    elif [[ "$titulo" == "Seleccionar paquetes Yay (AUR)" ]]; then
      check_status="TRUE"
      button_text="Continuar"
    elif [[ "$titulo" == "Seleccionar paquetes Flatpak" ]]; then
      check_status="TRUE"
      button_text="Continuar"
    fi
  fi

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
        --button="$button_text:0" \
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
        if [[ -n "$seleccion" ]]; then
          grep -vFf <(echo "$seleccion") "$lista" > "${lista}.tmp" && mv "${lista}.tmp" "$lista"
          if [[ -s "$sel_prev" ]]; then
            grep -vFf <(echo "$seleccion") "$sel_prev" > "${sel_prev}.tmp" && mv "${sel_prev}.tmp" "$sel_prev"
          fi
        else
          yad --info --text="No hay paquetes seleccionados para borrar."
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

  if [[ -s "$PACMAN_SEL" ]]; then
    had_any=1
    log "Instalando paquetes Pacman seleccionados..."
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      log "pacman: $pkg"
      if ! sudo pacman -S --needed --noconfirm "$pkg"; then
        log "ERROR: No se pudo instalar $pkg (pacman)"
      fi
    done < "$PACMAN_SEL"
  fi

  if [[ -s "$YAY_SEL" ]]; then
    had_any=1
    if ensure_yay; then
      log "Instalando paquetes AUR (yay) seleccionados..."
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        log "yay: $pkg"
        if ! yay -S --needed --noconfirm "$pkg"; then
          log "ERROR: No se pudo instalar $pkg (yay)"
        fi
      done < "$YAY_SEL"
    else
      yad --warning --text="No se encontró 'yay'. Omite instalación de AUR."
    fi
  fi

  if [[ -s "$FLATPAK_SEL" ]]; then
    had_any=1
    if ensure_flatpak; then
      log "Instalando aplicaciones Flatpak seleccionadas..."
      while IFS= read -r app; do
        [[ -n "$app" ]] || continue
        log "flatpak: $app"
        if ! flatpak install -y "$app"; then
          log "ERROR: No se pudo instalar $app (flatpak)"
        fi
      done < "$FLATPAK_SEL"
    else
      yad --warning --text="No se pudo instalar Flatpak. Omite Flatpak."
    fi
  fi

  if [[ $had_any -eq 0 ]]; then
    yad --info --text="No hay selección guardada para instalar."
  else
    yad --info --text="Instalación finalizada. Revise $LOG para detalles."
  fi
}

desinstalar_paquetes() {
  local had_any=0

  if [[ -s "$PACMAN_RM_SEL" ]]; then
    had_any=1
    log "Desinstalando paquetes Pacman..."
    while IFS= read -r pkg; do
      [[ -n "$pkg" ]] || continue
      log "pacman -Rns: $pkg"
      sudo pacman -Rns --noconfirm "$pkg" || log "ERROR: No se pudo desinstalar $pkg (pacman)"
    done < "$PACMAN_RM_SEL"
  fi

  if [[ -s "$YAY_RM_SEL" ]]; then
    had_any=1
    if ensure_yay; then
      log "Desinstalando paquetes AUR con yay..."
      while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        log "yay -Rns: $pkg"
        yay -Rns --noconfirm "$pkg" || log "ERROR: No se pudo desinstalar $pkg (yay)"
      done < "$YAY_RM_SEL"
    else
      yad --warning --text="No se encontró 'yay'. Omite AUR."
    fi
  fi

  if [[ -s "$FLATPAK_RM_SEL" ]]; then
    had_any=1
    if ensure_flatpak; then
      log "Desinstalando Flatpak..."
      while IFS= read -r app; do
        [[ -n "$app" ]] || continue
        log "flatpak uninstall: $app"
        flatpak uninstall -y "$app" || log "ERROR: No se pudo desinstalar $app (flatpak)"
      done < "$FLATPAK_RM_SEL"
    else
      yad --warning --text="Flatpak no disponible."
    fi
  fi

  if [[ $had_any -eq 0 ]]; then
    yad --info --text="No hay selección guardada para desinstalar."
  else
    yad --info --text="✅ Desinstalación finalizada. Revise $LOG para detalles."
  fi
}

instalar_menu() {
  while true; do
    local opcion
    opcion=$(
      yad --list --title="Menú de Instalación" --width=520 --height=340 \
          --column="Acción" --column="Descripción" \
          "Recopilar" "Recopilar paquetes instalados (actualiza listas)" \
          "Seleccionar" "Marcar/desmarcar qué paquetes instalar" \
          "Instalar" "Instalar paquetes según selección guardada" \
          "Salir" "Volver al menú principal" \
          --single-click
    )
    case "${opcion:-}" in
      Recopilar*) recopilar_listas ;;
      Seleccionar*)
        selector_paquetes "Seleccionar paquetes Pacman" "$PACMAN_LIST" "$PACMAN_SEL" "pacman" || true
        selector_paquetes "Seleccionar paquetes Yay (AUR)" "$YAY_LIST" "$YAY_SEL" "yay" || true
        selector_paquetes "Seleccionar paquetes Flatpak" "$FLATPAK_LIST" "$FLATPAK_SEL" "flatpak" || true
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
          "Recopilar" "Generar listas de paquetes instalados" \
          "Seleccionar" "Marcar qué paquetes desinstalar" \
          "Desinstalar" "Eliminar los paquetes seleccionados" \
          "Salir" "Volver al menú principal" \
          --single-click
    )
    case "${opcion:-}" in
      Recopilar*)  recopilar_listas ;;
      Seleccionar*)
        selector_paquetes "Pacman: marcar para DESINSTALAR" "$PACMAN_LIST" "$PACMAN_RM_SEL" "pacman" || true
        selector_paquetes "AUR (yay): marcar para DESINSTALAR" "$YAY_LIST" "$YAY_RM_SEL" "yay" || true
        selector_paquetes "Flatpak: marcar para DESINSTALAR" "$FLATPAK_LIST" "$FLATPAK_RM_SEL" "flatpak" || true
        ;;
      Desinstalar*) desinstalar_paquetes ;;
      Salir*|"")   clear; return ;;
    esac
  done
}

main_menu_launcher() {
  while true; do
    local opcion
    opcion=$(
      yad --list --title="Gestor de Paquetes" \
          --width=400 --height=200 --center \
          --column="Acción" --column="Descripción" \
          "Instalar" "Gestionar instalación de paquetes" \
          "Desinstalar" "Gestionar desinstalación de paquetes" \
          "Salir" "Salir del gestor" \
          --single-click
    )
    case "${opcion:-}" in
      Instalar*)   instalar_menu ;;
      Desinstalar*) desinstalar_menu ;;
      Salir*|"")   clear; exit 0 ;;
    esac
  done
}

check_yad
main_menu_launcher
