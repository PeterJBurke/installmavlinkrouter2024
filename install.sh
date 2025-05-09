#!/bin/bash

# Copyright Peter Burke 11/3/2024

# define functions first


function installstuff {
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "Installing a whole bunch of packages..."

    start_time_installstuff="$(date -u +%s)"
  
    echo "export PROMPT_COMMAND='history -a'" | sudo tee -a /etc/bash.bashrc
    time sudo apt-get -y update # 1 min   #Update the list of packages in the software center                                   
    time sudo apt-get -y full-upgrade # 3.5 min
    # time sudo apt-get -y install screen # 0.5 min
    time sudo apt-get -y install git # 0 min
    time sudo apt-get -y install git meson ninja-build pkg-config gcc g++ systemd
    # Install serial support packages
    time sudo apt-get -y install raspi-config
    time sudo apt-get -y install minicom screen

    # Enable serial port
    sudo raspi-config nonint do_serial 2  # Enable serial port but disable serial console
    # Add user to dialout group for serial access
    sudo usermod -a -G dialout $USER

    echo "Done installing a whole bunch of packages..."


    end_time_installstuff="$(date -u +%s)"
    elapsed_installstuff="$(($end_time_installstuff-$start_time_installstuff))"
    echo "Total of $elapsed_installstuff seconds elapsed for installing packages"
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
