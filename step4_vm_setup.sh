#!/bin/sh
# Step 4: VM Setup Script
# This script creates and configures VM templates for Windows 11 and Pop!OS
# Run this script after step3_virtualization_setup.sh and a system reboot

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
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="/mnt/storage/windows11.iso"/>
      <target dev="sda" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
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
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="/mnt/storage/windows11.iso"/>
      <target dev="sda" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
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
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="/mnt/storage/pop-os.iso"/>
      <target dev="sda" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
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

# Finalisation
print_message "Installation des VM terminée !"
print_message "Votre système Alpine Linux est maintenant configuré comme hôte de virtualisation."
print_message "Pour configurer le passthrough GPU, exécutez la commande 'setup-gpu-passthrough'"
print_message "Pour démarrer les VM, utilisez les commandes :"
print_message "  - start-win11-intel (sur machine Intel)"
print_message "  - start-win11-amd (sur machine AMD)"
print_message "  - start-popos (sur les deux machines)"

print_message "Installation complète !"
