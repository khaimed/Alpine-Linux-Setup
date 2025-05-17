# Paquets pour i3wm, ly-dm, son, clavier et bluetooth

## Environnement graphique de base
```
apk add xorg-server xorg-server-common xf86-input-libinput xf86-video-fbdev
apk add xf86-input-mouse xf86-input-keyboard xf86-input-evdev
apk add xorg-apps xauth xinit xrandr
apk add mesa-gl mesa-egl mesa-dri
```

## i3wm et composants
```
apk add i3wm i3status i3lock dmenu
apk add xfce4-terminal rofi feh picom
apk add dunst libnotify
apk add polybar
apk add thunar thunar-volman gvfs gvfs-mtp gvfs-smb
apk add xdg-utils xdg-user-dirs
```

## Gestionnaire de connexion ly-dm
```
# Ajouter le dépôt testing
echo "https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories
apk update

# Installer ly
apk add ly
rc-update add ly default
```

## Paquets pour le son
```
apk add alsa-utils alsa-utils-doc alsa-lib alsaconf
apk add pulseaudio pulseaudio-alsa pulseaudio-utils
apk add pavucontrol pulsemixer
apk add pipewire pipewire-pulse pipewire-alsa
apk add wireplumber
```

## Paquets pour le clavier
```
apk add setxkbmap xkeyboard-config
apk add numlockx
apk add xbindkeys
```

## Paquets pour le bluetooth
```
apk add bluez bluez-openrc bluez-libs bluez-deprecated
apk add bluez-alsa bluez-firmware
apk add blueman
```

## Paquets pour la gestion des périphériques
```
apk add upower
apk add libinput libinput-tools
apk add xev
```

## Paquets pour les polices
```
apk add font-dejavu font-noto font-noto-emoji
apk add ttf-dejavu ttf-liberation ttf-ubuntu-font-family
apk add fontconfig
```

## Paquets pour les thèmes
```
apk add adwaita-gtk2-theme adwaita-icon-theme
apk add arc-theme arc-icon-theme
apk add papirus-icon-theme
apk add gtk+2.0 gtk+3.0 gtk-engines gtk-engine-murrine
```

## Paquets pour les applications de base
```
apk add firefox-esr
apk add pcmanfm
apk add viewnior
apk add scrot
apk add arandr
apk add lxappearance
apk add network-manager-applet
```

## Paquets pour la gestion de l'énergie dans l'environnement graphique
```
apk add xfce4-power-manager
```

## Paquets pour la configuration d'i3wm
```
# Ces fichiers seront créés manuellement
# ~/.config/i3/config
# ~/.config/i3status/config
# ~/.config/rofi/config.rasi
```
