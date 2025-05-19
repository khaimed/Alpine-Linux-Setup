#!/bin/sh
# Step 2: Desktop Environment Setup Script (Fixed Version)
# This script installs and configures i3wm, polybar, and other desktop components
# Run this script after step1_base_setup.sh and a system reboot

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Activer le mode debug pour voir les commandes exécutées
set -x

# Vérifier si l'utilisateur est root
if [ "$(id -u)" -ne 0 ]; then
    print_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Charger les informations de détection avec vérification
if [ -f /etc/alpine_vm_setup/hardware_info ]; then
    . /etc/alpine_vm_setup/hardware_info
    print_message "Informations de détection chargées"
    print_message "CPU détecté: $CPU_TYPE"
    if [ "$HAS_NVIDIA" = "true" ]; then
        print_message "Carte graphique NVIDIA détectée"
    fi
    if [ -n "$USERNAME" ]; then
        print_message "Utilisateur: $USERNAME"
    fi
else
    print_error "Informations de détection non trouvées. Exécutez d'abord step1_base_setup.sh"
    exit 1
fi

# Fonction pour installer des paquets avec timeout
install_packages() {
    local packages="$1"
    local description="$2"
    local timeout=300  # 5 minutes timeout
    
    print_message "Installation de $description..."
    
    # Utiliser timeout pour éviter les blocages
    if timeout $timeout apk add $packages; then
        print_success "$description installés"
        return 0
    else
        print_error "Timeout lors de l'installation de $description"
        print_warning "Continuez manuellement avec: apk add $packages"
        return 1
    fi
}

# Installation des paquets pour l'environnement graphique minimal
install_packages "xorg-server xorg-server-common xf86-input-libinput xf86-video-fbdev xf86-input-mouse xf86-input-keyboard xf86-input-evdev xorg-apps xauth xinit xrandr mesa-gl mesa-egl mesa-dri" "l'environnement graphique minimal"

# Installation de i3wm et composants
install_packages "i3wm i3lock dmenu" "i3wm"
install_packages "xfce4-terminal rofi feh picom" "les composants de bureau"
install_packages "dunst libnotify" "les notifications"
install_packages "thunar thunar-volman gvfs gvfs-mtp gvfs-smb" "le gestionnaire de fichiers"
install_packages "xdg-utils xdg-user-dirs" "les utilitaires XDG"

# Installation de polybar (remplace i3status)
install_packages "polybar" "polybar"

# Installation de ly-dm
install_packages "ly" "ly-dm"
rc-update add ly default || print_warning "Impossible d'ajouter ly au démarrage"

# Installation des polices
install_packages "font-dejavu ttf-dejavu ttf-liberation fontconfig" "les polices"

# Installation des paquets audio
install_packages "alsa-utils alsa-utils-doc alsa-lib alsaconf" "les utilitaires audio"
install_packages "pulseaudio pulseaudio-alsa pulseaudio-utils pavucontrol" "pulseaudio"

# Installation des paquets pour le clavier et bluetooth
install_packages "setxkbmap xkeyboard-config" "la configuration du clavier"
install_packages "bluez bluez-openrc bluez-libs blueman" "bluetooth"
rc-update add bluetooth default || print_warning "Impossible d'ajouter bluetooth au démarrage"

# Installation des paquets spécifiques au CPU
if [ "$CPU_TYPE" = "intel" ]; then
    print_message "Installation des paquets spécifiques pour Intel..."
    install_packages "intel-ucode mesa mesa-dri-intel intel-media-driver" "les paquets Intel"
elif [ "$CPU_TYPE" = "amd" ]; then
    print_message "Installation des paquets spécifiques pour AMD..."
    install_packages "amd-ucode mesa mesa-dri-gallium mesa-vulkan-ati" "les paquets AMD"
else
    print_message "Installation des paquets génériques pour le GPU..."
    install_packages "mesa mesa-dri" "les paquets GPU génériques"
fi

# Installation des paquets NVIDIA si détecté
if [ "$HAS_NVIDIA" = "true" ]; then
    install_packages "nvidia-driver nvidia-modules" "les paquets NVIDIA"
fi

