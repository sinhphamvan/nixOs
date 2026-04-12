#!/usr/bin/env bash
set -e

echo "Start NixOS auto install"

DISK="/dev/sda"

wipefs -a $DISK
sgdisk --zap-all $DISK

parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 boot on
parted $DISK -- mkpart primary ext4 512MiB 100%

mkfs.fat -F32 ${DISK}1
mkfs.ext4 ${DISK}2

mount ${DISK}2 /mnt
mkdir -p /mnt/boot
mount ${DISK}1 /mnt/boot

nixos-generate-config --root /mnt

nixos-install --no-root-passwd

reboot
