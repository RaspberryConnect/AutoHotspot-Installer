RaspberryConnect.com
This installer script and the autohotspot & autohotspotN scripts can be shared and modified but all references to RaspberryConnect.com must be kept in place.


AutoHotspot Setups:
This script is for installing a Raspberry Pi WiFi setup where the Pi will connect to a previously configured Wifi network when the Pi is in range of the router or Automatically setup a Raspberry Pi access point when a known wifi network is not in range.
This can also be run manually or with a timer to switch between a WiFi network or a WifI access point without a reboot.

There are two setups available:
1: Network/Internet access available for connected devices when an ethernet cable is connected for the Raspberry Pi's 3A,3B,3B+ & 4. For Rapberry Pi's A,B, B+,& 2 if an usb Wifi adapter is used.
2: No internet access for connected devices. Designed for the Raspberry Pi Zero W or other Raspberry PI's where only a direct connection to the PI from a phone, tablet or Laptop is required.

There is also a setup for permanent access point with network/internet access from eth0 for WiFi connected devices.

For more information and for the manual setup's see:
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/157-raspberry-pi-auto-wifi-hotspot-switch-internet
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/158-raspberry-pi-auto-wifi-hotspot-switch-direct-connection
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/168-raspberry-pi-hotspot-access-point-dhcpcd-method

This script will install any of these three setups or allow you to change between setup types.
In additionm the Access Point SSID and Password can be changed, new WiFi networks can be added to the Raspberry PI while in access point mode. The Pi can be forced between WiFi Network mode and Access Point mode without a reboot. Also there is an uninstaller.

To use the installer:

Download the AutoHotspot-Setup.tar.xz archive from
curl "https://www.raspberryconnect.com/images/hsinstaller/AutoHotspot-Setup.tar.gz" -o AutoHotspot-Setup.tar.gz

Unarchive the file to the curent folder using the command
tar -xzvf AutoHotspot-Setup.tar.xz
If you are using the Desktop then right click on the AutoHotspot-Setup.tar.xz and select Extract Here

open a terminal window and navigate to the Autohotspot folder. If this is in your home directory then use 
cd Autohotspot
if this is your desktop then use 
cd ./Desktop/Autohotspot
Run the script with the command
sudo ./autohotspot-setup.sh
This script will fail if sudo is not used.

You will presented with a menu with these options

 1 = Install Autohotspot with eth0 access for Connected Devices
 2 = Install Autohotspot with No eth0 for connected devices
 3 = Install a Permanent Access Point with eth0 access for connected devices
 4 = Uninstall Autohotspot or permanent access point
 5 = Add a new wifi network to the Pi (SSID) or update the password for an existing one.
 6 = Autohotspot: Force to an access point or connect to WiFi network if a known SSID is in range
 7 = Change the access points SSID and password
 8 = Exit

Option 1: Install Autohotspot with eth0 access for Connected Devices 
Once installed and after a reboot the Raspberry Pi will connect to a router that has previously been connected to and is listed in /etc/wpa_supplicant/wpa_supplicant.conf. If no router is in range then it will generate a WiFi access point.
This will have an SSID of RPiHotspot and password of 1234567890
Use option 7 to change the access point password and also the SSID if required
If an ethernet cable is connected to the Pi with access to the internet then it will allow devices connected to the access point to connect to the internet or local network.
Once a connection to the access point has been made you can access the Raspberry Pi via ssh & VNC with
ssh pi@192.168.50.5
vnc: 192.168.50.5::5900
for webservers use http://192.168.50.5/

Option 2: Install Autohotspot with No eth0 for connected devices
This option is similar to option 1 but connected devices have no network/internet connection if an ethernet cable is connected. 
The Pi itself can use the eth0 connection and also be accessed from a device on the etho network.
This has been designed so you can access only the Pi from a Laptop, tablet or phone.
The access point SSID will be RPiHotspot with a password of 1234567890
Once a connection to the access point has been made you can access the Raspberry Pi via ssh & VNC with
ssh pi@10.0.0.5
vnc: 10.0.0.5::5900
for webservers use http://10.0.0.5/

Option 3: Install a Permanent Access Point with eth0 access for connected devices
This is for a permanent WiFi access point with network/internet access for connected devices.
The Raspberry Pi will only have network and internet access when an ethernet cable is connected.
Once a connection to the access point has been made, you can access the Raspberry Pi via ssh & VNC with
ssh pi@192.168.50.10
vnc: 192.168.50.10::5900
for webservers use http://192.168.50.10/

Additional setup is required if you wanted to use a second WiFi device to connect to a network or internet rather than a ethernet conection. 
This requires changing the references in the iptables or fftables files from eth0 to wlan1
/etc/iptables-hs    (PiOS version 10 or lower , Buster)
/etc/nftables/nft-stat-ap.nft (PiOS version 11 or higher, Bullseye)

Option 4: Uninstall Autohotspot or Permanent Access Point
This will disable the setup of any of the three setups and return the Raspberry Pi to default Wifi settings.
Hostapd & dnsmasq will not be uninstalled just disabled.

Option 5: Add a new wifi network to the Pi (SSID) or update the password for an existing one.
If you are using either of the autohotspot setups in access point mode and wish to connect to a local WiFi network. You will be unable to scan for any networks as the desktop wifi option will be disabled, shown as red crosses. You can manually add the details to /etc/wpa_supplicant/wpa_supplicant.conf if you know them. 
This option will allow you to scan for local WiFi networks and update the Pi. If you then reboot or use the Force... option 6 ,see below. 
This option only works for WiFi networks where only a password is required. If a username is required this will not work.

Option 6: Autohotspot: Force to an access point or Force to WiFi network if a known SSID is in range
This option is only for the Autohotspot setups.
If you are at home and connected to your home network but would like to use the hotspot. This option will force the pi to access point mode and will ignore your home network untill the next reboot. If you use this option again while in access point mode, it will attempt to connect to a known WiFi network. This will go back to the access point if no valid WiFi network is found or there is a connection issue.
 
Option 7: Change the Pi's access point SSID and Password
By default the access point SSID is RPiHotSpot with a password of 1234567890. Use this option to change either or both SSID and Password.
You will be prompted to change both but if you make no entry and press enter the existing setting will be kept.
The password must be at least 8 characters. 

Option 8: Exit
Exit the script.


/etc/network/interfaces file:
many older access points and network setup guides online add entries to the /etc/network/interfaces file. This file is depreciated in Raspbian & PiOS. Any entry in this file is not compatible with these setups. This installer backup and remove any entries found in this file. They will be restored if the uninstall option is used.

RaspberryConnect.com

Jan 29th 2022
