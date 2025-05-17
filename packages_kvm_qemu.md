# Paquets pour KVM/QEMU et virtualisation

## Paquets de base pour KVM/QEMU
```
apk add qemu qemu-img qemu-system-x86_64 qemu-modules
apk add libvirt libvirt-daemon libvirt-client
apk add virt-manager virt-viewer
apk add dbus dbus-openrc polkit
apk add bridge-utils
apk add ovmf
```

## Paquets spécifiques pour Intel
```
apk add qemu-system-i386 qemu-system-x86_64
apk add intel-ucode
```

## Paquets spécifiques pour AMD
```
apk add qemu-system-i386 qemu-system-x86_64
apk add amd-ucode
```

## Paquets pour le réseau virtuel
```
apk add iptables ebtables dnsmasq
apk add bridge-utils
```

## Paquets pour la sécurité et le masquage du matériel
```
apk add apparmor-profiles-extra
apk add libvirt-apparmor
```

## Paquets pour la gestion des images disque
```
apk add qemu-img
apk add libguestfs libguestfs-tools
```

## Configuration des services
```
rc-update add libvirtd default
rc-update add dbus default
```

## Configuration des groupes d'utilisateurs
```
addgroup <username> libvirt
addgroup <username> kvm
```

## Paramètres pour masquer le matériel dans les VM
```
# Ces paramètres seront inclus dans les fichiers XML
# - vendor_id
# - hidden state
# - kvm hidden
# - hypervisor features
```

## Emplacement des fichiers de configuration
```
# Fichiers XML pour les VM
/etc/libvirt/qemu/

# Images disque
/var/lib/libvirt/images/
```

## Commandes pour créer des images disque
```
# Créer une image Windows 11
qemu-img create -f qcow2 /var/lib/libvirt/images/win11.qcow2 100G

# Créer une image Pop!_OS
qemu-img create -f qcow2 /var/lib/libvirt/images/popos.qcow2 50G
```

## Optimisations pour le gaming dans les VM
```
# Paramètres à inclure dans les fichiers XML
# - CPU pinning
# - Hugepages
# - Mémoire statique
# - Contrôleur virtio
# - Disques virtio
```
