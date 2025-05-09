#!/bin/bash

# Copyright Peter Burke 11/3/2024

# define functions first


function installstuff {
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Installing packages and configuring serial port..."

    start_time_installstuff="$(date -u +%s)"
  
    echo "export PROMPT_COMMAND='history -a'" | sudo tee -a /etc/bash.bashrc
    time sudo apt-get -y update
    time sudo apt-get -y install git meson ninja-build pkg-config gcc g++ systemd

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
    echo "Downloading git clone of mavlink-router..."
    #Download the git clone:                                                                                        

    # Remove existing directory if it exists
    [ -d "mavlink-router" ] && rm -rf mavlink-router

    git clone https://github.com/intel/mavlink-router.git
    cd mavlink-router
    sudo git submodule update --init --recursive

    echo "Done downloading git clone of mavlink-router..."

    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Start making / compiling / building mavlink-router..."
    meson setup build .


    #Make it                                                                                                        
    ninja -j 1 -C build
    sudo ninja -C build install
    
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
