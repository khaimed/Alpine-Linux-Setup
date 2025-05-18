#!/bin/sh
# Script d'installation automatique pour Alpine Linux comme hôte de virtualisation
# Ce script configure Alpine Linux comme un hôte minimal pour KVM/QEMU avec i3wm et ly-dm
# Compatible avec Intel Ultra 7 et AMD Ryzen 9 5000 + NVIDIA GeForce RTX

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
apk add alpine-base alpine-sdk build-base linux-firmware sudo
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

# Installation des paquets pour l'environnement graphique minimal
print_message "Installation de l'environnement graphique minimal..."
apk add xorg-server xorg-server-common xf86-input-libinput xf86-video-fbdev
apk add xf86-input-mouse xf86-input-keyboard xf86-input-evdev
apk add xorg-apps xauth xinit xrandr
apk add mesa-gl mesa-egl mesa-dri

# Installation de i3wm et composants
apk add i3wm i3status i3lock dmenu
apk add xfce4-terminal rofi feh picom
apk add dunst libnotify
apk add thunar thunar-volman gvfs gvfs-mtp gvfs-smb
apk add xdg-utils xdg-user-dirs

# Installation de ly-dm
apk add ly
rc-update add ly default

# Installation des polices
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
if [ "$HAS_NVIDIA" = true ]; then
    print_message "Installation des paquets NVIDIA..."
    apk add nvidia-driver nvidia-modules
    print_success "Paquets NVIDIA installés"
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
apk add qemu-img
print_success "Paquets pour KVM/QEMU installés"

# Configuration des services
print_message "Configuration des services..."
rc-update add networkmanager default
rc-update add dbus default
rc-update add libvirtd default
rc-update add bluetooth default
print_success "Services configurés"

# Création du répertoire pour les VM
print_message "Configuration du montage pour les VM..."
mkdir -p /mnt/vm

# Ajout du montage dans fstab s'il n'existe pas déjà
if ! grep -q "/mnt/vm" /etc/fstab; then
    echo "/dev/sda3    /mnt/vm    ext3    defaults    0 0" >> /etc/fstab
    print_message "Entrée ajoutée à fstab pour /mnt/vm"
fi

# Montage du répertoire VM
mount /mnt/vm || print_warning "Impossible de monter /mnt/vm, vérifiez que /dev/sda3 est disponible"
print_success "Répertoire VM configuré"

# Création des répertoires pour les images VM
print_message "Création des répertoires pour les images VM..."
mkdir -p /mnt/vm/images
mkdir -p /mnt/vm/xml
print_success "Répertoires pour les images VM créés"

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

# Création d'un utilisateur si demandé
print_message "Voulez-vous créer un nouvel utilisateur ? (o/n)"
read -r CREATE_USER
if [ "$CREATE_USER" = "o" ] || [ "$CREATE_USER" = "O" ]; then
    print_message "Entrez le nom d'utilisateur :"
    read -r USERNAME
    adduser -g "Utilisateur VM" "$USERNAME"
    addgroup "$USERNAME" libvirt
    addgroup "$USERNAME" kvm
    addgroup "$USERNAME" audio
    addgroup "$USERNAME" video
    addgroup "$USERNAME" input
    addgroup "$USERNAME" wheel
    print_success "Utilisateur $USERNAME créé et ajouté aux groupes nécessaires"
    
    # Copie des fichiers de configuration pour le nouvel utilisateur
    USER_HOME="/home/$USERNAME"
    
    # Copier les fichiers de configuration i3wm
    print_message "Copie des fichiers de configuration i3wm..."
    copy_config_file "/etc/i3/config" "/usr/share/doc/i3/config" "/usr/share/i3/config" "config" "$USER_HOME/.config/i3"
    
    # Copier les fichiers de configuration i3status
    print_message "Copie des fichiers de configuration i3status..."
    copy_config_file "/etc/i3status.conf" "/usr/share/doc/i3status/config" "/usr/share/i3status/config" "config" "$USER_HOME/.config/i3status"
    
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
fi

# Configuration de sudo
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
print_success "Sudo configuré"

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

# Création des scripts de démarrage VM
print_message "Création des scripts de démarrage VM..."
mkdir -p /usr/local/bin

# Script pour démarrer Windows 11 sur Intel
cat > /usr/local/bin/start-win11-intel << EOF
#!/bin/sh
virsh start win11-intel
EOF
chmod +x /usr/local/bin/start-win11-intel

# Script pour démarrer Windows 11 sur AMD
cat > /usr/local/bin/start-win11-amd << EOF
#!/bin/sh
virsh start win11-amd
EOF
chmod +x /usr/local/bin/start-win11-amd

