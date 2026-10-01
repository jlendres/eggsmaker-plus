
# 🥚 Eggsmaker Plus (v1.2.1)

[**Español**](#-español) | [**English**](#-english)

---
## 🇪🇸 Español
Durante 2025 habia creado la aplicacion Eggsmaker que era una aplicacion grafica para ejecutar los comandos indispensables y mas usados de penguins-eggs.
Si bien lucia bien, hacer cambios en funcion del avance del proyecto lo hacia tedioso , entonces busque un segundo camino, eggsmaker-web: fuen un pryecto que arme hacia finales del 2025.
El plan de mantenimiento era mas sencillo para cumplir las funciones que hacia la anterior version.
Pensaba actualizarla para las nuevas versiones de Penguins pero opte por otro camino, no intentar inventar la rueda e ir por lo que realmente sirve.
Aqui nace Eggsmaker-plus que ademas de ejecutar comandos de Penguins-eggs agrega algunas herramientas que habia generado para mi uso personal.
Esto consiste en recopilar las aplicaciones instaladas en un equipo, hacer una seleccion de las mismas e instalarlas en otro equipo con una version fresca recien instalada que la llame pkgmaker. Finalmente la incorpore a Eggsmaker-plus.

Ahora que penguins-eggs esta maduro y mejor que nunca, gracias al gran trabajo de mi amigo Piero Proietti (https://penguins-eggs.net/ ), es el momento de hacer un aporte al proyecto.


### 📖 Descripción
**Eggsmaker Plus** es una suite de administración de sistemas escrita en Bash con interfaz gráfica basada en **YAD**. Diseñada para simplificar la creación de imágenes ISO personalizadas y clones del sistema usando **Penguins Eggs**, incluye además un gestor de paquetes unificado para mantener respaldos de tus aplicaciones instaladas.

El script detecta automáticamente la familia de tu distribución Linux y ajusta los comandos de forma nativa sin requerir configuración manual.

---

### ✨ Características Principales
* **Soporte Multi-Distribución:** Compatible de forma nativa con el ecosistema **Arch Linux** (`pacman` / `yay`) y **Debian / Ubuntu** (`apt`).
* **Generador de ISOs:** Permite crear ISOs estándar personalizadas o clones completos del sistema en ejecución (`--clone`).
* **Ejecución Nativa de Instaladores:** Lanzamiento directo sin captura de terminal para **Calamares** (interfaz Qt) y **Krill** (interfaz `ncurses` TUI).
* **Gestor de Paquetes Unificado:** Recopilación, instalación y desinstalación respaldada en `~/hostname-pak/` para paquetes Nativos, AUR y Flatpak.
* **Soporte Internacional (i18n):** Detección automática de idioma (Español, Italiano e Inglés).

---

### 📸 Capturas de Pantalla / Screenshots

| Menú Principal / Main Menu | Gestor de Paquetes / Package Manager |
| :---: | :---: |
| ![Menú Principal](screenshots/main_menu.png) | ![Gestor de Paquetes](screenshots/package_manager.png) |

| Creación de ISO / ISO Generation | Registro de Proceso / Progress Log |
| :---: | :---: |
| ![Generador ISO](screenshots/iso_builder.png) | ![Progreso](screenshots/progress.png) |

---

### 🚀 Instalación y Uso

1. **Clonar el repositorio:**
   ```bash
   git clone [https://github.com/jlendres/eggsmaker-plus.git](https://github.com/jlendres/eggsmaker-plus.git)
   cd eggsmaker-plus
2.  **Dar permisos de ejecución a los scripts:**
    chmod +x install.sh eggsmaker
3.  Ejecutar el instalador de dependencias: sudo ./install.sh
4.  Iniciar la aplicación: sudo eggsmaker
5.  Ademas encontrara el lanzador de la aplicacion en el menu . Hacer click , ingresar clave sudo para iniciar.

 
   