# Fonction pour copier les fichiers de configuration d'origine avec timeout
copy_config_file() {
    # convertir les arguments en tableau source_paths manuellement
    set -- "$@"
    count=$#
    dest_dir="${!count}"; count=$((count - 1))
    file_name="${!count}"; count=$((count - 1))

    # Extraire les chemins sources
    source_paths=""
    for i in $(seq 1 $count); do
        eval "source_paths_$i=\${$i}"
    done

    # Créer le répertoire de destination
    mkdir -p "$dest_dir"

    found=0
    for i in $(seq 1 $count); do
        eval "src_path=\$source_paths_$i"
        if [ -f "$src_path" ]; then
            cp "$src_path" "$dest_dir/$file_name"
            print_success "Fichier de configuration copié: $src_path -> $dest_dir/$file_name"
            found=1
            break
        fi
    done

    if [ "$found" -eq 0 ]; then
        print_warning "Aucun fichier de configuration trouvé pour $file_name, création d’un fichier vide"
        touch "$dest_dir/$file_name"
    fi

    return 0
}

# Configuration pour l'utilisateur
if [ -n "$USERNAME" ]; then
    USER_HOME="/home/$USERNAME"
    
    # Ajout de l'utilisateur aux groupes nécessaires
    print_message "Ajout de l'utilisateur $USERNAME aux groupes nécessaires..."
    addgroup "$USERNAME" audio || print_warning "Impossible d'ajouter l'utilisateur au groupe audio"
    addgroup "$USERNAME" video || print_warning "Impossible d'ajouter l'utilisateur au groupe video"
    addgroup "$USERNAME" input || print_warning "Impossible d'ajouter l'utilisateur au groupe input"
    
    # Créer les répertoires de configuration
    mkdir -p "$USER_HOME/.config/i3"
    mkdir -p "$USER_HOME/.config/polybar"
    mkdir -p "$USER_HOME/.config/rofi"
    mkdir -p "$USER_HOME/.config/xfce4/terminal"
    mkdir -p "$USER_HOME/.config/picom"
    
    # Copier les fichiers de configuration i3wm
    print_message "Copie des fichiers de configuration i3wm..."
    copy_config_file "/etc/i3/config" "/usr/share/doc/i3/config" "/usr/share/i3/config" "config" "$USER_HOME/.config/i3"
    
    # Créer une configuration polybar minimale si aucune n'est trouvée
    print_message "Configuration de polybar..."
    if ! copy_config_file "/etc/polybar/config.ini" "/usr/share/polybar/config.ini" "/usr/share/doc/polybar/config" "config.ini" "$USER_HOME/.config/polybar"; then
        cat > "$USER_HOME/.config/polybar/config.ini" << EOF
[colors]
background = #282A2E
foreground = #C5C8C6
primary = #F0C674

[bar/main]
width = 100%
height = 27
radius = 0
fixed-center = true
background = \${colors.background}
foreground = \${colors.foreground}
padding-left = 0
padding-right = 2
module-margin-left = 1
module-margin-right = 1
font-0 = "DejaVu Sans:size=10;2"
modules-left = i3
modules-center = date
modules-right = cpu memory
tray-position = right
tray-padding = 2

[module/i3]
type = internal/i3
pin-workspaces = true
strip-wsnumbers = true
index-sort = true
enable-click = true
enable-scroll = false
wrapping-scroll = false
reverse-scroll = false
fuzzy-match = true

[module/cpu]
type = internal/cpu
interval = 2
format-prefix = "CPU "
format-prefix-foreground = \${colors.primary}
label = %percentage:2%%

[module/memory]
type = internal/memory
interval = 2
format-prefix = "RAM "
format-prefix-foreground = \${colors.primary}
label = %percentage_used:2%%

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d%
time = %H:%M:%S
label = %date% %time%
EOF
        print_success "Configuration polybar minimale créée"
    fi
    
    # Créer un script de lancement pour polybar
    cat > "$USER_HOME/.config/polybar/launch.sh" << EOF
#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u \$UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar main &

echo "Polybar launched..."
EOF
    chmod +x "$USER_HOME/.config/polybar/launch.sh"
    
    # Modifier la configuration i3 pour utiliser polybar au lieu de i3status
    if [ -f "$USER_HOME/.config/i3/config" ]; then
        # Commenter la ligne i3status
        sed -i 's/^bar {/# bar {/g' "$USER_HOME/.config/i3/config" || print_warning "Impossible de modifier la configuration i3 (bar)"
        sed -i 's/^    status_bar/    # status_bar/g' "$USER_HOME/.config/i3/config" || print_warning "Impossible de modifier la configuration i3 (status_bar)"
        sed -i 's/^}/# }/g' "$USER_HOME/.config/i3/config" || print_warning "Impossible de modifier la configuration i3 (})"
        
        # Ajouter le lancement de polybar
        echo "" >> "$USER_HOME/.config/i3/config"
        echo "# Lancer polybar au démarrage" >> "$USER_HOME/.config/i3/config"
        echo "exec --no-startup-id $USER_HOME/.config/polybar/launch.sh" >> "$USER_HOME/.config/i3/config"
    else
        # Créer une configuration i3 minimale si aucune n'est trouvée
        cat > "$USER_HOME/.config/i3/config" << EOF
