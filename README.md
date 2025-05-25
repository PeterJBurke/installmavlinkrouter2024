# Outline

This installs Mavlink-Router.
It also connects to the flight controller over serial using Mavlink protocol, assuming a UART connection to the flight controller.
Tested in 2024 on Raspberry Pi Zero W 2 with Bookworm version of Raspbian OS.

## Target hardware/prerequisites

* SD Card
* Raspberry Pi Zero W 2
* Matek or similar flight controller configured for telemetry at 57,600 baud in Ardupilot
* UART cable from flight controller to Pi Zero W 2

## Installing

Download and install Raspbian Bookworm from:
```
https://www.raspberrypi.org/downloads/raspbian/
```
Follow the instructions here to copy the image to an sd card.


Boot Pi with SD and ssh into the Pi.


Get the script to install and configure the Pi:
```
wget -O install.sh https://raw.githubusercontent.com/PeterJBurke/installmavlinkrouter2024/refs/heads/main/install.sh
```
Run script (takes about 10-15 minutes to run on a Pi Zero 2 W, or less than a minute if MAVLink Router is already installed):
```
sudo chmod 777 ~/install.sh; 
sudo ~/install.sh 2>&1 | tee MavlinkRouterBuildlog.txt 
```

After the installation completes, reboot your system:
```
sudo reboot
```

Done!

## Testing Your Installation

### 1. Checking Service Status
First, verify that the MAVLink Router service is running properly:

Check service status:
```
systemctl status mavlink-router
```

View service logs:
```
journalctl -u mavlink-router
```

Monitor logs in real-time:
```
journalctl -u mavlink-router -f
```

### 2. Testing with Command Line
You can test the connection manually using mavproxy:
```
sudo -s mavproxy.py --master=/dev/Serial0 --baudrate 57600
```

Or directly invoke mavlink-router:
```
mavlink-routerd
```

### 3. Testing with Mission Planner
1. Make sure your computer is on the same local network as the Raspberry Pi
2. In Mission Planner, use `PI_IP_ADDRESS:5678` as the TCP connection address (replace PI_IP_ADDRESS with your Pi's actual IP address)
3. Mission Planner should connect to your drone through the MAVLink Router

### 4. Verifying Configuration Files
Check that these configuration files were created properly:
* `/etc/mavlink-router/main.conf` - Contains port settings (UART via /dev/Serial0 and TCP on localhost:5678)

## How it works:

The script first checks if MAVLink Router is already installed. If it is, it will skip the download and compilation steps to save time.

If not already installed, the script installs required packages using apt-get install, including:
* Basic development tools (git, gcc, etc.)
* Serial support packages (raspi-config, minicom, screen)
* MAVLink router dependencies

During installation, the script will:
* Automatically enable the serial port
* Disable serial console (to free up the port for MAVLink)
* Add the user to the dialout group for serial port access

It downloads mavlink-router source code from git hub, compiles it. (Version 2.0)

mavlink-router is what it says: it passes mavlink packets from one place to another.

It downloads these files file (from this repo) for automatically running mavlink-router and the ssh:
* /etc/main.conf has the parameters for the ports (connects to flight controller on UART via /dev/Serial0 and opens Mavlink stream on TCP localhost:5678)

## Authors

* **Peter Burke** - *Initial work*

## License

This project is licensed under the GNU License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

* Thanks to the developers of mavlink-router and Ardupilot.
