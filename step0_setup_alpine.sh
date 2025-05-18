#!/bin/sh
# step0_setup_alpine.sh - Script pour la configuration initiale d'Alpine Linux
# Ce script gère la détection des disques, le partitionnement et la configuration de base
# Exécuter ce script directement depuis le TTY après avoir démarré sur la clé USB Alpine Linux

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

# Installation des outils nécessaires
print_message "Installation des outils nécessaires..."
apk update
apk add cfdisk lsblk e2fsprogs ntfs-3g ntfs-3g-progs dosfstools
print_success "Outils installés"

# Détection des disques disponibles
print_message "Détection des disques disponibles..."
echo ""
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "disk|part" | grep -v "loop"
echo ""

# Sélection du disque
print_message "Veuillez sélectionner le disque à partitionner (ex: sda, nvme0n1, etc.):"
read -r DISK
if [ ! -b "/dev/${DISK}" ]; then
    print_error "Disque /dev/${DISK} non trouvé"
    exit 1
fi
print_message "Disque sélectionné: /dev/${DISK}"

# Confirmation avant de continuer
print_warning "ATTENTION: Toutes les données sur /dev/${DISK} seront effacées!"
print_message "Voulez-vous continuer? (o/n)"
read -r CONFIRM
if [ "$CONFIRM" != "o" ] && [ "$CONFIRM" != "O" ]; then
    print_message "Opération annulée"
    exit 0
fi

# Choix du mode de partitionnement
print_message "Choisissez le mode de partitionnement:"
print_message "1) Tailles par défaut (EFI: 512M, Alpine: 20G, Swap: 2G, VM: 220G, Storage: reste)"
print_message "2) Tailles personnalisées"
read -r PART_MODE

if [ "$PART_MODE" = "1" ]; then
    # Tailles par défaut
    EFI_SIZE="512M"
    ALPINE_SIZE="20G"
    SWAP_SIZE="2G"
    VM_SIZE="220G"
    # Storage prendra le reste de l'espace
else
    # Tailles personnalisées
    print_message "Entrez la taille de la partition EFI (ex: 512M):"
    read -r EFI_SIZE
    print_message "Entrez la taille de la partition Alpine Linux (ex: 20G):"
    read -r ALPINE_SIZE
    print_message "Entrez la taille de la partition Swap (ex: 2G):"
    read -r SWAP_SIZE
    print_message "Entrez la taille de la partition VM (ex: 220G):"
    read -r VM_SIZE
    # Storage prendra le reste de l'espace
fi

# Création du script pour cfdisk
print_message "Création du script de partitionnement..."
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" << EOF
#!/bin/sh
# Script temporaire pour cfdisk

# Effacer la table de partitions existante
echo -e "g\nw\nq\n" | fdisk /dev/${DISK}

# Créer les partitions avec cfdisk
(
echo n # nouvelle partition (EFI)
echo   # partition primaire (par défaut)
echo   # premier secteur (par défaut)
echo +${EFI_SIZE} # taille
echo t # changer le type
echo 1 # EFI System
echo n # nouvelle partition (Alpine)
echo   # partition primaire (par défaut)
echo   # premier secteur (par défaut)
echo +${ALPINE_SIZE} # taille
echo n # nouvelle partition (Swap)
echo   # partition primaire (par défaut)
echo   # premier secteur (par défaut)
echo +${SWAP_SIZE} # taille
echo t # changer le type
echo 3 # numéro de partition
echo 19 # Linux swap
echo n # nouvelle partition (VM)
echo   # partition primaire (par défaut)
echo   # premier secteur (par défaut)
echo +${VM_SIZE} # taille
echo n # nouvelle partition (Storage)
echo   # partition primaire (par défaut)
echo   # premier secteur (par défaut)
echo   # dernier secteur (par défaut, utilise tout l'espace restant)
echo t # changer le type
echo 5 # numéro de partition
echo 11 # Microsoft basic data (NTFS)
echo w # écrire les changements
) | fdisk /dev/${DISK}
EOF
chmod +x "$TMP_SCRIPT"

# Exécution du script de partitionnement
print_message "Partitionnement du disque /dev/${DISK}..."
"$TMP_SCRIPT"
rm "$TMP_SCRIPT"
print_success "Partitionnement terminé"

# Attendre que le système détecte les nouvelles partitions
print_message "Attente de la détection des nouvelles partitions..."
sleep 3

# Formatage des partitions
print_message "Formatage des partitions..."
mkfs.vfat -F32 -n EFI /dev/${DISK}1
mkfs.ext4 -L "Alpine Linux" /dev/${DISK}2
mkswap -L swap /dev/${DISK}3
mkfs.ext4 -L "Virtual Machine" /dev/${DISK}4
mkfs.ntfs -f -L Storage /dev/${DISK}5
print_success "Formatage terminé"

# Montage des partitions
print_message "Montage des partitions..."
mkdir -p /mnt/boot
mount -t vfat /dev/${DISK}1 /mnt/boot
mount /dev/${DISK}2 /mnt
swapon /dev/${DISK}3
mkdir -p /mnt/vm
mkdir -p /mnt/storage
mount -t ext4 /dev/${DISK}4 /mnt/vm
mount -t ntfs-3g /dev/${DISK}5 /mnt/storage
print_success "Montage terminé"

# Installation du système
print_message "Installation du système Alpine Linux..."
setup-disk -m sys /mnt
print_success "Installation terminée"

# Ajout des entrées fstab pour VM et Storage
print_message "Configuration de fstab pour VM et Storage..."
if [ -f /mnt/etc/fstab ]; then
    # Vérifier si les entrées existent déjà
    if ! grep -q "/mnt/vm" /mnt/etc/fstab; then
        echo "/dev/${DISK}4    /mnt/vm    ext4    defaults    0 0" >> /mnt/etc/fstab
    fi
    if ! grep -q "/mnt/storage" /mnt/etc/fstab; then
        echo "/dev/${DISK}5    /mnt/storage    ntfs-3g    defaults    0 0" >> /mnt/etc/fstab
    fi
    print_success "Entrées fstab ajoutées"
else
    print_warning "Fichier fstab non trouvé, les entrées devront être ajoutées manuellement"
fi

# Création des répertoires dans le système installé
print_message "Création des répertoires dans le système installé..."
mkdir -p /mnt/mnt/vm
mkdir -p /mnt/mnt/storage
print_success "Répertoires créés"

# Finalisation
print_message "Installation de base terminée !"
print_message "Vous pouvez maintenant démonter les partitions et redémarrer:"
print_message "umount -R /mnt"
print_message "reboot"

# Demande de démontage et redémarrage
print_message "Voulez-vous démonter et redémarrer maintenant ? (o/n)"
read -r REBOOT
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Démontage des partitions..."
    umount -R /mnt
    print_message "Redémarrage du système..."
    reboot
fi

print_message "Script terminé. Veuillez démonter manuellement avec 'umount -R /mnt' et redémarrer avec 'reboot'"
