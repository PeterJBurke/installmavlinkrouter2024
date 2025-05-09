#!/bin/bash

# Test script to verify serial port configuration
# Copyright Peter Burke 2024

echo "Starting serial port configuration test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "Checking current serial port status:"

echo "1. Checking for serial device:"
ls -l /dev/serial* 2>/dev/null || echo "No serial devices found"

echo -e "\n2. Checking if user is in dialout group:"
groups $SUDO_USER | grep -q dialout
if [ $? -eq 0 ]; then
    echo "User $SUDO_USER is in dialout group"
else
    echo "Adding user $SUDO_USER to dialout group..."
    usermod -a -G dialout $SUDO_USER
    echo "User added to dialout group. This will take effect after next login."
fi

echo -e "\n3. Checking UART configuration:"
if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE="/boot/firmware/config.txt"
else
    CONFIG_FILE="/boot/config.txt"
fi

if [ -f "$CONFIG_FILE" ]; then
    if grep -q "^enable_uart=1" "$CONFIG_FILE"; then
        echo "UART is enabled in $CONFIG_FILE"
    else
        echo "UART is not enabled in $CONFIG_FILE"
        echo "To enable UART, add 'enable_uart=1' to $CONFIG_FILE"
    fi
fi

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, you can test the serial port using: ls -l /dev/serial0"