# Configuration i3 minimale
set \$mod Mod4
font pango:DejaVu Sans 10

# Utiliser Mouse+\$mod pour déplacer les fenêtres flottantes
floating_modifier \$mod

# Terminal
bindsym \$mod+Return exec xfce4-terminal

# Tuer la fenêtre focalisée
bindsym \$mod+Shift+q kill

# Lanceur d'applications
bindsym \$mod+d exec rofi -show drun

# Changer le focus
bindsym \$mod+j focus left
bindsym \$mod+k focus down
bindsym \$mod+l focus up
bindsym \$mod+semicolon focus right

# Déplacer la fenêtre focalisée
bindsym \$mod+Shift+j move left
bindsym \$mod+Shift+k move down
bindsym \$mod+Shift+l move up
bindsym \$mod+Shift+semicolon move right

# Orientation de séparation
bindsym \$mod+h split h
bindsym \$mod+v split v

# Mode plein écran
bindsym \$mod+f fullscreen toggle

# Changer le mode de conteneur
bindsym \$mod+s layout stacking
bindsym \$mod+w layout tabbed
bindsym \$mod+e layout toggle split

# Basculer entre fenêtre flottante/tiling
bindsym \$mod+Shift+space floating toggle

# Espaces de travail
set \$ws1 "1"
set \$ws2 "2"
set \$ws3 "3"
set \$ws4 "4"
set \$ws5 "5"
set \$ws6 "6"
set \$ws7 "7"
set \$ws8 "8"
set \$ws9 "9"
set \$ws10 "10"

# Changer d'espace de travail
bindsym \$mod+1 workspace number \$ws1
bindsym \$mod+2 workspace number \$ws2
bindsym \$mod+3 workspace number \$ws3
bindsym \$mod+4 workspace number \$ws4
bindsym \$mod+5 workspace number \$ws5
bindsym \$mod+6 workspace number \$ws6
bindsym \$mod+7 workspace number \$ws7
bindsym \$mod+8 workspace number \$ws8
bindsym \$mod+9 workspace number \$ws9
bindsym \$mod+0 workspace number \$ws10

# Déplacer une fenêtre vers un espace de travail
bindsym \$mod+Shift+1 move container to workspace number \$ws1
bindsym \$mod+Shift+2 move container to workspace number \$ws2
bindsym \$mod+Shift+3 move container to workspace number \$ws3
bindsym \$mod+Shift+4 move container to workspace number \$ws4
bindsym \$mod+Shift+5 move container to workspace number \$ws5
bindsym \$mod+Shift+6 move container to workspace number \$ws6
bindsym \$mod+Shift+7 move container to workspace number \$ws7
bindsym \$mod+Shift+8 move container to workspace number \$ws8
bindsym \$mod+Shift+9 move container to workspace number \$ws9
bindsym \$mod+Shift+0 move container to workspace number \$ws10

# Recharger la configuration
bindsym \$mod+Shift+c reload
bindsym \$mod+Shift+r restart
bindsym \$mod+Shift+e exec "i3-nagbar -t warning -m 'Voulez-vous quitter i3?' -B 'Oui' 'i3-msg exit'"

# Redimensionner les fenêtres
mode "resize" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym \$mod+r mode "default"
}
bindsym \$mod+r mode "resize"

# Lancer polybar au démarrage
exec --no-startup-id $USER_HOME/.config/polybar/launch.sh

# Lancer picom
exec --no-startup-id picom -b

# Fond d'écran
exec --no-startup-id feh --bg-fill /usr/share/backgrounds/default.png
EOF
        print_success "Configuration i3 minimale créée"
    fi
    
    # Copier ou créer les fichiers de configuration rofi
    print_message "Configuration de rofi..."
    if ! copy_config_file "/etc/rofi/config.rasi" "/usr/share/rofi/config.rasi" "config.rasi" "$USER_HOME/.config/rofi"; then
        cat > "$USER_HOME/.config/rofi/config.rasi" << EOF