# Script pour démarrer Pop!_OS
cat > /usr/local/bin/start-popos << EOF
#!/bin/sh
virsh start popos
EOF
chmod +x /usr/local/bin/start-popos
print_success "Scripts de démarrage VM créés"

# Création des fichiers XML pour les VM
print_message "Création des fichiers XML pour les VM..."

# Fichier XML pour Windows 11 sur Intel
cat > /mnt/vm/xml/win11-intel.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<domain type="kvm">
  <name>win11-intel</name>
  <uuid>00000000-0000-0000-0000-000000000001</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/11"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="GiB">14</memory>
  <currentMemory unit="GiB">14</currentMemory>
  <vcpu placement="static">4</vcpu>
  <os>
    <type arch="x86_64" machine="q35">hvm</type>
    <loader readonly="yes" type="pflash">/usr/share/ovmf/OVMF_CODE.fd</loader>
    <nvram>/mnt/vm/nvram/win11-intel_VARS.fd</nvram>
    <boot dev="hd"/>
    <bootmenu enable="yes"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vpindex state="on"/>
      <synic state="on"/>
      <stimer state="on"/>
      <reset state="on"/>
      <vendor_id state="on" value="randomid"/>
      <frequencies state="on"/>
    </hyperv>
    <kvm>
      <hidden state="on"/>
    </kvm>
    <vmport state="off"/>
    <ioapic driver="kvm"/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on">
    <topology sockets="1" dies="1" cores="4" threads="1"/>
    <feature policy="disable" name="hypervisor"/>
    <feature policy="require" name="invtsc"/>
    <cache mode="passthrough"/>
  </cpu>
  <clock offset="localtime">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
    <timer name="hypervclock" present="yes"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" discard="unmap"/>
      <source file="/mnt/vm/images/win11.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="pci" index="6" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="6" port="0x15"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:11:22:33"/>
      <source network="default"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <input type="tablet" bus="usb">
      <address type="usb" bus="0" port="1"/>
    </input>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="spice" autoport="yes">
      <listen type="address"/>
      <image compression="off"/>
    </graphics>
    <sound model="ich9">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
    </sound>
    <audio id="1" type="spice"/>
    <video>
      <model type="virtio" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
  </devices>
  <qemu:commandline xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">
    <qemu:arg value="-cpu"/>
    <qemu:arg value="host,hv_time,kvm=off,hv_vendor_id=null"/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=2,manufacturer=AlpineLinux,product=VirtualMachine,version=1.0"/>
  </qemu:commandline>
</domain>
EOF

# Fichier XML pour Windows 11 sur AMD
cat > /mnt/vm/xml/win11-amd.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<domain type="kvm">
  <name>win11-amd</name>
  <uuid>00000000-0000-0000-0000-000000000002</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/11"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="GiB">14</memory>
  <currentMemory unit="GiB">14</currentMemory>
  <vcpu placement="static">4</vcpu>
  <os>
    <type arch="x86_64" machine="q35">hvm</type>
    <loader readonly="yes" type="pflash">/usr/share/ovmf/OVMF_CODE.fd</loader>
    <nvram>/mnt/vm/nvram/win11-amd_VARS.fd</nvram>
    <boot dev="hd"/>
    <bootmenu enable="yes"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode="custom">
      <relaxed state="on"/>
      <vapic state="on"/>
      <spinlocks state="on" retries="8191"/>
      <vpindex state="on"/>
      <synic state="on"/>
      <stimer state="on"/>
      <reset state="on"/>
      <vendor_id state="on" value="randomid"/>
      <frequencies state="on"/>
    </hyperv>
    <kvm>
      <hidden state="on"/>
    </kvm>
    <vmport state="off"/>
    <ioapic driver="kvm"/>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on">
    <topology sockets="1" dies="1" cores="4" threads="1"/>
    <feature policy="disable" name="hypervisor"/>
    <feature policy="require" name="invtsc"/>
    <feature policy="require" name="topoext"/>
    <cache mode="passthrough"/>
    <model fallback="allow">EPYC</model>
  </cpu>
  <clock offset="localtime">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
    <timer name="hypervclock" present="yes"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" discard="unmap"/>
      <source file="/mnt/vm/images/win11.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="pci" index="6" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="6" port="0x15"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:11:22:44"/>
      <source network="default"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <input type="tablet" bus="usb">
      <address type="usb" bus="0" port="1"/>
    </input>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="spice" autoport="yes">
      <listen type="address"/>
      <image compression="off"/>
    </graphics>
    <sound model="ich9">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
    </sound>
    <audio id="1" type="spice"/>
    <video>
      <model type="virtio" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <hostdev mode="subsystem" type="pci" managed="yes">
      <source>
        <address domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
      </source>
      <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
    </hostdev>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
  </devices>
  <qemu:commandline xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">
    <qemu:arg value="-cpu"/>
    <qemu:arg value="host,hv_time,kvm=off,hv_vendor_id=null"/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=2,manufacturer=AlpineLinux,product=VirtualMachine,version=1.0"/>
    <qemu:arg value="-set"/>
    <qemu:arg value="device.hostdev0.x-vga=on"/>
    <qemu:arg value="-set"/>
    <qemu:arg value="device.hostdev0.romfile=/mnt/vm/vbios/nvidia.rom"/>
  </qemu:commandline>
