#!/bin/bash

# Copyright Peter Burke 11/3/2024

# Function to check if the system can use the pre-compiled binary
check_architecture() {
    local arch
    arch=$(uname -m)
    
    # Check if the system is 64-bit ARM (aarch64)
    if [ "$arch" = "aarch64" ]; then
        # Check if we're running on a Raspberry Pi
        if grep -q "Raspberry Pi" /proc/device-tree/model 2>/dev/null; then
            echo "aarch64"
            return 0
        fi
    fi
    
    echo "unsupported"
    return 1
}

# Function to download and install the pre-compiled binary
install_precompiled() {
    local arch=$1
    local version="main"  # Using main branch for now, change to tag when you create a release
    
    echo "Downloading pre-compiled binary for $arch..."
    
    # Create installation directory
    sudo mkdir -p /usr/local/bin
    sudo mkdir -p /etc/mavlink-router
    
    # Download the binary from the bin directory in the repo
    local repo_url="https://raw.githubusercontent.com/PeterJBurke/installmavlinkrouter2024"
    local binary_url="$repo_url/$version/bin/raspberrypi-$arch/mavlink-routerd"
    
    if ! curl -L -o /tmp/mavlink-routerd "$binary_url"; then
        echo "Failed to download pre-compiled binary. Falling back to compilation."
        return 1
    fi
    
    # Install the binary
    sudo install -m 755 /tmp/mavlink-routerd /usr/local/bin/
    rm -f /tmp/mavlink-routerd
    
    echo "Successfully installed pre-compiled mavlink-routerd"
    return 0
}

# Function to build from source
build_from_source() {
    echo "Building mavlink-router from source..."
    
    # Install build dependencies
    sudo apt-get update
    sudo apt-get install -y git meson ninja-build pkg-config gcc g++
    
    # Clone and build
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1
    
    git clone https://github.com/intel/mavlink-router.git
    cd mavlink-router
    git submodule update --init --recursive
    
    meson setup build .
    ninja -C build
    sudo ninja -C build install
    
    # Clean up
    cd /tmp || exit 1
    rm -rf "$temp_dir"
}

function installstuff {
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Installing packages and configuring serial port..."

    start_time_installstuff="$(date -u +%s)"
  
    echo "export PROMPT_COMMAND='history -a'" | sudo tee -a /etc/bash.bashrc
    time sudo apt-get -y update
    time sudo apt-get -y install git meson ninja-build pkg-config gcc g++ systemd curl

    # Set configuration paths for Ubuntu on Raspberry Pi
    CONFIG_FILE="/boot/firmware/config.txt"
    CMDLINE_FILE="/boot/firmware/cmdline.txt"

    echo "Configuring serial port..."
    # Configure UART in config.txt
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        
        # Remove existing uart settings
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

    echo "Serial port configuration complete. Reboot required for changes to take effect."

    end_time_installstuff="$(date -u +%s)"
    elapsed_installstuff="$(($end_time_installstuff-$start_time_installstuff))"
    echo "Total of $elapsed_installstuff seconds elapsed for installation and configuration"
    # 38 mins
    
    
}

function downloadandbuildmavlinkrouter {
    # Check if mavlink-router is already installed
    if command -v mavlink-routerd &> /dev/null && systemctl is-enabled mavlink-router &> /dev/null; then
        echo "MAVLink Router is already installed and service is configured."
        echo "Skipping download and build to save time."
        echo "If you want to force a reinstall, please remove mavlink-routerd and disable the service first."
        return 0
    fi

    start_time_downloadandbuildmavlinkrouter="$(date -u +%s)"
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    
    # Check architecture
    local arch
    arch=$(check_architecture)
    
    # Try to install pre-compiled binary if architecture is supported
    if [ "$arch" != "unsupported" ]; then
        echo "Detected compatible architecture: $arch"
        if install_precompiled "$arch"; then
            echo "Successfully installed pre-compiled binary for $arch"
            return 0
        fi
        echo "Falling back to source compilation..."
    else
        echo "No pre-compiled binary available for this architecture. Compiling from source..."
    fi

    # Fall back to building from source
    build_from_source
    
    echo "Done making / compiling / building mavlink-router..."

    end_time_downloadandbuildmavlinkrouter="$(date -u +%s)"
    elapsed_downloadandbuildmavlinkrouter="$(($end_time_downloadandbuildmavlinkrouter-$start_time_downloadandbuildmavlinkrouter))"
    echo "Total of $elapsed_downloadandbuildmavlinkrouter seconds elapsed for downloading and building mavlink router"
    # 13 min

}


# Check for any errors, quit if any
check_errors() {
  if ! [ $? = 0 ]
  then
    echo "An error occured! Aborting...."
    exit 1
  fi
}

function fxyz {
    echo "doing function fxyz"
}


function configuremavlinkrouter {
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Start configuring mavlink-router..."
    echo "It will connect to flight controller on /dev/AMA0"
    echo "It will serve up a mavlink stream on localhost port 5678 TCP"


    #Configure it                                                                                                   

    if [ ! -d "/etc/mavlink-router" ] 
    then
        echo "Directory /etc/mavlink-router does not exist yet. Making it." 
        sudo mkdir /etc/mavlink-router
        echo "Made /etc/mavlink-router" 
    fi

    cd /etc/mavlink-router
    # wget main.conf #  for mavlink-router configuration
    wget https://raw.githubusercontent.com/PeterJBurke/installmavlinkrouter2024/refs/heads/main/main.conf -O /etc/mavlink-router/main.conf
    sudo chmod 777 main.conf
    echo "Done configuring mavlink-router..."

}




#***********************END OF FUNCTION DEFINITIONS******************************

set -x

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "This will install mavlink router and set it up for you."


echo "Starting..."

date


start_time="$(date -u +%s)"

installstuff

downloadandbuildmavlinkrouter
                                                            
configuremavlinkrouter

#enable the mavlink router service and start it
sudo systemctl enable mavlink-router
sudo systemctl start mavlink-router

date

end_time="$(date -u +%s)"

elapsed="$(($end_time-$start_time))"
echo "Total of $elapsed seconds elapsed for the entire process"


echo "Installation is complete."
echo "A reboot is required to ensure all changes take effect (especially for serial port configuration)."
echo "Please reboot your system with 'sudo reboot' after this script finishes."
echo "Closing..."
