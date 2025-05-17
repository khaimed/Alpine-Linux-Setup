# Paquets de base pour Alpine Linux (Gaming Setup)

## Paquets système essentiels
```
apk add alpine-base alpine-sdk build-base linux-firmware doas sudo
apk add eudev udev-init-scripts udev-init-scripts-openrc
apk add e2fsprogs e2fsprogs-extra dosfstools ntfs-3g
apk add bash bash-completion coreutils util-linux pciutils usbutils
apk add curl wget git nano vim
apk add htop neofetch lsblk
apk add openssl openssh openssh-server
apk add chrony tzdata
```

## Paquets réseau
```
apk add networkmanager networkmanager-cli networkmanager-tui networkmanager-wifi
apk add wpa_supplicant wireless-tools iw
apk add dhclient
```

## Paquets de sécurité
```
apk add iptables ip6tables iptables-openrc
apk add fail2ban fail2ban-openrc
apk add apparmor apparmor-utils apparmor-profiles
apk add firejail
```

## Paquets pour Intel
```
apk add intel-ucode
apk add mesa mesa-dri-intel intel-media-driver
```

## Paquets pour AMD
```
apk add amd-ucode
apk add mesa mesa-dri-gallium mesa-vulkan-ati
```

## Paquets pour NVIDIA
```
# Ajouter le dépôt community
echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
apk update

# Installer les pilotes NVIDIA
apk add nvidia-driver nvidia-modules
```

## Paquets pour le gaming
```
# Vulkan
apk add vulkan-loader vulkan-tools vulkan-headers vulkan-validation-layers

# OpenGL
apk add mesa-gl mesa-egl mesa-dev

# Bibliothèques de jeu
apk add sdl2 sdl2-dev sdl2_image sdl2_mixer sdl2_ttf
apk add libva libva-intel-driver libva-utils
apk add vdpau-va-driver

# Compatibilité 32-bit (pour certains jeux)
apk add gcompat
```

## Paquets pour la gestion d'énergie
```
apk add acpi acpid acpid-openrc
apk add cpufrequtils powertop
```

## Paquets pour la compression
```
apk add zip unzip p7zip xz tar gzip bzip2
```

## Paquets pour le support des langues
```
apk add ibus ibus-libpinyin
apk add noto-fonts noto-fonts-cjk noto-fonts-emoji
```
