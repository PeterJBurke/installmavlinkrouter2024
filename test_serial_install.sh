#!/bin/bash

# Test script to verify serial port configuration
# Copyright Peter Burke 2024

echo "Starting serial port configuration test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Checking and configuring serial port..."

# Determine system configuration paths
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
    CMDLINE_FILE="/boot/firmware/cmdline.txt"
else
    CONFIG_FILE="/boot/config.txt"
    CMDLINE_FILE="/boot/cmdline.txt"
fi

echo "1. Checking current configuration..."
echo "=== Current config.txt ==="
cat "$CONFIG_FILE"

echo "\n=== Current cmdline.txt ==="
cat "$CMDLINE_FILE"

echo "\n2. Configuring UART..."
# First, disable Bluetooth to free up the PL011 UART
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
    
    # Add our UART configuration
    echo "" >> "$CONFIG_FILE"
    echo "# UART Configuration" >> "$CONFIG_FILE"
    echo "enable_uart=1" >> "$CONFIG_FILE"
    echo "dtoverlay=disable-bt" >> "$CONFIG_FILE"
    
    echo "Updated config.txt with UART settings (backup saved as ${CONFIG_FILE}.bak)"
fi

# Disable serial console in cmdline.txt
if [ -f "$CMDLINE_FILE" ]; then
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak"
    sed -i 's/console=ttyAMA0,[0-9]\+ //' "$CMDLINE_FILE"
    sed -i 's/console=serial0,[0-9]\+ //' "$CMDLINE_FILE"
    echo "Updated cmdline.txt (backup saved as ${CMDLINE_FILE}.bak)"
fi

echo "\n3. Adding user to dialout group..."
if ! groups $SUDO_USER | grep -q dialout; then
    usermod -a -G dialout $SUDO_USER
    echo "Added $SUDO_USER to dialout group (will take effect after next login)"
else
    echo "User $SUDO_USER is already in dialout group"
fi

echo "\n4. Current status:"
echo "=== Updated config.txt ==="
cat "$CONFIG_FILE"

echo "\n=== Updated cmdline.txt ==="
cat "$CMDLINE_FILE"

echo "\n=== Current serial devices ==="
ls -l /dev/tty* | grep -E 'serial|AMA|USB' || echo "No serial devices found"

echo "\n=== Bluetooth status ==="
systemctl status bluetooth || echo "Bluetooth service not found"

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, you can test the serial port using: ls -l /dev/serial0 and ls -l /dev/ttyAMA0"
