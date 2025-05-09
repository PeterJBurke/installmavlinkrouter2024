#!/bin/bash

# Test script to verify serial port configuration
# Copyright Peter Burke 2024

echo "Starting serial port configuration test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "1. Removing serial console from cmdline.txt..."
if [ -f /boot/firmware/cmdline.txt ]; then
    sed -i 's/console=serial0,115200 //g' /boot/firmware/cmdline.txt
    echo "Updated /boot/firmware/cmdline.txt"
else
    echo "Warning: /boot/firmware/cmdline.txt not found"
fi

echo "2. Enabling UART in config.txt..."
if [ -f /boot/firmware/config.txt ]; then
    if ! grep -q "^enable_uart=1" /boot/firmware/config.txt; then
        echo "enable_uart=1" >> /boot/firmware/config.txt
        echo "Added enable_uart=1 to config.txt"
    else
        echo "UART already enabled in config.txt"
    fi
else
    echo "Warning: /boot/firmware/config.txt not found"
fi

echo "3. Adding current user to dialout group..."
usermod -a -G dialout $SUDO_USER

echo "4. Verifying changes..."
echo "Contents of /boot/firmware/cmdline.txt:"
cat /boot/firmware/cmdline.txt
echo -e "\nChecking for enable_uart in /boot/firmware/config.txt:"
grep "enable_uart" /boot/firmware/config.txt
echo -e "\nChecking dialout group membership:"
groups $SUDO_USER | grep dialout

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, you can test the serial port using: ls -l /dev/serial0"
