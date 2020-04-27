RaspberryConnect.com
This installer script, the autohotspot and autohotspotN scripts can be shared and modified but all references to RaspberryConnect.com must be kept in place.

AutoHotspot Setups:
This script is for installing a Raspberry Pi WiFi setup where the Pi will connect to a previously configured Wifi network when the Pi is in range of the router or Automatically setup a Raspberry Pi Hotspot/access point when a known wifi network is not in range.
This can also be run manually or with a timer to switch without a reboot.

This is available in two setups:
1: Internet access available for connected devices when a Ethernet cable is connected for the Raspberry Pi's 3A,3B,3B+ & 4. For Rapberry Pi's A,B, B+,& 2 if an usb Wifi adapter is used.
2: No internet access for connected devices. Designed for the Raspberry Pi Zero W or other Raspberry PI's where only a direct connection to the PI from a phone, tablet or Laptop is required.

There is also setup for permanent hotspot with internet access for connected devices.

For more information and for the manual setup's see:
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/157-raspberry-pi-auto-wifi-hotspot-switch-internet
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/158-raspberry-pi-auto-wifi-hotspot-switch-direct-connection
https://www.raspberryconnect.com/projects/65-raspberrypi-hotspot-accesspoints/168-raspberry-pi-hotspot-access-point-dhcpcd-method

This script will install any of these three setups or allow you to change between setup types.
In addition the Hotspot SSID and Password can be changed, new WiFi networks can be added to the Raspberry PI while in Hotspot Mode. The Pi can be forced between Network mode and Hotspot mode without a reboot. Also there is an uninstaller.

To use the installer:

Download the AutoHotspot-Setup.tar.xz archive from
curl "https://www.raspberryconnect.com/images/hsinstaller/AutoHotspot-Setup.tar.gz" -o AutoHotspot-Setup.tar.gz
Unarchive the file to the curent folder using the command
tar -xzvf AutoHotspot-Setup.tar.xz
If you are using the Desktop then right click on the AutoHotspot-Setup.tar.xz and select Extract Here

open a terminal screen and navigate to the Autohotspot folder. If this is in your home directory then use 
cd Autohotspot
if this is your desktop then use 
cd ./Desktop/Autohotspot
Run the script with the command
sudo ./autohotspot-setup.sh
This script will fail if sudo is not used.

You will presented with a menu with these options

 1 = Install Autohotspot with Internet for Connected Devices
 2 = Install Autohotspot with No Internet for connected devices
 3 = Install a Permanent Hotspot with Internet for connected devices
 4 = Uninstall Autohotspot or Permanent Hotspot
 5 = Add or Change a WiFi network (SSID)
 6 = Autohotspot: Force to a Hotspot or Force to Network if SSID in Range
 7 = Change the Hotspots SSID and Password
 8 = Exit

Option 1: Install Autohotspot with Internet for Connected Devices 
Once installed and after a reboot the Raspberry Pi will connect to a router that has previously been connected to and is listed in /etc/wpa_supplicant/wpa_supplicant.conf. If no router is in range then it will generate a WiFi hotspot.
This will have an SSID of RPiHotspot and password of 1234567890
Use option 7 to change the password and also the SSID if required
If an ethernet cable is connected to the Pi with access to the internet then it will allow devices connected to the hotspot access to the internet or local network.
Once a connection to the hotspot has been made you can access the Raspberry Pi via ssh & VNC with
ssh pi@192.168.50.5
vnc: 192.168.50.5::5900
for webservers use http://192.168.50.5/

Option 2: Install Autohotspot with No Internet for connected devices
This option is similar to option 1 but connected devices have no internet connection if an ethernet cable is connected. 
This has been designed so you can access only the Pi from a Laptop, tablet or phone.
The hotspot SSID will be RPiHotspot with a password of 1234567890
Once a connection to the hotspot has been made you can access the Raspberry Pi via ssh & VNC with
ssh pi@10.0.0.5
vnc: 10.0.0.5::5900
for webservers use http://10.0.0.5/

Otion 3: Install a Permanent Hotspot with Internet for connected devices
This is for a permanent WiFi hotspot with internet access for connected devices.
The Raspberry Pi will only have network or internet access when an ethernet cable is connected.
Once a connection to the hotspot has been made you can access the Raspberry Pi via ssh & VNC with
ssh pi@192.168.50.10
vnc: 192.168.50.10::5900
for webservers use http://192.168.50.10/

Additional setup is required if you wanted to use a second WiFi device to connect to the internet rather than a ethernet conection. This will be a future option.

Option 4: Uninstall Autohotspot or Permanent Hotspot
This will disable the setup of any of the three setups and return the Raspberry Pi to default Wifi settings.
Hostapd & dnsmasq will not be uninstalled just disabled.

Option 5: Add or Change a WiFi network (SSID)
If you are using either of the autohotspot setups in hotspot modes and wish to connect to a local WiFi network. You will be unable to scan for any networks as the desktop wifi option will be disabled, shown as red crosses. You can manually add the details to /etc/wpa_supplicant/wpa_supplicant.conf if you know them. 
This option will allow you to scan for local WiFi networks and update the Pi. If you then reboot or use the Force... option ,see below. 
This option only works for WiFi networks where only a password is required. If a username is required this will not work. (Future update)

Option 6: Autohotspot: Force to a Hotspot or Force to Network if SSID in Range
This option is only for the Autohotspot setups.
If you are at home and connected to your home network but would like to use the hotspot. This option will force the pi to hotspot mode and will ignore your home network untill the next reboot. If you use this option again while in hotspot mode it will attempt to connect to a known network. This will go back to the hotspot if no valid WiFi network is found or there is a connection issue.
 
Option 7: Change the Hotspots SSID and Password
By default the hotspot ssid is RPiHotSpot with a password of 1234567890. Use this option to change either or both SSID and Password.
You will be prompted to change both but if you make no entry and press enter the existing setting will be kept.
The password must be at least 8 characters. 

Option 8: Exit
Exit the script.

 
NFtables Warning.
This setup uses iptables for routing the Hotspots to the internet, options 1 & 3. From Raspbian 10 Buster, IPtables are depreciated in place of NFtables. By default NFtables will handle IPtable rules. 
If you know you are using NFtables for a Firewall or other routing rules then don't use the internet routed hotspots and only use option 2, Autohotspot without internet. Otherwise there will be a conflict with your routing tables. 
NFtables will be implemented shortly in the next main update of the installer and scripts.    
Raspbian Stretch (9) & Jessie (8) only use IPtables.
You will be warned when you initally run the installer script if NFtables are active.

/etc/network/interfaces file:
many older hotspot and network setup guides online add entries to the /etc/network/interfaces file. This file is depreciated in Raspbian and any entry in this file is not compatible with these setups. This installer backup and remove any entries found in this file. They will be restored if the uninstall option is used.

RaspberryConnect.com
