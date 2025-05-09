#!/bin/bash

# Test script to verify serial port configuration
# Copyright Peter Burke 2024

echo "Starting serial port configuration test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Set configuration paths for Ubuntu on Raspberry Pi
CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"

echo "1. Checking current configuration..."
echo "=== Serial devices ==="
ls -l /dev/tty* 2>/dev/null | grep -E 'serial|AMA|USB'

echo "\n2. Configuring UART..."
# Disable Bluetooth to free up the PL011 UART
if systemctl is-active --quiet bluetooth; then
    systemctl disable bluetooth
    systemctl stop bluetooth
    echo "Disabled Bluetooth service"
fi

# Configure UART in config.txt
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
    
    # Remove any existing uart-related settings
    sed -i '/^enable_uart=/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=uart/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=disable-bt/d' "$CONFIG_FILE"
    sed -i '/^dtparam=uart0=/d' "$CONFIG_FILE"
    sed -i '/^dtparam=uart1=/d' "$CONFIG_FILE"
    
    # Add UART configuration
    echo "" >> "$CONFIG_FILE"
    echo "# UART Configuration" >> "$CONFIG_FILE"
    echo "enable_uart=1" >> "$CONFIG_FILE"
    echo "dtparam=uart0=on" >> "$CONFIG_FILE"
    echo "dtparam=uart1=off" >> "$CONFIG_FILE"
    echo "dtoverlay=disable-bt" >> "$CONFIG_FILE"
    
    echo "Updated config.txt with UART settings (backup saved)"
fi

# Remove serial console from cmdline.txt
if [ -f "$CMDLINE_FILE" ]; then
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak"
    sed -i 's/console=ttyAMA0,[0-9]\+ //g' "$CMDLINE_FILE"
    sed -i 's/console=serial0,[0-9]\+ //g' "$CMDLINE_FILE"
    echo "Updated cmdline.txt (backup saved)"
fi

# Add user to dialout group
if ! groups $SUDO_USER | grep -q dialout; then
    usermod -a -G dialout $SUDO_USER
    echo "Added $SUDO_USER to dialout group (will take effect after next login)"
fi

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, check: ls -l /dev/serial0"
