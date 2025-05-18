#!/bin/sh
# Step 1: Base Alpine Linux Setup Script
# This script handles the initial setup of Alpine Linux as a VM host
# Run this script first after a fresh Alpine Linux installation

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

# Détection du CPU
print_message "Détection du matériel..."
if grep -q "Intel" /proc/cpuinfo; then
    CPU_TYPE="intel"
    print_message "CPU Intel détecté"
elif grep -q "AMD" /proc/cpuinfo; then
    CPU_TYPE="amd"
    print_message "CPU AMD détecté"
else
    CPU_TYPE="generic"
    print_warning "Type de CPU non détecté, utilisation de la configuration générique"
fi

# Détection de la carte graphique NVIDIA
if lspci | grep -i nvidia > /dev/null; then
    HAS_NVIDIA=true
    print_message "Carte graphique NVIDIA détectée"
else
    HAS_NVIDIA=false
    print_message "Pas de carte graphique NVIDIA détectée"
fi

# Mise à jour des dépôts
print_message "Mise à jour des dépôts..."
cat > /etc/apk/repositories << EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
https://dl-cdn.alpinelinux.org/alpine/edge/community
EOF

apk update
print_success "Dépôts mis à jour"

# Installation des paquets de base
print_message "Installation des paquets système essentiels..."
apk add alpine-base alpine-sdk build-base linux-firmware doas sudo
apk add eudev udev-init-scripts udev-init-scripts-openrc
apk add e2fsprogs e2fsprogs-extra dosfstools ntfs-3g
apk add bash bash-completion coreutils util-linux pciutils usbutils
apk add curl wget git nano vim
apk add htop neofetch lsblk
apk add openssl openssh openssh-server
apk add chrony tzdata
print_success "Paquets système essentiels installés"

# Installation des paquets réseau
print_message "Installation des paquets réseau..."
apk add networkmanager networkmanager-cli networkmanager-tui networkmanager-wifi
apk add wpa_supplicant wireless-tools iw
apk add dhclient
print_success "Paquets réseau installés"

# Configuration des services réseau
print_message "Configuration des services réseau..."
rc-update add networkmanager default
rc-update add udev default
rc-update add udev-trigger default
rc-update add udev-settle default
print_success "Services réseau configurés"

# Configuration des montages pour les partitions
print_message "Configuration des montages pour les partitions..."

# Création du répertoire pour les VM
mkdir -p /mnt/vm

# Ajout du montage dans fstab s'il n'existe pas déjà
if ! grep -q "/mnt/vm" /etc/fstab; then
    echo "/dev/sda4    /mnt/vm    ext4    defaults    0 0" >> /etc/fstab
    print_message "Entrée ajoutée à fstab pour /mnt/vm"
fi

# Création du répertoire pour le stockage
mkdir -p /mnt/storage

# Ajout du montage dans fstab s'il n'existe pas déjà
if ! grep -q "/mnt/storage" /etc/fstab; then
    echo "/dev/sda5    /mnt/storage    ntfs    defaults    0 0" >> /etc/fstab
    print_message "Entrée ajoutée à fstab pour /mnt/storage"
fi

# Montage des répertoires
mount /mnt/vm || print_warning "Impossible de monter /mnt/vm, vérifiez que /dev/sda4 est disponible"
mount /mnt/storage || print_warning "Impossible de monter /mnt/storage, vérifiez que /dev/sda5 est disponible"
print_success "Répertoires montés"

# Création d'un utilisateur si demandé
print_message "Voulez-vous créer un nouvel utilisateur ? (o/n)"
read -r CREATE_USER
if [ "$CREATE_USER" = "o" ] || [ "$CREATE_USER" = "O" ]; then
    print_message "Entrez le nom d'utilisateur :"
    read -r USERNAME
    adduser -g "Utilisateur VM" "$USERNAME"
    print_success "Utilisateur $USERNAME créé"
    
    # Configuration de sudo
    echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
    addgroup "$USERNAME" wheel
    print_success "Sudo configuré pour $USERNAME"
fi

# Sauvegarde des informations de détection pour les scripts suivants
print_message "Sauvegarde des informations de détection..."
mkdir -p /etc/alpine_vm_setup
cat > /etc/alpine_vm_setup/hardware_info << EOF
CPU_TYPE=$CPU_TYPE
HAS_NVIDIA=$HAS_NVIDIA
EOF

if [ -n "$USERNAME" ]; then
    echo "USERNAME=$USERNAME" >> /etc/alpine_vm_setup/hardware_info
fi
print_success "Informations de détection sauvegardées"

# Finalisation
print_message "Installation de base terminée !"
print_message "Redémarrez le système puis exécutez le script step2_desktop_setup.sh"

# Demande de redémarrage
print_message "Voulez-vous redémarrer maintenant ? (o/n)"
read -r REBOOT
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Redémarrage du système..."
    reboot
fi
