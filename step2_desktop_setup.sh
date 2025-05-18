#!/bin/sh
# Step 2: Desktop Environment Setup Script
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

# Vérifier si l'utilisateur est root
if [ "$(id -u)" -ne 0 ]; then
    print_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Charger les informations de détection
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

# Installation des paquets pour l'environnement graphique minimal
print_message "Installation de l'environnement graphique minimal..."
apk add xorg-server xorg-server-common xf86-input-libinput xf86-video-fbdev
apk add xf86-input-mouse xf86-input-keyboard xf86-input-evdev
apk add xorg-apps xauth xinit xrandr
apk add mesa-gl mesa-egl mesa-dri

# Installation de i3wm et composants
print_message "Installation de i3wm et composants..."
apk add i3wm i3lock dmenu
apk add xfce4-terminal rofi feh picom
apk add dunst libnotify
apk add thunar thunar-volman gvfs gvfs-mtp gvfs-smb
apk add xdg-utils xdg-user-dirs

# Installation de polybar (remplace i3status)
print_message "Installation de polybar..."
apk add polybar

# Installation de ly-dm
print_message "Installation de ly-dm..."
apk add ly
rc-update add ly default

# Installation des polices
print_message "Installation des polices..."
apk add font-dejavu ttf-dejavu ttf-liberation
apk add fontconfig
print_success "Environnement graphique minimal installé"

# Installation des paquets audio
print_message "Installation des paquets audio..."
apk add alsa-utils alsa-utils-doc alsa-lib alsaconf
apk add pulseaudio pulseaudio-alsa pulseaudio-utils
apk add pavucontrol
print_success "Paquets audio installés"

# Installation des paquets pour le clavier et bluetooth
print_message "Installation des paquets pour le clavier et bluetooth..."
apk add setxkbmap xkeyboard-config
apk add bluez bluez-openrc bluez-libs
apk add blueman
rc-update add bluetooth default
print_success "Paquets pour le clavier et bluetooth installés"

# Installation des paquets spécifiques au CPU
if [ "$CPU_TYPE" = "intel" ]; then
    print_message "Installation des paquets spécifiques pour Intel..."
    apk add intel-ucode
    apk add mesa mesa-dri-intel intel-media-driver
elif [ "$CPU_TYPE" = "amd" ]; then
    print_message "Installation des paquets spécifiques pour AMD..."
    apk add amd-ucode
    apk add mesa mesa-dri-gallium mesa-vulkan-ati
fi
print_success "Paquets spécifiques au CPU installés"

# Installation des paquets NVIDIA si détecté
if [ "$HAS_NVIDIA" = "true" ]; then
    print_message "Installation des paquets NVIDIA..."
    apk add nvidia-driver nvidia-modules
    print_success "Paquets NVIDIA installés"
fi

# Fonction pour copier les fichiers de configuration d'origine
copy_config_file() {
    local source_paths=("$@")
    local dest_dir="${source_paths[-1]}"
    local file_name="${source_paths[-2]}"
    unset 'source_paths[${#source_paths[@]}-1]'
    unset 'source_paths[${#source_paths[@]}-1]'
    
    # Créer le répertoire de destination s'il n'existe pas
    mkdir -p "$dest_dir"
    
    # Parcourir les chemins source possibles
    for src_path in "${source_paths[@]}"; do
        if [ -f "$src_path" ]; then
            cp "$src_path" "$dest_dir/$file_name"
            print_success "Fichier de configuration copié: $src_path -> $dest_dir/$file_name"
            return 0
        fi
    done
    
    print_warning "Aucun fichier de configuration trouvé pour $file_name"
    return 1
}

# Configuration pour l'utilisateur
if [ -n "$USERNAME" ]; then
    USER_HOME="/home/$USERNAME"
    
    # Ajout de l'utilisateur aux groupes nécessaires
    print_message "Ajout de l'utilisateur $USERNAME aux groupes nécessaires..."
    addgroup "$USERNAME" audio
    addgroup "$USERNAME" video
    addgroup "$USERNAME" input
    
    # Copier les fichiers de configuration i3wm
    print_message "Copie des fichiers de configuration i3wm..."
    copy_config_file "/etc/i3/config" "/usr/share/doc/i3/config" "/usr/share/i3/config" "config" "$USER_HOME/.config/i3"
    
    # Copier les fichiers de configuration polybar
    print_message "Copie des fichiers de configuration polybar..."
    copy_config_file "/etc/polybar/config.ini" "/usr/share/polybar/config.ini" "/usr/share/doc/polybar/config" "config.ini" "$USER_HOME/.config/polybar"
    
    # Créer un script de lancement pour polybar
    mkdir -p "$USER_HOME/.config/polybar"
    cat > "$USER_HOME/.config/polybar/launch.sh" << EOF
#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch polybar
polybar main &

echo "Polybar launched..."
EOF
    chmod +x "$USER_HOME/.config/polybar/launch.sh"
    
    # Modifier la configuration i3 pour utiliser polybar au lieu de i3status
    if [ -f "$USER_HOME/.config/i3/config" ]; then
        # Commenter la ligne i3status
        sed -i 's/^bar {/# bar {/g' "$USER_HOME/.config/i3/config"
        sed -i 's/^    status_bar/    # status_bar/g' "$USER_HOME/.config/i3/config"
        sed -i 's/^}/# }/g' "$USER_HOME/.config/i3/config"
        
        # Ajouter le lancement de polybar
        echo "" >> "$USER_HOME/.config/i3/config"
        echo "# Lancer polybar au démarrage" >> "$USER_HOME/.config/i3/config"
        echo "exec --no-startup-id $USER_HOME/.config/polybar/launch.sh" >> "$USER_HOME/.config/i3/config"
    fi
    
    # Copier les fichiers de configuration rofi
    print_message "Copie des fichiers de configuration rofi..."
    copy_config_file "/etc/rofi/config.rasi" "/usr/share/rofi/config.rasi" "config.rasi" "$USER_HOME/.config/rofi"
    
    # Copier les fichiers de configuration xfce4-terminal
    print_message "Copie des fichiers de configuration xfce4-terminal..."
    copy_config_file "/etc/xfce4/terminal/terminalrc" "/usr/share/xfce4/terminal/terminalrc" "terminalrc" "$USER_HOME/.config/xfce4/terminal"
    
    # Copier les fichiers de configuration picom
    print_message "Copie des fichiers de configuration picom..."
    copy_config_file "/etc/xdg/picom.conf" "/etc/picom.conf" "/usr/share/doc/picom/picom.conf.example" "picom.conf" "$USER_HOME/.config/picom"
    
    # Changer le propriétaire des fichiers de configuration
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config"
    print_success "Configuration pour l'utilisateur $USERNAME terminée"
fi

# Finalisation
print_message "Installation de l'environnement de bureau terminée !"
print_message "Redémarrez le système puis exécutez le script step3_virtualization_setup.sh"

# Demande de redémarrage
print_message "Voulez-vous redémarrer maintenant ? (o/n)"
read -r REBOOT
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Redémarrage du système..."
    reboot
fi
