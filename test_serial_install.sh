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

echo "1. Configuring UART in $CONFIG_FILE..."
if [ -f "$CONFIG_FILE" ]; then
    # Enable UART
    if ! grep -q "^enable_uart=1" "$CONFIG_FILE"; then
        echo "enable_uart=1" >> "$CONFIG_FILE"
        echo "Added enable_uart=1 to $CONFIG_FILE"
    else
        echo "UART already enabled in $CONFIG_FILE"
    fi
    
    # Add dtoverlay for uart if not present
    if ! grep -q "^dtoverlay=uart" "$CONFIG_FILE"; then
        echo "dtoverlay=uart0" >> "$CONFIG_FILE"
        echo "Added dtoverlay=uart0 to $CONFIG_FILE"
    else
        echo "UART dtoverlay already configured"
    fi
fi

echo "\n2. Configuring cmdline in $CMDLINE_FILE..."
if [ -f "$CMDLINE_FILE" ]; then
    sed -i 's/console=serial0,115200 //g' "$CMDLINE_FILE"
    echo "Removed serial console from $CMDLINE_FILE"
fi

echo "\n3. Adding user to dialout group..."
if ! groups $SUDO_USER | grep -q dialout; then
    usermod -a -G dialout $SUDO_USER
    echo "Added $SUDO_USER to dialout group (will take effect after next login)"
else
    echo "User $SUDO_USER is already in dialout group"
fi

echo "\n4. Current configuration status:"
echo "=== Config file ($CONFIG_FILE) ==="
grep "uart" "$CONFIG_FILE" || echo "No UART configuration found"

echo "\n=== Cmdline file ($CMDLINE_FILE) ==="
cat "$CMDLINE_FILE" || echo "Could not read cmdline file"

echo "\n=== Serial devices ==="
ls -l /dev/serial* 2>/dev/null || echo "No serial devices found"

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, you can test the serial port using: ls -l /dev/serial0"
