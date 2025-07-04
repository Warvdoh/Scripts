#!/bin/bash

# === Color Definitions ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# === Setup Temp Directory ===
TMPDIR="/tmp/safe_recovery"
mkdir -p "$TMPDIR"

# === Interrupt Trap ===
cleanup() {
    echo -e "${YELLOW}\n[INFO] Cleaning up...${NC}"
    [[ -d "$MOUNT_POINT" ]] && sudo umount "$MOUNT_POINT" 2>/dev/null
    exit 1
}
trap cleanup INT TERM

# === Device Scanning ===
echo -e "${BLUE}=== Scanning for available block devices... ===${NC}"
DEVICES=$(lsblk -dpno NAME,TYPE | grep -w disk)

declare -A DEV_MAP
INDEX=1

echo -e "${YELLOW}Available Drives:${NC}"
while read -r DEV TYPE; do
    SIZE=$(lsblk -dnbo SIZE "$DEV" | awk '{print $1}')
    SIZE_HR=$(numfmt --to=iec --suffix=B "$SIZE")
    MOUNTED=$(lsblk -no MOUNTPOINT "$DEV" | grep -v '^$' | head -n 1)
    printf "%s) %s (%s, %s)\n" "$INDEX" "$DEV" "$SIZE_HR" "${MOUNTED:-unmounted}"
    DEV_MAP["$INDEX"]="$DEV"
    ((INDEX++))
done <<< "$DEVICES"

# === Device Selection ===
read -rp $'\nChoose a drive number to operate on: ' CHOICE
DEVICE="${DEV_MAP[$CHOICE]}"

if [ -z "$DEVICE" ]; then
    echo -e "${RED}[ERROR] Invalid selection.${NC}"
    exit 1
fi

echo -e "${GREEN}Selected device: $DEVICE${NC}"
read -rp "Are you sure you want to continue with $DEVICE? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || {
    echo -e "${YELLOW}Aborted by user.${NC}"
    exit 0
}

# === Operation Selection ===
echo -e "${YELLOW}Operation: S = scan, C = copy, SC = both${NC}"
read -rp "Enter operation: " OP

MOUNT_POINT="$TMPDIR/mnt_$(basename "$DEVICE")"
mkdir -p "$MOUNT_POINT"

# === Mount Attempt ===
# Attempt to mount the device
echo -e "${BLUE}--- Mounting $DEVICE read-only... ---${NC}"
if ! sudo mount -o ro "$DEVICE" "$MOUNT_POINT" 2>/dev/null; then
    echo -e "${RED}[WARNING] Mount failed. Searching for partitions...${NC}"
    MAP_PARTS=$(lsblk -lnpo NAME,TYPE | awk '$2 == "part" { print $1 }' | grep "^$DEVICE")

    if [ -z "$MAP_PARTS" ]; then
        echo -e "${RED}[ERROR] No partitions found to mount.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Available Partitions:${NC}"
    PART_INDEX=1
    declare -A PART_MAP

    while read -r PART; do
        FSTYPE=$(lsblk -no FSTYPE "$PART")
        SIZE=$(lsblk -dnbo SIZE "$PART" | awk '{print $1}')
        SIZE_HR=$(numfmt --to=iec --suffix=B "$SIZE")
        echo "$PART_INDEX) $PART ($SIZE_HR, ${FSTYPE:-unknown FS})"
        PART_MAP["$PART_INDEX"]="$PART"
        ((PART_INDEX++))
    done <<< "$MAP_PARTS"

    read -rp "Choose partition to mount: " PART_CHOICE
    PART="${PART_MAP[$PART_CHOICE]}"
    if [ -z "$PART" ]; then
        echo -e "${RED}[ERROR] Invalid partition selection.${NC}"
        exit 1
    fi

    DEVICE="$PART"
    if ! sudo mount -o ro "$DEVICE" "$MOUNT_POINT"; then
        echo -e "${RED}[ERROR] Failed to mount $DEVICE.${NC}"
        exit 1
    fi
fi

# === Scan and/or Copy ===
SCAN_LOG="$TMPDIR/scan_$(basename "$DEVICE").log"
COPY_DEST="$TMPDIR/backup_$(basename "$DEVICE")"
mkdir -p "$COPY_DEST"

if [[ "$OP" == *S* ]]; then
    echo -e "${BLUE}Starting badblocks scan...${NC}"
    (ionice -c2 -n7 nice -n19 sudo badblocks -sv "$DEVICE" > "$SCAN_LOG") &
    SCAN_PID=$!
fi

if [[ "$OP" == *C* ]]; then
    echo -e "${BLUE}Starting file copy...${NC}"
    (
        rsync -a --info=progress2 --ignore-existing "$MOUNT_POINT"/ "$COPY_DEST"/
    ) > "$TMPDIR/copy_$(basename "$DEVICE").log" 2>&1 &
    COPY_PID=$!
fi

# === Wait for Completion ===
[[ "$SCAN_PID" ]] && wait "$SCAN_PID" && echo -e "${GREEN}[OK] Scan finished.${NC}"
[[ "$COPY_PID" ]] && wait "$COPY_PID" && echo -e "${GREEN}[OK] Copy finished.${NC}"

# === Wrap-up ===
echo -e "${YELLOW}Logs and copied files are in:${NC} $TMPDIR"

# === Optional Unmount ===
read -rp "Do you want to unmount the drive? (y/N): " UMNT
[[ "$UMNT" =~ ^[Yy]$ ]] && sudo umount "$MOUNT_POINT" && echo -e "${GREEN}[OK] Drive unmounted.${NC}"
# Licensed under Warvdoh's Personal Use License (WPUL) Version 1.2 Copyright (c) 2025 Warvdoh Mróz. https://warvdoh.github.io/Assets/LICENSE.md
