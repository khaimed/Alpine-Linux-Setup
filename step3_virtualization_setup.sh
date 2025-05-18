#!/bin/sh
# Step 3: Virtualization Setup Script
# This script installs and configures KVM/QEMU and libvirt
# Run this script after step2_desktop_setup.sh and a system reboot

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

# Installation des paquets pour KVM/QEMU
print_message "Installation des paquets pour KVM/QEMU..."
apk add qemu qemu-img qemu-system-x86_64 qemu-modules
apk add libvirt libvirt-daemon libvirt-client
apk add virt-manager virt-viewer
apk add dbus dbus-openrc polkit
apk add bridge-utils
apk add ovmf
apk add iptables ebtables dnsmasq
print_success "Paquets pour KVM/QEMU installés"

# Configuration des services
print_message "Configuration des services..."
rc-update add dbus default
rc-update add libvirtd default
print_success "Services configurés"

# Création des répertoires pour les VM
print_message "Création des répertoires pour les VM..."
mkdir -p /mnt/vm/images
mkdir -p /mnt/vm/xml
mkdir -p /mnt/vm/nvram
mkdir -p /mnt/vm/vbios
print_success "Répertoires pour les VM créés"

# Configuration pour le passthrough matériel
print_message "Configuration pour le passthrough matériel..."

# Modification de GRUB pour activer IOMMU
if [ -f /etc/default/grub ]; then
    if [ "$CPU_TYPE" = "intel" ]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"/g' /etc/default/grub
    elif [ "$CPU_TYPE" = "amd" ]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_iommu=on iommu=pt"/g' /etc/default/grub
    fi
    update-grub
    print_message "GRUB configuré pour IOMMU"
else
    print_warning "Fichier GRUB non trouvé, configuration manuelle requise pour IOMMU"
    
    # Alternative pour les systèmes sans GRUB (comme Alpine avec syslinux)
    if [ -f /etc/update-extlinux.conf ]; then
        if [ "$CPU_TYPE" = "intel" ]; then
            sed -i 's/default_kernel_opts=".*"/default_kernel_opts="quiet intel_iommu=on iommu=pt"/g' /etc/update-extlinux.conf
        elif [ "$CPU_TYPE" = "amd" ]; then
            sed -i 's/default_kernel_opts=".*"/default_kernel_opts="quiet amd_iommu=on iommu=pt"/g' /etc/update-extlinux.conf
        fi
        update-extlinux
        print_message "Extlinux configuré pour IOMMU"
    fi
fi

# Configuration des modules pour le passthrough
cat > /etc/modules << EOF
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
EOF
print_success "Modules pour le passthrough configurés"

# Configuration de libvirt pour le passthrough
mkdir -p /etc/libvirt/hooks
cat > /etc/libvirt/hooks/qemu << EOF
#!/bin/bash
GUEST=\$1
OPERATION=\$2
if [ "\$GUEST" = "win11-intel" ] || [ "\$GUEST" = "win11-amd" ] || [ "\$GUEST" = "popos" ]; then
    if [ "\$OPERATION" = "start" ]; then
        echo "Préparation du passthrough pour \$GUEST"
        # Ajouter ici des commandes spécifiques pour le passthrough
    elif [ "\$OPERATION" = "stopped" ]; then
        echo "Nettoyage après arrêt de \$GUEST"
        # Ajouter ici des commandes de nettoyage
    fi
fi
EOF
chmod +x /etc/libvirt/hooks/qemu
print_success "Libvirt configuré pour le passthrough"

# Script pour identifier et configurer le passthrough GPU
cat > /usr/local/bin/setup-gpu-passthrough << EOF
#!/bin/sh
# Script pour identifier et configurer le passthrough GPU

# Identifier les GPU disponibles
echo "GPUs disponibles :"
lspci -nn | grep -i "VGA\|3D\|Display"

# Demander à l'utilisateur de choisir un GPU
echo "Entrez l'identifiant du GPU à passer en passthrough (ex: 01:00.0) :"
read -r GPU_ID

# Obtenir le vendor:device ID
VENDOR_DEVICE=\$(lspci -nn | grep \$GPU_ID | grep -o "\[....:...." | tr -d '[]')
VENDOR=\$(echo \$VENDOR_DEVICE | cut -d':' -f1)
DEVICE=\$(echo \$VENDOR_DEVICE | cut -d':' -f2)

# Créer le fichier de configuration VFIO
echo "options vfio-pci ids=\$VENDOR:\$DEVICE" > /etc/modprobe.d/vfio.conf

# Mettre à jour les fichiers XML
sed -i "s/<address domain=\"0x0000\" bus=\"0x01\" slot=\"0x00\" function=\"0x0\"\/>/<address domain=\"0x0000\" bus=\"\$(echo \$GPU_ID | cut -d':' -f1)\" slot=\"\$(echo \$GPU_ID | cut -d':' -f2 | cut -d'.' -f1)\" function=\"\$(echo \$GPU_ID | cut -d'.' -f2)\"\/>/" /mnt/vm/xml/win11-amd.xml

# Extraire le VBIOS si NVIDIA
if lspci -nn | grep -i nvidia | grep -q \$GPU_ID; then
    echo "GPU NVIDIA détecté, extraction du VBIOS..."
    echo "Cette opération nécessite un redémarrage."
    echo "Après le redémarrage, exécutez : extract-nvidia-vbios \$GPU_ID"
fi

echo "Configuration du passthrough GPU terminée. Redémarrez pour appliquer les changements."
EOF
chmod +x /usr/local/bin/setup-gpu-passthrough

# Script pour extraire le VBIOS NVIDIA
cat > /usr/local/bin/extract-nvidia-vbios << EOF
#!/bin/sh
# Script pour extraire le VBIOS NVIDIA

if [ -z "\$1" ]; then
    echo "Usage: \$0 <GPU_ID>"
    echo "Exemple: \$0 01:00.0"
    exit 1
fi

GPU_ID=\$1
VBIOS_PATH="/mnt/vm/vbios/nvidia.rom"

echo "Extraction du VBIOS pour le GPU \$GPU_ID..."
echo 1 > /sys/bus/pci/devices/0000:\$GPU_ID/rom
cat /sys/bus/pci/devices/0000:\$GPU_ID/rom > \$VBIOS_PATH
echo 0 > /sys/bus/pci/devices/0000:\$GPU_ID/rom

echo "VBIOS extrait et sauvegardé dans \$VBIOS_PATH"
EOF
chmod +x /usr/local/bin/extract-nvidia-vbios

# Ajout de l'utilisateur aux groupes de virtualisation
if [ -n "$USERNAME" ]; then
    print_message "Ajout de l'utilisateur $USERNAME aux groupes de virtualisation..."
    addgroup "$USERNAME" libvirt
    addgroup "$USERNAME" kvm
    print_success "Utilisateur $USERNAME ajouté aux groupes de virtualisation"
fi

# Finalisation
print_message "Installation de la virtualisation terminée !"
print_message "Redémarrez le système puis exécutez le script step4_vm_setup.sh"

# Demande de redémarrage
print_message "Voulez-vous redémarrer maintenant ? (o/n)"
read -r REBOOT
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Redémarrage du système..."
    reboot
fi
