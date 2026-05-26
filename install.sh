#!/usr/bin/env bash
set -euo pipefail

echo "======================================"
echo "      NixOS 25.12 Auto Installer"
echo "======================================"

DISK="/dev/sda"
HOSTNAME="nixos-server"

ROOT_PASS="root123"
ADMIN_USER="admin"
ADMIN_PASS="admin123"

echo "[1/7] Wiping disk $DISK ..."
wipefs -af $DISK
sgdisk --zap-all $DISK

echo "[2/7] Creating partitions..."
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 512MiB
parted -s $DISK set 1 boot on
parted -s $DISK mkpart primary ext4 512MiB 100%

echo "[3/7] Formatting filesystems..."
mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

echo "[4/7] Mounting target filesystem..."
mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

echo "[5/7] Generating hardware configuration..."
nixos-generate-config --root /mnt

echo "[6/7] Writing configuration.nix..."

cat > /mnt/etc/nixos/configuration.nix <<EOF
{ config, pkgs, ... }:

{
  imports =
    [ ./hardware-configuration.nix ];

  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;
  networking.useDHCP = false;

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
    wget
    btop
    alacritty
    gedit
    gemini-cli
    networkmanager
  ];

  system.stateVersion = "25.12";
}
EOF

echo "[7/7] Installing NixOS..."
nixos-install --no-root-passwd

echo "Setting root password..."
echo "root:$ROOT_PASS" | chpasswd --root /mnt

echo "======================================"
echo " Installation Complete"
echo "--------------------------------------"
echo "Root login:"
echo "  user: root"
echo "  pass: $ROOT_PASS"
echo ""
echo "Admin login:"
echo "  user: $ADMIN_USER"
echo "  pass: $ADMIN_PASS"
echo "======================================"

sleep 5
reboot
