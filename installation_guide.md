# Guide d'installation et de configuration d'Alpine Linux

## 1. Installation de base d'Alpine Linux

### 1.1 Préparation initiale
```
# Se connecter en tant que root
login: root

# Configurer le clavier (exemple pour un clavier français)
setup-keymap fr fr

# Configurer le nom d'hôte
setup-hostname alpine-gaming

# Configurer les interfaces réseau
setup-interfaces
# Suivre les instructions pour configurer eth0 ou wlan0
# Généralement, dhcp pour une configuration automatique

# Démarrer le service réseau
rc-service networking start
rc-update add networking boot

# Mettre à jour les dépôts
setup-apkrepos
# Choisir un miroir proche de votre localisation

# Mettre à jour le système
apk update
apk upgrade
```

### 1.2 Installation du système de base
```
# Installer les paquets système essentiels
apk add alpine-base alpine-sdk build-base linux-firmware doas sudo
apk add eudev udev-init-scripts udev-init-scripts-openrc
apk add e2fsprogs e2fsprogs-extra dosfstools ntfs-3g
apk add bash bash-completion coreutils util-linux pciutils usbutils
apk add curl wget git nano vim
apk add htop neofetch lsblk
apk add openssl openssh openssh-server
apk add chrony tzdata

# Configurer le fuseau horaire
setup-timezone

# Configurer le disque et installer le système
setup-disk
# Suivre les instructions pour partitionner et formater les disques
# Choisir sys pour une installation complète sur disque

# Créer un utilisateur
adduser votre_nom_utilisateur
# Suivre les instructions pour définir le mot de passe

# Ajouter l'utilisateur au groupe wheel pour les privilèges sudo
addgroup votre_nom_utilisateur wheel

# Configurer sudo
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Configurer doas (alternative à sudo)
echo "permit persist :wheel" > /etc/doas.d/doas.conf
chmod 640 /etc/doas.d/doas.conf
```

## 2. Configuration du réseau

### 2.1 Installation des paquets réseau
```
# Installer NetworkManager
apk add networkmanager networkmanager-cli networkmanager-tui networkmanager-wifi
apk add wpa_supplicant wireless-tools iw
apk add dhclient

# Désactiver les services réseau par défaut et activer NetworkManager
rc-update del networking boot
rc-update del wpa_supplicant boot
rc-update add networkmanager default

# Démarrer NetworkManager
rc-service networkmanager start
```

### 2.2 Configuration du réseau sans fil
```
# Configurer une connexion Wi-Fi
nmtui
# Ou utiliser la ligne de commande
nmcli device wifi list
nmcli device wifi connect "SSID" password "mot_de_passe"
```

## 3. Installation de l'environnement graphique

### 3.1 Installation de Xorg et des pilotes graphiques
```
# Installer Xorg et les pilotes de base
apk add xorg-server xorg-server-common xf86-input-libinput xf86-video-fbdev
apk add xf86-input-mouse xf86-input-keyboard xf86-input-evdev
apk add xorg-apps xauth xinit xrandr
apk add mesa-gl mesa-egl mesa-dri

# Installer les pilotes spécifiques selon votre matériel

## Pour Intel
apk add intel-ucode
apk add mesa mesa-dri-intel intel-media-driver

## Pour AMD
apk add amd-ucode
apk add mesa mesa-dri-gallium mesa-vulkan-ati

## Pour NVIDIA
# Ajouter le dépôt community
echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
apk update
apk add nvidia-driver nvidia-modules
```

### 3.2 Installation et configuration de i3wm
```
# Installer i3wm et les composants associés
apk add i3wm i3status i3lock dmenu
apk add xfce4-terminal rofi feh picom
apk add dunst libnotify
apk add polybar
apk add thunar thunar-volman gvfs gvfs-mtp gvfs-smb
apk add xdg-utils xdg-user-dirs

# Créer les répertoires de configuration
mkdir -p ~/.config/i3
mkdir -p ~/.config/i3status
mkdir -p ~/.config/rofi
mkdir -p ~/.config/picom

# Copier les fichiers de configuration par défaut
cp /usr/share/doc/i3/config ~/.config/i3/
cp /usr/share/doc/i3status/config ~/.config/i3status/
```

### 3.3 Installation et configuration de ly-dm
```
# Ajouter le dépôt testing
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update

# Installer ly
apk add ly

# Activer ly au démarrage
rc-update add ly default
```

