# Outline

This installs Mavlink-Router.
It also connects to the flight controller over serial using Mavlink protocol, assuming a UART connection to the flight controller.
Tested in 2024 on Raspberry Pi Zero W 2 with Bookworm version of Raspbian OS.

## Target hardware/prerequisites

* SD Card
* Raspberry Pi Zero W 2
* Matek or similar flight controller configured for telemetry at 57,600 baud in Ardupilot
* UART cable from flight controller to Pi Zero W 2


It assumes /home/pi is your home directory.

## Installing

Download and install Raspbian Bookworm from:
```
https://www.raspberrypi.org/downloads/raspbian/
```
Follow the instructions here to copy the image to an sd card.


Boot Pi with SD.

Get the script to install and configure the Pi:
```
wget https://gitlab.com/pjbca/4guav/raw/master/MavlinkRouterBuild/MavlinkRouterBuild.sh
```

Run script (takes about an hour to run):
```
sudo chmod 777 ~/MavlinkRouterBuild.sh; 
sudo ~/MavlinkRouterBuild.sh 2>&1 | tee MavlinkRouterBuildlog.txt 
```



Done!

To confirm it works:
* Connect to flight controller over serial (see schematics) and confirm it connects to the mavproxy router by monitoring it's screen (see below).

## How it works:

The script installs a whole bunch of packages using apt-get install.

It downloads mavlink-router source code from git hub, compiles it. (Version 2.0)

mavlink-router is what it says: it passes mavlink packets from one place to another.

It downloads these files file (from this repo) for automatically running mavlink-router and the ssh:
* /etc/main.conf has the parameters for the ports (connects to flight controller on UART via /dev/Serial0 and opens Mavlink stream on TCP localhost:5678)

## How to test it:

### How to check the status of mavlink-router service:
Check status of the service:
```
systemctl status mavlink-router
```

Check logs of the service:
```
journalctl -u mavlink-router
```

Check logs of the service with end updated dyamically:
```
journalctl -u mavlink-router -f
```


### Manual testing:

Test connection manually to UAV with mavproxy:
```
sudo -s mavproxy.py --master=/dev/Serial0 --baudrate 57600
```


To manually invoke mavlink-router:

```
cd ~/mavlink-router
/.mavlink-routerd # (will use main.conf file)
```
or
```
mavlink-routerd
```

### Check all the configuration files:
The following configuration files are created/modified during the build. You can check to see if they were created properly with the correct content:

* /home/pi/MavlinkRouterBuild.sh
* /etc/mavlink-router/main.conf has the parameters for the ports (connects to flight controller on UART via /dev/AMA0 and opens Mavlink stream on TCP localhost:5678)
* 

## Authors

* **Peter Burke** - *Initial work* - 

## License

This project is licensed under the GNU License - see the [LICENSE.txt](LICENSE.txt) file for details

## Acknowledgments

 * Thanks to the developers of mavlink-router and Ardupilot.
