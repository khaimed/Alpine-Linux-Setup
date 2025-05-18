#!/bin/sh
# step1_base_setup.sh – Optimized base Alpine Linux VM host setup
# Run once after fresh Alpine install as root

set -euo pipefail

# ---------- Colors ----------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()      { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[ "$(id -u)" -eq 0 ] || err "Must be run as root"

# ---------- Hardware Detection ----------
log "Detecting CPU..."
if grep -qi intel /proc/cpuinfo; then CPU_TYPE=intel; log "Intel CPU";
elif grep -qi amd   /proc/cpuinfo; then CPU_TYPE=amd;   log "AMD CPU";
else CPU_TYPE=generic; warn "Unknown CPU, using generic"; fi

log "Detecting NVIDIA GPU..."
if lspci | grep -qi nvidia; then HAS_NVIDIA=1; log "NVIDIA GPU present"; else HAS_NVIDIA=0; log "No NVIDIA GPU"; fi

# ---------- Repositories ----------
log "Configuring APK repositories..."
cat >/etc/apk/repositories <<EOF
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
https://dl-cdn.alpinelinux.org/alpine/edge/community
https://dl-cdn.alpinelinux.org/alpine/edge/testing
EOF
apk update
ok "Repos updated"

# ---------- Package Installation ----------
log "Installing packages..."
apk add --no-cache \
  alpine-base alpine-sdk build-base linux-firmware doas sudo \
  eudev e2fsprogs dosfstools ntfs-3g \
  bash bash-completion coreutils util-linux pciutils usbutils \
  curl wget git nano vim htop lsblk \
  neofetch dhclient \
  openssh openssh-server chrony tzdata \
  networkmanager wpa_supplicant wireless-tools
ok "Packages installed"

# ---------- Services Enable ----------
log "Enabling services..."
for svc in networkmanager sshd chronyd; do rc-update add "$svc" default; done
ok "Services set to start on boot"

# ---------- Timezone Setup ----------
log "Setting timezone to UTC..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
ok "Timezone configured"

# ---------- Mountpoints & Fstab ----------
log "Configuring VM and storage mounts..."
mkdir -p /mnt/vm /mnt/storage
# Use filesystem labels for device-agnostic mounting
grep -q 'LABEL=vm' /etc/fstab || echo "LABEL=vm /mnt/vm ext4 defaults 0 0" >> /etc/fstab
grep -q 'LABEL=storage' /etc/fstab || echo "LABEL=storage /mnt/storage ntfs-3g defaults 0 0" >> /etc/fstab
# Mount now
mount /mnt/vm || warn "Could not mount /mnt/vm"
mount /mnt/storage || warn "Could not mount /mnt/storage"
ok "Mountpoints ready"

# ---------- User Creation ----------
log "Create non-root user? [y/N]"
read -r CR
if [ "${CR,,}" = y ]; then
  read -rp "Username: " USER
  adduser -G wheel "$USER"
  # Permit wheel group in doas
  echo "permit persist :wheel" >/etc/doas.conf
  ok "User '$USER' created and wheel/doas configured"
fi

# ---------- Save Detection Info ----------
log "Saving hardware info..."
mkdir -p /etc/alpine_vm_setup
cat >/etc/alpine_vm_setup/hardware_info <<EOF
CPU_TYPE=$CPU_TYPE
HAS_NVIDIA=$HAS_NVIDIA
EOF
[ -n "${USER:+1}" ] && echo "USERNAME=$USER" >>/etc/alpine_vm_setup/hardware_info
ok "Detection info saved"

log "Base setup complete. Reboot to apply changes."