### 3.4 Configuration des polices et thèmes
```
# Installer les polices
apk add font-dejavu font-noto font-noto-emoji
apk add ttf-dejavu ttf-liberation ttf-ubuntu-font-family
apk add fontconfig

# Installer les thèmes
apk add adwaita-gtk2-theme adwaita-icon-theme
apk add arc-theme arc-icon-theme
apk add papirus-icon-theme
apk add gtk+2.0 gtk+3.0 gtk-engines gtk-engine-murrine

# Créer le fichier de configuration des polices
mkdir -p ~/.config/fontconfig
cat > ~/.config/fontconfig/fonts.conf << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>
EOF
```

## 4. Configuration du son, du clavier et du bluetooth

### 4.1 Configuration du son
```
# Installer les paquets audio
apk add alsa-utils alsa-utils-doc alsa-lib alsaconf
apk add pulseaudio pulseaudio-alsa pulseaudio-utils
apk add pavucontrol pulsemixer
apk add pipewire pipewire-pulse pipewire-alsa
apk add wireplumber

# Ajouter l'utilisateur au groupe audio
addgroup votre_nom_utilisateur audio

# Démarrer et activer PulseAudio au démarrage de la session
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/pulseaudio.service << EOF
[Unit]
Description=PulseAudio Sound System
Documentation=man:pulseaudio(1)
After=sound.target

[Service]
ExecStart=/usr/bin/pulseaudio --daemonize=no
Restart=on-failure

[Install]
WantedBy=default.target
EOF

# Configurer PulseAudio pour démarrer automatiquement
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/pulseaudio.desktop << EOF
[Desktop Entry]
Type=Application
Name=PulseAudio Sound System
Comment=Start the PulseAudio Sound System
Exec=pulseaudio --start
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
```

### 4.2 Configuration du clavier
```
# Installer les paquets pour le clavier
apk add setxkbmap xkeyboard-config
apk add numlockx
apk add xbindkeys

# Créer un script pour configurer le clavier au démarrage
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/keyboard-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=Keyboard Setup
Comment=Configure keyboard layout and options
Exec=sh -c "setxkbmap fr; numlockx on"
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
```

### 4.3 Configuration du bluetooth
```
# Installer les paquets bluetooth
apk add bluez bluez-openrc bluez-libs bluez-deprecated
apk add bluez-alsa bluez-firmware
apk add blueman

# Ajouter l'utilisateur au groupe bluetooth
addgroup votre_nom_utilisateur bluetooth

# Activer et démarrer le service bluetooth
rc-update add bluetooth default
rc-service bluetooth start

# Configurer blueman pour démarrer automatiquement
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/blueman.desktop << EOF
[Desktop Entry]
Type=Application
Name=Blueman Applet
Comment=Bluetooth Manager applet
Exec=blueman-applet
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
```

## 5. Configuration pour le gaming

### 5.1 Installation des paquets pour le gaming
```
# Installer Vulkan
apk add vulkan-loader vulkan-tools vulkan-headers vulkan-validation-layers

# Installer OpenGL
apk add mesa-gl mesa-egl mesa-dev

# Installer les bibliothèques de jeu
apk add sdl2 sdl2-dev sdl2_image sdl2_mixer sdl2_ttf
apk add libva libva-intel-driver libva-utils
apk add vdpau-va-driver

# Installer la compatibilité 32-bit
apk add gcompat
```

### 5.2 Configuration de la gestion d'énergie
```
# Installer les paquets de gestion d'énergie
apk add acpi acpid acpid-openrc
apk add cpufrequtils powertop
apk add xfce4-power-manager

# Activer et démarrer le service acpid
rc-update add acpid default
rc-service acpid start

# Configurer xfce4-power-manager pour démarrer automatiquement
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/xfce4-power-manager.desktop << EOF
[Desktop Entry]
Type=Application
Name=Power Manager
Comment=Power management for the Xfce desktop
Exec=xfce4-power-manager
Terminal=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
```

## 6. Configuration de KVM/QEMU pour la virtualisation

### 6.1 Installation des paquets de virtualisation
```
# Installer les paquets de base pour KVM/QEMU
apk add qemu qemu-img qemu-system-x86_64 qemu-modules
apk add libvirt libvirt-daemon libvirt-client
apk add virt-manager virt-viewer
apk add dbus dbus-openrc polkit
apk add bridge-utils
apk add ovmf

# Installer les paquets spécifiques selon votre CPU
## Pour Intel
apk add qemu-system-i386 qemu-system-x86_64
apk add intel-ucode

## Pour AMD
apk add qemu-system-i386 qemu-system-x86_64
apk add amd-ucode

# Installer les paquets pour le réseau virtuel
apk add iptables ebtables dnsmasq
apk add bridge-utils

# Installer les paquets pour la sécurité
apk add apparmor-profiles-extra
apk add libvirt-apparmor

# Installer les paquets pour la gestion des images disque
apk add qemu-img
apk add libguestfs libguestfs-tools
```