</domain>
EOF

# Fichier XML pour Pop!_OS
cat > /mnt/vm/xml/popos.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<domain type="kvm">
  <name>popos</name>
  <uuid>00000000-0000-0000-0000-000000000003</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://ubuntu.com/ubuntu/20.04"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="GiB">8</memory>
  <currentMemory unit="GiB">8</currentMemory>
  <vcpu placement="static">4</vcpu>
  <os>
    <type arch="x86_64" machine="q35">hvm</type>
    <loader readonly="yes" type="pflash">/usr/share/ovmf/OVMF_CODE.fd</loader>
    <nvram>/mnt/vm/nvram/popos_VARS.fd</nvram>
    <boot dev="hd"/>
    <bootmenu enable="yes"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state="off"/>
    <kvm>
      <hidden state="on"/>
    </kvm>
  </features>
  <cpu mode="host-passthrough" check="none" migratable="on">
    <topology sockets="1" dies="1" cores="4" threads="1"/>
    <feature policy="disable" name="hypervisor"/>
    <cache mode="passthrough"/>
  </cpu>
  <clock offset="utc">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2" discard="unmap"/>
      <source file="/mnt/vm/images/popos.qcow2"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <interface type="network">
      <mac address="52:54:00:11:22:55"/>
      <source network="default"/>
      <model type="virtio"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <input type="tablet" bus="usb">
      <address type="usb" bus="0" port="1"/>
    </input>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <graphics type="spice" autoport="yes">
      <listen type="address"/>
      <image compression="off"/>
    </graphics>
    <sound model="ich9">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
    </sound>
    <audio id="1" type="spice"/>
    <video>
      <model type="virtio" heads="1" primary="yes"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
    </video>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
  </devices>
  <qemu:commandline xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0">
    <qemu:arg value="-cpu"/>
    <qemu:arg value="host,hv_time,kvm=off,hv_vendor_id=null"/>
    <qemu:arg value="-smbios"/>
    <qemu:arg value="type=2,manufacturer=AlpineLinux,product=VirtualMachine,version=1.0"/>
  </qemu:commandline>
</domain>
EOF
print_success "Fichiers XML pour les VM créés"

# Création des répertoires pour les NVRAM
mkdir -p /mnt/vm/nvram
mkdir -p /mnt/vm/vbios
print_success "Répertoires pour NVRAM et VBIOS créés"

# Création des images disque
print_message "Création des images disque pour les VM..."
qemu-img create -f qcow2 /mnt/vm/images/win11.qcow2 120G
qemu-img create -f qcow2 /mnt/vm/images/popos.qcow2 80G
print_success "Images disque pour les VM créées"

# Définition des VM dans libvirt
print_message "Définition des VM dans libvirt..."
virsh define /mnt/vm/xml/win11-intel.xml || print_warning "Impossible de définir win11-intel.xml"
virsh define /mnt/vm/xml/win11-amd.xml || print_warning "Impossible de définir win11-amd.xml"
virsh define /mnt/vm/xml/popos.xml || print_warning "Impossible de définir popos.xml"
print_success "VM définies dans libvirt"

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

print_success "Scripts de configuration GPU créés"

# Finalisation
print_message "Installation terminée !"
print_message "Redémarrez le système pour appliquer toutes les configurations."
print_message "Après le redémarrage, exécutez 'setup-gpu-passthrough' pour configurer le passthrough GPU."
print_message "Pour démarrer les VM, utilisez les commandes :"
print_message "  - start-win11-intel (sur machine Intel)"
print_message "  - start-win11-amd (sur machine AMD)"
print_message "  - start-popos (sur les deux machines)"

# Demande de redémarrage
print_message "Voulez-vous redémarrer maintenant ? (o/n)"
read -r REBOOT
if [ "$REBOOT" = "o" ] || [ "$REBOOT" = "O" ]; then
    print_message "Redémarrage du système..."
    reboot
fi
