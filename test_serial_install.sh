#!/bin/bash

# Test script to verify serial port configuration
# Copyright Peter Burke 2024

echo "Starting serial port configuration test..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "System Information:"
uname -a

echo "\nRaspberry Pi Hardware Info:"
if [ -f /proc/cpuinfo ]; then
    echo "=== CPU Info ==="
    cat /proc/cpuinfo | grep -E 'model|Model'
    echo "\n=== Hardware ==="
    cat /proc/cpuinfo | grep Hardware
    echo "\n=== Revision ==="
    cat /proc/cpuinfo | grep Revision
fi

echo "\nChecking and configuring serial port..."

# Force configuration paths for Ubuntu on Raspberry Pi
CONFIG_FILE="/boot/firmware/config.txt"
CMDLINE_FILE="/boot/firmware/cmdline.txt"

echo "1. Diagnostic Information:"
echo "=== Looking for config files ==="
ls -l /boot/firmware/config.txt /boot/firmware/cmdline.txt /boot/config.txt /boot/cmdline.txt 2>/dev/null

echo "\n=== Current TTY Devices ==="
ls -l /dev/tty* 2>/dev/null | grep -E 'serial|AMA|USB'

echo "\n=== GPIO UART Status ==="
raspi-gpio get | grep -E "GPIO14|GPIO15" || echo "raspi-gpio not available"

echo "\n=== Current config.txt ==="
if [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
else
    echo "Config file not found at $CONFIG_FILE"
fi

echo "\n=== Current cmdline.txt ==="
if [ -f "$CMDLINE_FILE" ]; then
    cat "$CMDLINE_FILE"
else
    echo "Cmdline file not found at $CMDLINE_FILE"
fi

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
    echo "Created backup at ${CONFIG_FILE}.bak"
    
    # Remove any existing uart-related settings
    sed -i '/^enable_uart=/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=uart/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=pi3-disable-bt/d' "$CONFIG_FILE"
    sed -i '/^dtoverlay=disable-bt/d' "$CONFIG_FILE"
    sed -i '/^dtparam=uart0=/d' "$CONFIG_FILE"
    sed -i '/^dtparam=uart1=/d' "$CONFIG_FILE"
    
    # Add our UART configuration
    echo "" >> "$CONFIG_FILE"
    echo "# UART Configuration" >> "$CONFIG_FILE"
    echo "enable_uart=1" >> "$CONFIG_FILE"
    echo "dtparam=uart0=on" >> "$CONFIG_FILE"
    echo "dtparam=uart1=off" >> "$CONFIG_FILE"
    echo "dtoverlay=disable-bt" >> "$CONFIG_FILE"
    
    echo "Updated config.txt with UART settings"
fi

# Disable serial console in cmdline.txt
if [ -f "$CMDLINE_FILE" ]; then
    cp "$CMDLINE_FILE" "${CMDLINE_FILE}.bak"
    echo "Created backup at ${CMDLINE_FILE}.bak"
    sed -i 's/console=ttyAMA0,[0-9]\+ //g' "$CMDLINE_FILE"
    sed -i 's/console=serial0,[0-9]\+ //g' "$CMDLINE_FILE"
    echo "Updated cmdline.txt"
fi

echo "\n3. Adding user to dialout group..."
if ! groups $SUDO_USER | grep -q dialout; then
    usermod -a -G dialout $SUDO_USER
    echo "Added $SUDO_USER to dialout group (will take effect after next login)"
else
    echo "User $SUDO_USER is already in dialout group"
fi

echo "\n4. Final Configuration Status:"
echo "=== Updated config.txt ==="
if [ -f "$CONFIG_FILE" ]; then
    cat "$CONFIG_FILE"
fi

echo "\n=== Updated cmdline.txt ==="
if [ -f "$CMDLINE_FILE" ]; then
    cat "$CMDLINE_FILE"
fi

echo "\n=== Raspberry Pi Model ==="
cat /proc/cpuinfo | grep Model

echo "\n=== Loaded Kernel Modules ==="
lsmod | grep -E 'uart|serial|bluetooth'

echo "\n=== Device Tree Status ==="
ls -l /proc/device-tree/soc/serial* 2>/dev/null || echo "No serial devices in device tree"

echo "\n=== UART Overlay Status ==="
ls -l /sys/firmware/devicetree/base/soc/serial* 2>/dev/null || echo "No UART overlays found"

echo "\n=== Debug Output ==="
dmesg | grep -i "serial"
dmesg | grep -i "uart"

echo -e "\nConfiguration complete!"
echo "NOTE: A reboot is required for changes to take effect."
echo "After reboot, check:"
echo "1. ls -l /dev/serial0"
echo "2. ls -l /dev/ttyAMA0"
echo "3. ls -l /proc/device-tree/soc/serial*"
echo "4. dmesg | grep -i serial"