### 6.2 Configuration des services de virtualisation
```
# Activer et démarrer les services nécessaires
rc-update add libvirtd default
rc-update add dbus default
rc-service dbus start
rc-service libvirtd start

# Ajouter l'utilisateur aux groupes nécessaires
addgroup votre_nom_utilisateur libvirt
addgroup votre_nom_utilisateur kvm
```

### 6.3 Création des images disque
```
# Créer le répertoire pour les images si nécessaire
sudo mkdir -p /var/lib/libvirt/images/

# Créer une image Windows 11
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 100G

# Créer une image Pop!_OS
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/popos.qcow2 50G
```

### 6.4 Configuration du réseau pour les VM
```
# Créer un bridge réseau pour les VM
cat > /tmp/bridge.xml << EOF
<network>
  <name>bridge-network</name>
  <forward mode="nat"/>
  <bridge name="virbr0" stp="on" delay="0"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
    </dhcp>
  </ip>
</network>
EOF

# Définir et démarrer le réseau
sudo virsh net-define /tmp/bridge.xml
sudo virsh net-autostart bridge-network
sudo virsh net-start bridge-network
```

## 7. Configuration de la sécurité

### 7.1 Configuration du pare-feu
```
# Installer et configurer le pare-feu
apk add iptables ip6tables iptables-openrc
rc-update add iptables default
rc-update add ip6tables default

# Configurer les règles de base du pare-feu
cat > /etc/iptables/rules-save << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -j ACCEPT
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -p tcp --dport 22 -j ACCEPT
-A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A FORWARD -i virbr0 -o eth0 -j ACCEPT
COMMIT
EOF

# Charger les règles
iptables-restore < /etc/iptables/rules-save
```

### 7.2 Configuration de fail2ban
```
# Installer et configurer fail2ban
apk add fail2ban fail2ban-openrc
rc-update add fail2ban default

# Configurer fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
EOF

# Démarrer fail2ban
rc-service fail2ban start
```

### 7.3 Configuration d'AppArmor
```
# Installer et configurer AppArmor
apk add apparmor apparmor-utils apparmor-profiles
rc-update add apparmor default

# Activer AppArmor au démarrage
cat >> /etc/update-extlinux.conf << EOF
default_kernel_opts="... apparmor=1 security=apparmor"
EOF
update-extlinux

# Démarrer AppArmor
rc-service apparmor start
```

## 8. Configuration d'i3wm

### 8.1 Configuration de base d'i3wm
```
# Créer le fichier de configuration i3
mkdir -p ~/.config/i3
cat > ~/.config/i3/config << EOF
# i3 config file (v4)

# Définir la touche mod (Mod1=Alt, Mod4=Super/Windows)
set $mod Mod4

# Police pour les titres de fenêtres
font pango:DejaVu Sans Mono 10

# Utiliser Mouse+$mod pour déplacer les fenêtres flottantes
floating_modifier $mod

# Terminal par défaut
bindsym $mod+Return exec xfce4-terminal

# Tuer la fenêtre focalisée
bindsym $mod+Shift+q kill

# Lanceur d'applications (rofi)
bindsym $mod+d exec rofi -show drun

# Changer le focus
bindsym $mod+j focus left
bindsym $mod+k focus down
bindsym $mod+l focus up
bindsym $mod+semicolon focus right

# Alternativement, vous pouvez utiliser les touches fléchées
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Déplacer la fenêtre focalisée
bindsym $mod+Shift+j move left
bindsym $mod+Shift+k move down
bindsym $mod+Shift+l move up
bindsym $mod+Shift+semicolon move right

# Alternativement, vous pouvez utiliser les touches fléchées
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right

# Diviser horizontalement
bindsym $mod+h split h

# Diviser verticalement
bindsym $mod+v split v

# Entrer en mode plein écran
bindsym $mod+f fullscreen toggle

# Changer la disposition des conteneurs
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Basculer entre fenêtre flottante et tiling
bindsym $mod+Shift+space floating toggle

# Changer le focus entre fenêtres tiling et flottantes
bindsym $mod+space focus mode_toggle

# Focaliser le conteneur parent
bindsym $mod+a focus parent

# Définir les noms des espaces de travail
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"

# Basculer vers l'espace de travail
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10

# Déplacer la fenêtre focalisée vers l'espace de travail
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10

# Recharger le fichier de configuration
bindsym $mod+Shift+c reload

# Redémarrer i3 sur place
bindsym $mod+Shift+r restart

# Quitter i3
bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'Voulez-vous vraiment quitter i3?' -B 'Oui, quitter i3' 'i3-msg exit'"

# Redimensionner les fenêtres
mode "resize" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym semicolon resize grow width 10 px or 10 ppt

        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt

        bindsym Return mode "default"
        bindsym Escape mode "default"
        bindsym $mod+r mode "default"
}

bindsym $mod+r mode "resize"

# Barre d'état (i3status)
bar {
        status_command i3status
        position top
}

# Programmes au démarrage
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
exec --no-startup-id xfce4-power-manager
exec --no-startup-id picom -b
exec --no-startup-id feh --bg-fill /usr/share/backgrounds/default.jpg

# Verrouillage d'écran
bindsym $mod+l exec i3lock -c 000000

# Contrôle du volume
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle

# Contrôle de la luminosité
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-

# Capture d'écran
bindsym Print exec --no-startup-id scrot 'screenshot_%Y%m%d_%H%M%S.png' -e 'mv $f ~/Pictures/'
EOF
```

