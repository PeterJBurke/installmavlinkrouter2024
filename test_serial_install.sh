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
sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt

echo "2. Enabling UART in config.txt..."
if ! grep -q "^enable_uart=1" /boot/config.txt; then
    echo "enable_uart=1" >> /boot/config.txt
    echo "Added enable_uart=1 to config.txt"
else
    echo "UART already enabled in config.txt"
fi

echo "3. Adding current user to dialout group..."
usermod -a -G dialout $SUDO_USER

echo "4. Verifying changes..."
echo "Contents of /boot/cmdline.txt:"
cat /boot/cmdline.txt
echo -e "\nChecking for enable_uart in /boot/config.txt:"
grep "enable_uart" /boot/config.txt
echo -e "\nChecking dialout group membership:"
groups $SUDO_USER | grep dialout

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, you can test the serial port using: ls -l /dev/serial0"
