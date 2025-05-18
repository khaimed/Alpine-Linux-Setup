#!/bin/sh
# step0_setup_alpine.sh – Fully automated Alpine Linux disk setup
# Creates GPT layout: EFI, Alpine root, swap, VM, Storage
# Run from Alpine Live USB as root.

set -euo pipefail

# ---------- colours ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

msg()      { echo -e "${BLUE}[INFO]${NC} $1" ; }
success()  { echo -e "${GREEN}[OK]${NC} $1" ; }
warn()     { echo -e "${YELLOW}[WARN]${NC} $1" ; }
error()    { echo -e "${RED}[ERROR]${NC} $1" ; }

[ "$(id -u)" -eq 0 ] || { error "Run as root" ; exit 1 ; }

# ---------- packages ----------
# fdisk is part of util-linux; sgdisk is provided by gptfdisk
msg "Installing required packages ..."
apk update
apk add --no-cache lsblk e2fsprogs dosfstools ntfs-3g ntfs-3g-progs util-linux gptfdisk sgdisk bc
success "Packages installed"

# ---------- select disk ----------
msg "Available disks:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E "disk|part" | grep -v loop
echo
read -rp "Disk to use (e.g. sda, nvme0n1): " DISK
[ -b "/dev/$DISK" ] || { error "/dev/$DISK not found" ; exit 1 ; }

warn "This will ERASE /dev/$DISK entirely!"
read -rp "Continue? [y/N]: " confirm
[ "${confirm:-n}" = "y" ] || { msg "Aborted" ; exit 0 ; }

# ---------- partition sizes ----------
default_sizes() {
  EFI_SIZE=512M
  ALPINE_SIZE=20G
  SWAP_SIZE=2G
  VM_SIZE=220G
}
custom_sizes() {
  read -rp "EFI size (e.g. 512M): " EFI_SIZE
  read -rp "Alpine Linux size (e.g. 20G): " ALPINE_SIZE
  read -rp "Swap size (e.g. 2G): " SWAP_SIZE
  read -rp "Virtual Machine size (e.g. 220G): " VM_SIZE
}
msg "Partitioning mode:
1) Default (EFI 512M / Alpine 20G / Swap 2G / VM 220G / Storage rest)
2) Custom"
read -rp "Select [1/2]: " mode
[ "${mode:-1}" = "2" ] && custom_sizes || default_sizes

# ---------- partitioning ----------
msg "Wiping existing partition table ..."
sgdisk --zap-all /dev/$DISK

msg "Creating GPT partitions with sgdisk ..."
sgdisk -n1:0:+$EFI_SIZE   -t1:ef00 -c1:"EFI"              \
       -n2:0:+$ALPINE_SIZE -t2:8300 -c2:"Alpine Linux"    \
       -n3:0:+$SWAP_SIZE   -t3:8200 -c3:"Swap"            \
       -n4:0:+$VM_SIZE     -t4:8300 -c4:"Virtual Machine" \
       -n5:0:0             -t5:0700 -c5:"Storage"         /dev/$DISK
success "Partitions created"

# wait for kernel to refresh partition table
msg "Waiting for partition nodes to appear ..."
sleep 3

# ---------- formatting ----------
msg "Formatting filesystems ..."
mkfs.vfat -F32 -n EFI          /dev/${DISK}1
mkfs.ext4 -L "Alpine Linux"    /dev/${DISK}2
mkswap   -L swap               /dev/${DISK}3
mkfs.ext4 -L "Virtual Machine" /dev/${DISK}4
mkfs.ntfs -f -L storage        /dev/${DISK}5
success "Filesystems ready"

# ---------- mount ----------
msg "Mounting filesystems ..."
mount /dev/${DISK}2 /mnt
mkdir -p /mnt/boot /mnt/vm /mnt/storage
mount -t vfat    /dev/${DISK}1 /mnt/boot
mount -t ext4    /dev/${DISK}4 /mnt/vm
mount -t ntfs-3g /dev/${DISK}5 /mnt/storage
swapon /dev/${DISK}3
success "Mounted"

# ---------- install ----------
msg "Installing Alpine into /mnt ..."
setup-disk -m sys /mnt
success "Alpine installed"

# ---------- fstab entries ----------
msg "Adding extra mountpoints to fstab ..."
grep -q " /vm " /mnt/etc/fstab || echo "/dev/${DISK}4 /vm ext4 defaults 0 0" >> /mnt/etc/fstab
grep -q " /storage " /mnt/etc/fstab || echo "/dev/${DISK}5 /storage ntfs-3g defaults 0 0" >> /mnt/etc/fstab
success "fstab updated"

msg "All done! You can now 'umount -R /mnt && reboot'."