### 8.2 Configuration de i3status
```
# Créer le fichier de configuration i3status
mkdir -p ~/.config/i3status
cat > ~/.config/i3status/config << EOF
general {
        colors = true
        interval = 5
}

order += "wireless _first_"
order += "ethernet _first_"
order += "battery all"
order += "disk /"
order += "load"
order += "memory"
order += "tztime local"

wireless _first_ {
        format_up = "W: (%quality at %essid) %ip"
        format_down = "W: down"
}

ethernet _first_ {
        format_up = "E: %ip (%speed)"
        format_down = "E: down"
}

battery all {
        format = "%status %percentage %remaining"
}

disk "/" {
        format = "%avail"
}

load {
        format = "%1min"
}

memory {
        format = "%used | %available"
        threshold_degraded = "1G"
        format_degraded = "MEMORY < %available"
}

tztime local {
        format = "%Y-%m-%d %H:%M:%S"
}
EOF
```

### 8.3 Configuration de rofi
```
# Créer le fichier de configuration rofi
mkdir -p ~/.config/rofi
cat > ~/.config/rofi/config.rasi << EOF
configuration {
    modi: "window,run,ssh,drun";
    font: "DejaVu Sans Mono 12";
    show-icons: true;
    icon-theme: "Papirus";
    terminal: "xfce4-terminal";
    drun-display-format: "{icon} {name}";
    location: 0;
    disable-history: false;
    hide-scrollbar: true;
    display-drun: "Applications";
    display-run: "Run";
    display-window: "Windows";
    display-ssh: "SSH";
    sidebar-mode: true;
}

@theme "Arc-Dark"
EOF
```

### 8.4 Configuration de picom
```
# Créer le fichier de configuration picom
mkdir -p ~/.config/picom
cat > ~/.config/picom/picom.conf << EOF
backend = "glx";
vsync = true;

shadow = true;
shadow-radius = 7;
shadow-offset-x = -7;
shadow-offset-y = -7;
shadow-opacity = 0.7;

fading = true;
fade-delta = 4;
fade-in-step = 0.03;
fade-out-step = 0.03;

inactive-opacity = 0.9;
active-opacity = 1.0;
frame-opacity = 0.7;

blur-background = true;
blur-method = "dual_kawase";
blur-strength = 5;

mark-wmwin-focused = true;
mark-ovredir-focused = true;
detect-rounded-corners = true;
detect-client-opacity = true;
refresh-rate = 0;
detect-transient = true;
detect-client-leader = true;
use-damage = true;
log-level = "warn";
EOF
```

## 9. Finalisation de l'installation

### 9.1 Vérification des services
```
# Vérifier que tous les services nécessaires sont activés au démarrage
rc-update show

# Vérifier l'état des services
rc-status
```

### 9.2 Redémarrage du système
```
# Redémarrer le système pour appliquer toutes les configurations
reboot
```

### 9.3 Première connexion graphique
```
# Après le redémarrage, ly-dm devrait démarrer automatiquement
# Connectez-vous avec votre nom d'utilisateur et mot de passe
# i3wm devrait démarrer et vous présenter son écran d'accueil
```
