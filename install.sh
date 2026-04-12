#!/usr/bin/env bash
set -e

echo "===== Start NixOS Auto Install ====="

DISK="/dev/sda"
HOSTNAME="metta-server"
ROOT_PASS="root123"
ADMIN_USER="admin"
ADMIN_PASS="admin123"

echo "Wiping disk..."
wipefs -a $DISK
sgdisk --zap-all $DISK

echo "Creating partitions..."
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 boot on
parted $DISK -- mkpart primary ext4 512MiB 100%

echo "Formatting partitions..."
mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

echo "Mounting..."
mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo "Generate hardware config..."
nixos-generate-config --root /mnt

echo "Updating configuration.nix..."

cat <<EOF >> /mnt/etc/nixos/configuration.nix

networking.hostName = "$HOSTNAME";

time.timeZone = "Asia/Ho_Chi_Minh";

boot.loader.systemd-boot.enable = true;
boot.loader.efi.canTouchEfiVariables = true;

services.openssh.enable = true;

users.users.$ADMIN_USER = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
  initialPassword = "$ADMIN_PASS";
};

security.sudo.wheelNeedsPassword = false;

environment.systemPackages = with pkgs; [
  git
  vim
  curl
  htop
];

EOF

echo "Installing NixOS..."
nixos-install --no-root-passwd

echo "Setting root password..."
echo "root:$ROOT_PASS" | chpasswd --root /mnt

echo "Install complete."

echo "===================================="
echo "Login info:"
echo "root password: $ROOT_PASS"
echo "$ADMIN_USER password: $ADMIN_PASS"
echo "===================================="

reboot