configuration {
    modi: "window,run,ssh,drun";
    font: "DejaVu Sans 12";
    show-icons: true;
    terminal: "xfce4-terminal";
    drun-display-format: "{name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "Applications";
    display-run: "Commandes";
    display-window: "Fenêtres";
    display-ssh: "SSH";
    sidebar-mode: true;
}

* {
    background-color: #282a36;
    border-color: #bd93f9;
    text-color: #f8f8f2;
    spacing: 0;
    width: 512px;
}

inputbar {
    border: 0 0 1px 0;
    children: [prompt,entry];
}

prompt {
    padding: 16px;
    border: 0 1px 0 0;
}

entry {
    padding: 16px;
}

listview {
    cycle: false;
    margin: 0 0 -1px 0;
    scrollbar: false;
}

element {
    border: 0 0 1px 0;
    padding: 16px;
}

element selected {
    background-color: #44475a;
}
EOF
        print_success "Configuration rofi minimale créée"
    fi
    
    # Copier ou créer les fichiers de configuration xfce4-terminal
    print_message "Configuration de xfce4-terminal..."
    if ! copy_config_file "/etc/xfce4/terminal/terminalrc" "/usr/share/xfce4/terminal/terminalrc" "terminalrc" "$USER_HOME/.config/xfce4/terminal"; then
        cat > "$USER_HOME/.config/xfce4/terminal/terminalrc" << EOF
[Configuration]
FontName=DejaVu Sans Mono 12
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBellUrgent=FALSE
MiscBordersDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=80x24
MiscInheritGeometry=FALSE
MiscMenubarDefault=TRUE
MiscMouseAutohide=FALSE
MiscMouseWheelZoom=TRUE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscMiddleClickOpensUri=FALSE
MiscCopyOnSelect=FALSE
MiscShowRelaunchDialog=TRUE
MiscRewrapOnResize=TRUE
MiscUseShiftArrowsToScroll=FALSE
MiscSlimTabs=FALSE
MiscNewTabAdjacent=FALSE
ColorForeground=#dcdcdc
ColorBackground=#2c2c2c
ColorCursor=#dcdcdc
ColorPalette=#3f3f3f;#705050;#60b48a;#dfaf8f;#9ab8d7;#dc8cc3;#8cd0d3;#dcdcdc;#709080;#dca3a3;#72d5a3;#f0dfaf;#94bff3;#ec93d3;#93e0e3;#ffffff
EOF
        print_success "Configuration xfce4-terminal minimale créée"
    fi
    
    # Copier ou créer les fichiers de configuration picom
    print_message "Configuration de picom..."
    if ! copy_config_file "/etc/xdg/picom.conf" "/etc/picom.conf" "/usr/share/doc/picom/picom.conf.example" "picom.conf" "$USER_HOME/.config/picom"; then
        cat > "$USER_HOME/.config/picom/picom.conf" << EOF
# Ombres
shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.7;

# Transparence
inactive-opacity = 0.9;
active-opacity = 1.0;
frame-opacity = 0.9;
inactive-opacity-override = false;

# Flou
blur-background = true;
blur-method = "dual_kawase";
blur-strength = 5;

# Coins arrondis
corner-radius = 10;
rounded-corners-exclude = [
  "class_g = 'Polybar'",
  "class_g = 'i3bar'"
];

# Animations
transition-length = 300;
transition-pow-x = 0.1;
transition-pow-y = 0.1;
transition-pow-w = 0.1;
transition-pow-h = 0.1;
size-transition = true;

# Général
backend = "glx";
vsync = true;
mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
use-damage = true;
log-level = "warn";
EOF
        print_success "Configuration picom minimale créée"
    fi
    
    # Changer le propriétaire des fichiers de configuration
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config" || print_warning "Impossible de changer le propriétaire des fichiers de configuration"
    print_success "Configuration pour l'utilisateur $USERNAME terminée"
fi

# Finalisation
print_message "Installation de l'environnement de bureau terminée !"
print_message "Redémarrez le système puis exécutez le script step3_virtualization_setup.sh"

# Demande de redémarrage avec timeout
print_message "Voulez-vous redémarrer maintenant ? (o/n) - Répondez dans les 30 secondes"
read -t 30 -r REBOOT || REBOOT="n"
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Redémarrage du système..."
    reboot
fi

# Désactiver le mode debug
set +x

print_message "Script terminé. Redémarrez manuellement avec la commande 'reboot'"
