#!/bin/bash
#RaspberryConnect.com - Graeme Richards
#This installer can be shared but all references to RaspberryConnect.com in this file
#and other files used by the installer should remain in place. 

#Installer version 0.74-1 (9 Feb 2022)
#Installer for AutoHotspot, AutohotspotN scripts and Static Access Point setup.
#Autohotspot: a script that allows the Raspberry Pi to switch between Network Wifi and
#an access point either at bootup or with seperate timer without a reboot.

#This installer script will alter network settings and may overwrite existing settings if allowed.
#/etc/hostapd/hostapd.conf (backup old), /etc/dnsmasq.conf (backup old), modifies /etc/dhcpcd.conf (modifies)
#/etc/sysctl.conf (modifies), /etc/network/interfaces (backup old & removes any network entries)
#PiOS 10 Buster and older use ip tables, PiOS 11 Bullseye uses nftables. 
#If nftables are detected as installed on the older PiOS then it will be used. 

#Force Access Point or Network Wifi option will only work if either autohotspot is installed and active.


#Check for PiOS or Raspbian and version.
osver=($(cat /etc/issue))
cpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
opt="X"
vhostapd="N" vdnsmasq="N" autoH="N"
autoserv="N" iptble="N" nftble="N"

if [ "${osver[0]}" != 'Raspbian' ] && [ "${osver[0]}" != 'Debian' ]; then
	echo "This AutoHotspot installer is only for the PiOS & Raspbian on the Raspberry Pi"
	exit 1
elif [ "${osver[2]}" -ge 10 ]; then
	echo 'OS Version' "${osver[2]}"
elif [ "${osver[2]}" -lt 8 ];then
	echo "The version of PiOS or Raspbian is too old for the Autohotspot script"
	echo "Version 8 'Jessie' is the minimum requirement"
fi
if [ "${osver[0]}" == 'Debian' ]; then
	if ! systemctl -all list-unit-files dhcpcd.service | grep "dhcpcd.service enabled" ;then
		echo "Debian OS detected"
		echo "dhcpcd is not the default DHCP client"
		echo "This script is intended for the Raspberry Pi OS"
		echo "and requires dhcpcd to be the default DHCP client"
		exit 1
	fi
fi

check_installed()
{
	#check if required software is already installed
	if dpkg -s "hostapd" | grep 'Status: install ok installed' >/dev/null 2>&1; then
		vhostapd="Y"
	fi
	if dpkg -s "dnsmasq" | grep 'Status: install ok installed' >/dev/null 2>&1; then
		vdnsmasq="Y"
	fi
	#Does an Autohotspot files exist
	if ls /usr/bin/ | grep "autohotspot*" >/dev/null 2>&1 ; then
		autoH="Y"
	fi
	if ls /etc/systemd/system/ | grep "autohotspot.service" >/dev/null 2>&1 ; then
		autoserv="Y"
	fi
	if dpkg -s "iptables" >/dev/null 2>&1 ; then
		iptble="Y"
	fi
	if dpkg -s "nftables" >/dev/null 2>&1 ; then
		nftble="Y"
	fi
}

check_reqfiles()
{	
	fstatus=0
	cd "${cpath}/config/"
	if test -f "Checklist.md5" ;then
		if ! md5sum -c --quiet Checklist.md5 ;then
			echo "one or more of the required files in the config folder are missing or have been altered"
			echo "please download the installer again from RaspberryConnect.com"
			exit
		fi
	else
		echo "The file Checklist.md5 is missing from Config folder"
		echo "Please download the installer again"
		echo "from RaspberryConnect.com"
		exit
	fi
	
}

check_wificountry()
{
	#echo "Checking WiFi country"
	wpa=($(cat "/etc/wpa_supplicant/wpa_supplicant.conf" | tr -d '\r' | grep "country="))
	if [ -z ${wpa: -2} ] || [[ ${wpa: -2} == *"="* ]];then
		echo "The WiFi country has not been set. This is required for the access point setup."
		echo "Please update PiOS with the wifi country using the command 'sudo raspi-config' and choose the localisation menu"
		echo "From the desktop this can be done in the menu Preferences - Raspberry Pi Configuration - Localisation" 
		echo "Once done please try again."
		echo ""
		echo "press a key to continue"
		read
	fi
}

hostapd_config()
{
	echo "hostapd Config"
	echo "Hostapd Status is " $vhostapd
	if [ "$vhostapd" = "N" ]; then
		echo "Hostapd not installed- now installing"
		apt -q install hostapd
		echo "Recheck install Status"
		check_installed
		if [ "$vhostapd" = "N" ]; then
			echo ""
			echo ""
			echo "Hostapd failed to install. Check there is internet access"
			echo "and try again"
			echo "Press a key to continue"
			read
			menu
		fi
	fi
	echo "Hostapd is installed"
	if ! grep -F "RaspberryConnect.com" "/etc/hostapd/hostapd.conf" ;then
		#not a autohotspot file, create backup
		mv "/etc/hostapd/hostapd.conf" "/etc/hostapd/hostapd-RCbackup.conf"
	fi
	cp "$cpath/config/hostapd.conf" /etc/hostapd/hostapd.conf
	if [ "${osver[2]}" -lt 10 ]; then
		cp "$cpath/config/hostapd" /etc/default/hostapd
	fi
	if [ "$opt" = "AHN" ] || [ "$opt" = "AHD" ]; then
		#For Autohotspots
		echo "Unmask & Disable Hostapd"
		if systemctl -all list-unit-files hostapd.service | grep "hostapd.service masked" ;then
			systemctl unmask hostapd.service >/dev/null 2>&1
		fi
		if systemctl -all list-unit-files hostapd.service | grep "hostapd.service enabled" ;then
			systemctl disable hostapd.service >/dev/null 2>&1
		fi
	elif [ "$opt" = "SHS" ]; then
		#for Static Hotspot
		echo "Unmask and enable hostapd"
		if systemctl -all list-unit-files hostapd.service | grep "hostapd.service masked" ;then
			systemctl unmask hostapd >/dev/null 2>&1
		fi
		if systemctl -all list-unit-files hostapd.service | grep "hostapd.service disabled" ;then
			systemctl enable hostapd >/dev/null 2>&1
		fi
	elif [ "$opt" = "REM" ]; then
		if [ -f "/etc/hostapd/hostapd-RCbackup.conf" ] ; then
			mv "/etc/hostapd/hostapd-RCbackup.conf" "/etc/hostapd/hostapd.conf"
		fi
	fi
	#check country code for hostapd.conf
	wpa=($(cat "/etc/wpa_supplicant/wpa_supplicant.conf" | tr -d '\r' | grep "country="))
	hapd=($(cat "/etc/hostapd/hostapd.conf" | tr -d '\r' | grep "country_code="))
	if [[ ! ${wpa: -2} == ${hapd: -2} ]] ; then
		echo "Changing Hostapd Wifi country to " ${wpa: -2} 
		sed -i -e "/country_code=/c\country_code=${wpa: -2}" /etc/hostapd/hostapd.conf
	fi
}

dnsmasq_config()
{
	echo "Dnsmasq Config"
	if [ "$vdnsmasq" = "N" ]; then
		apt -q install dnsmasq
		check_installed
		if [ "$vdnsmasq" = "N" ]; then
		    echo ""
		    echo ""
			echo "dnsmasq failed to install. Check there is internet access"
			echo "and try again"
			echo "Press a key to continue"
			read
			menu
		fi
	fi
	if [ -f "/etc/dnsmasq.conf" ] ; then
		if ! grep -F "RaspberryConnect.com" "/etc/dnsmasq.conf" ;then
			#not a autohotspot file, create backup
			mv "/etc/dnsmasq.conf" "/etc/dnsmasq-RCbackup.conf"
		fi
	fi
	if [ "$opt" = "AHN" ] ; then
		echo "${cpath}/config/dnsmasqAHSN.conf"
		cp "${cpath}/config/dnsmasqAHSN.conf" "/etc/dnsmasq.conf"
	elif [ "$opt" = "AHD" ];then
		cp "${cpath}/config/dnsmasqAHS.conf" "/etc/dnsmasq.conf"
	elif [ "$opt" = "SHS" ] ;then
		cp "${cpath}/config/dnsmasqSHS.conf" "/etc/dnsmasq.conf"
	fi
	if [ "$opt" = "AHN" ] || [ "$opt" = "AHD" ]; then
		#For Autohotspots
		echo "Unmask & Disable Dnsmasq"
		if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service masked" ;then
			systemctl unmask dnsmasq >/dev/null 2>&1
		fi
		if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service enabled" ;then
			systemctl disable dnsmasq >/dev/null 2>&1
		fi
	elif [ "$opt" = "SHS" ]; then
		#for Static Hotspot
		echo "Unmask & Enable Dnsmasq"
		if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service masked" ;then
			systemctl unmask dnsmasq >/dev/null 2>&1
		fi
		if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service disabled" ;then
			systemctl enable dnsmasq >/dev/null 2>&1
		fi
	fi
	if [ "$opt" = "REM" ]; then
		if [ -f "/etc/dnsmasq-RCbackup.conf" ] ; then
			mv "/etc/dnsmasq-RCbackup.conf" "/etc/dnsmasq.conf"
		fi
	fi
		
}
dhcpcd_config()
{
	#Make backup if not done
	if [ ! "/etc/dhcpcd-RCbackup.conf" ] ;then
		mv "/etc/dhcpcd.conf" "/etc/dhcpcd-RCbackup.conf"
	fi
	if [ "$opt" = "AHN" ] || [ "$opt" = "AHD" ] ;then
		#use backup for Auto scripts to retain any custon Network Config like static ip's
		if [ ! "/etc/dhcpcd-RCbackup.conf" ] ;then 
			cp "/etc/dhcpcd-RCbackup.conf" "/etc/dhcpcd.conf"
		fi
		grep -vxf "${cpath}/config/dhcpcd-remove.conf" "/etc/dhcpcd.conf" > "${cpath}/config/Ndhcpcd.conf"
		cat "${cpath}/config/dhcpcd-autohs.conf" >> "${cpath}/config/Ndhcpcd.conf"
		mv "${cpath}/config/Ndhcpcd.conf" "/etc/dhcpcd.conf"
	elif [ "$opt" = "SHS" ]; then
		#use clean dhcpcd.conf for static hotspot, backup will be restored on removal /etc/dhcpcd-RCbackup.conf 
		cp "${cpath}/config/dhcpcd-default.conf" "/etc/dhcpcd.conf"
		grep -vxf "${cpath}/config/dhcpcd-remove.conf" "/etc/dhcpcd.conf" > "${cpath}/config/Ndhcpcd.conf"
		cat "${cpath}/config/dhcpcd-SHSN.conf" >> "${cpath}/config/Ndhcpcd.conf"
		mv "${cpath}/config/Ndhcpcd.conf" "/etc/dhcpcd.conf"
	fi
}

sysctl()
{
	if [ "$opt" = "AHN" ] || [ "$opt" = "SHS" ] ;then
		sed -i -e "/#net.ipv4.ip_forward=1/c\net.ipv4.ip_forward=1" /etc/sysctl.conf
	elif [ "$opt" = "AHD" ] || [ "$opt" = "REM" ] ;then
		sed -i -e "/net.ipv4.ip_forward=1/c\#net.ipv4.ip_forward=1" /etc/sysctl.conf
	fi
}

auto_service()
{
	if [ "$opt" = "AHN" ] ;then
		cp "${cpath}/config/autohotspot-Net.service" "/etc/systemd/system/autohotspot.service"
		systemctl daemon-reload
		systemctl enable autohotspot
	elif [ "$opt" = "AHD" ] ;then
		cp "${cpath}/config/autohotspot-direct.service" "/etc/systemd/system/autohotspot.service"
		systemctl daemon-reload
		systemctl enable autohotspot
	fi
	if [ "$opt" = "REM" ] || [ "$opt" = "SHS" ]; then
		if systemctl -all list-unit-files autohotspot.service | grep "autohotspot.service enabled" ;then
			systemctl disable autohotspot.service
		fi
		if [ -f "/etc/systemd/system/autohotspot.service" ]; then
			rm /etc/systemd/system/autohotspot.service
		fi
	fi

}
hs_routing()
{
	if [ "$opt" = "SHS" ]  ;then
		if [ "$iptble" = "Y" ] ; then
			if [ ! -f "/etc/systemd/system/hs-iptables.service" ];then
				cp "${cpath}/config/hs-iptables.service" "/etc/systemd/system/hs-iptables.service"
			fi
			if systemctl -all list-unit-files hs-iptables.service | grep "hs-iptables.service enabled" ;then
				systemctl daemon-reload
			fi
			if systemctl -all list-unit-files hs-iptables.service | grep "hs-iptables.service disabled" ;then
				systemctl enable hs-iptables.service
			fi
			if [ ! -f "/etc/iptables-hs" ] ;then
				cp "${cpath}/config/iptables-hs.txt" "/etc/iptables-hs"
				chmod +x "/etc/iptables-hs"
			fi
			
		elif [ "$nftble" = "Y" ] ; then
			if [ ! -d '/etc/nftables' ] ; then
				mkdir /etc/nftables
			fi
			if ! cat '/etc/nftables.conf' | grep 'nft-stat-ap.nft' ; then
				cp "${cpath}/config/nft-stat-ap.txt" "/etc/nftables/nft-stat-ap.nft"
				chmod +x "/etc/nftables/nft-stat-ap.nft"
				sed -i '$ a include "/etc/nftables/nft-stat-ap.nft"' "/etc/nftables.conf"
				if systemctl -all list-unit-files nftables.service | grep "nftables.service disabled" ;then
					systemctl enable nftables >/dev/null 2>&1
				fi
			fi	
		fi
	elif [ "$opt" = "REM" ] || [ "$opt" = "AHN" ] || [ "$opt" = "AHD" ] ; then
		if [ "$iptble" = "Y" ] ; then
			if systemctl is-active hs-iptables | grep -w "active" ;then
				systemctl disable hs-iptables.service
			fi
			if test -f "/etc/systemd/system/hs-iptables.service" ; then
				rm /etc/systemd/system/hs-iptables.service
			fi
			if test -f "/etc/iptables-hs" ; then
				rm /etc/iptables-hs
			fi
		elif [ "$nftble" = "Y" ] ; then
			sed -i '/nft-stat-ap/d' '/etc/nftables.conf'			
		fi
	fi
}

auto_script()
{
	if [ "$opt" = "AHN" ] ;then
		cp "${cpath}/config/autohotspotN" "/usr/bin/autohotspotN"
		chmod +x /usr/bin/autohotspotN
	elif [ "$opt" = "AHD" ] ;then
		cp "${cpath}/config/autohotspot-direct" "/usr/bin/autohotspot"
		chmod +x /usr/bin/autohotspot
	elif [ "$opt" = "REM" ] || [ "$opt" = "SHS" ] ;then
		if [ -f "/usr/bin/autohotspotN" ]; then
			rm /usr/bin/autohotspotN
		fi
		if [ -f "/usr/bin/autohotspot" ]; then
			rm /usr/bin/autohotspot
		fi		
	fi
}

interface()
{
	#if interfaces file contains network settings
	#backup and remove. 
	if grep -vxf "${cpath}/config/interfaces"  "/etc/network/interfaces" ;then
		mv "/etc/network/interfaces" "/etc/network/RCbackup-interfaces"
		cp "${cpath}/config/interfaces" "/etc/network/interfaces"
	fi
	if [ "$opt" = "REM" ] ;then
		if [ -f "/etc/network/RCbackup-interfaces" ] ;then
			mv "/etc/network/RCbackup-interfaces" "/etc/network/interfaces"
		fi
	fi
}

remove()
{
	if systemctl -all list-unit-files hostapd.service | grep "hostapd.service enabled" ;then
		systemctl disable hostapd >/dev/null 2>&1
	fi
	if systemctl -all list-unit-files dnsmasq.service | grep "dnsmasq.service enabled" ;then
		systemctl disable dnsmasq >/dev/null 2>&1
	fi
	auto_script #Remove Autohotspot Scripts
	#Reset DHCPCD.conf
	if [ -f "/etc/dhcpcd-RCbackup.conf" ] ;then #restore backup
		mv "/etc/dhcpcd-RCbackup.conf" "/etc/dhcpcd.conf"
	else #or remove edits if no backup
		echo "Removing config from dhcpcd.conf"
		grep -vxf "${cpath}/config/dhcpcd-remove.conf" "/etc/dhcpcd.conf" > "${cpath}/config/Ndhcpcd.conf"
		mv "${cpath}/config/Ndhcpcd.conf" "/etc/dhcpcd.conf"
	fi
	hs_routing #remove routing for Static HS
	sysctl #remove port forwarding
	interface #restore backup of interfaces fle
	auto_service #remove autohotspot.service
}

Hotspotssid()
{
	#Change the Default Hotspot SSID and Password
	if  [ ! -f "/etc/hostapd/hostapd.conf" ] ;then
		echo "An Access Point is not installed. No Password to change"
		echo "press enter to continue"
		read
		menu
	fi
	HSssid=($(cat "/etc/hostapd/hostapd.conf" | grep '^ssid='))
	HSpass=($(cat "/etc/hostapd/hostapd.conf" | grep '^wpa_passphrase='))
	echo "Change the Access Point's SSID and Password. press enter to keep existing settings"
	echo "The current SSID is:" "${HSssid:5}"
	echo "The current SSID Password is:" "${HSpass:15}"
	echo "Enter the new Access Point SSID:"
	read ssname
	echo "Enter the hotspots new password. Minimum 8 characters"
	read sspwd
	if [ ! -z $ssname ] ;then
		echo "Changing Hotspot SSID to:" "$ssname" 
		sed -i -e "/^ssid=/c\ssid=$ssname" /etc/hostapd/hostapd.conf
	else
		echo "The Hotspot SSID is"  ${HSssid: 5}
	fi
	if [ ! -z $sspwd ] && [ ${#sspwd} -ge 8 ] ;then
		echo "Changing Access Point Password to:" "$sspwd"
		sed -i -e "/^wpa_passphrase=/c\wpa_passphrase=$sspwd" /etc/hostapd/hostapd.conf
	else
		echo "The Access Point Password is:"  ${HSpass: 15}
	fi
	echo ""
	echo "The new setup will be available next time the hotspot is started"
	echo "Press a key to continue"
	read
	menu
}

setupssid()
{
	echo "Searching for local WiFi connection"
	echo "Add a new WiFi network or change the password for an existing one in range"
	echo "For Wifi networks where only a password is required."
	echo "This will not work where a username and password is required"
	echo ""
	echo "If the Pi is currently in Access Point mode with a Autohotspot"
	echo "then use option 6 to Force the Pi to the newly added Wifi Network"
	ct=0; j=0 ; lp=0
	wfselect=()

	until [ $lp -eq 1 ] #wait for wifi if busy, usb wifi is slower.
	do
		IFS=$'\n:$\t' localwifi=($((iw dev wlan0 scan ap-force | egrep "SSID:") 2>&1)) >/dev/null 2>&1
		#if wifi device errors recheck
		if (($j >= 5)); then #if busy 5 times exit to menu
			echo "WiFi Device Unavailable, cannot scan for wifi devices at this time"
			echo "press a key to continue"
			menu
			break
		elif echo "${localwifi[1]}" | grep "No such device (-19)" >/dev/null 2>&1; then
			echo "No Device found,trying again"
			j=$((j + 1))
			sleep 2
		elif echo "${localwifi[1]}" | grep "Network is down (-100)" >/dev/null 2>&1 ; then
			echo "Network Not available, trying again"
			j=$((j + 1))
			sleep 2
		elif echo "${localwifi[1]}" | grep "Read-only file system (-30)" >/dev/null 2>&1 ; then
			echo "Temporary Read only file system, trying again"
			j=$((j + 1))
			sleep 2
		elif echo "${localwifi[1]}" | grep "Invalid exchange (-52)" >/dev/null 2>&1 ; then
			echo "Temporary unavailable, trying again"
			j=$((j + 1))
			sleep 2
		elif echo "${localwifi[1]}" | grep -v "Device or resource busy (-16)"  >/dev/null 2>&1 ; then
			lp=1
		else #see if device not busy in 2 seconds
			echo "WiFi Device unavailable checking again"
			j=$((j + 1))
			sleep 2
		fi
	done

	#Wifi Connections found - continue
	for x in "${localwifi[@]}"
	do
		if [ $x != "SSID" ]; then
			ct=$((ct + 1))
			echo "$ct  ${x/ /}"
			wfselect+=("${x/ /}")
		fi
	done
	ct=$((ct + 1)) 
	echo  "$ct To Cancel"
	wfselect+=("Cancel")
	if [ "${#wfselect[@]}" -eq 1 ] ;then
		echo "Unable to detect local WiFi devices. Maybe there is a temporary issue with your WiFi"
		echo "Try again in a minute"
		echo "press a enter to continue"
		read
		menu
	fi

	read wf
	if [[ $wf =~ ^[0-9]+$ ]]; then
		if [ $wf -ge 0 ] && [ $wf -le $ct ]; then
			updatessid "${wfselect[$wf-1]}"
		else
			echo -e "\nNot a Valid entry"
			setupssid
		fi
	else
		echo -e "\nNot a Valid entry"
		setupssid
	fi
}

updatessid()
{
	#check for blank in return
	echo "$1"
	echo ""
	if [ "$1" = "Cancel" ] || [ "$1" = "" ] ; then
		menu
		exit
	fi

	IFS="," wpassid=$(awk '/ssid="/{ print $0 }' /etc/wpa_supplicant/wpa_supplicant.conf | awk -F'ssid=' '{ print $2 }' | sed 's/\r//g'| awk 'BEGIN{ORS=","} {print}' | sed 's/\"/''/g' | sed 's/,$//')
	ssids=($wpassid)
	if [[ ! " ${ssids[@]} " =~ " $1 " ]]; then
		echo "Add New Wifi Network"
		echo "Selection SSID: $1"
		echo ""
		echo "Enter password for Wifi"
		read ssidpw
		echo -e "\nnetwork={\n\tssid=\x22$1\x22\n\tpsk=\x22$ssidpw\x22\n\tkey_mgmt=WPA-PSK\n}" >> /etc/wpa_supplicant/wpa_supplicant.conf
	else
		f=0
		echo "Change Password for Selected Wifi"
		while IFS= read -r ln || [[ -n "$ln" ]] <&3; do
			if [[ "$ln" == *"psk="* ]] && [ $f -eq 1 ] ;then
				break
			elif [[ "$ln" == *"$1"* ]] ; then
				f=1
			fi
		done < /etc/wpa_supplicant/wpa_supplicant.conf
		echo "Change Wifi Network Password"
		echo "Selected SSID: $1"
		echo ""
		echo "Enter password for Wifi"
		read chgpw
		newpsk=$'\tpsk=\x22'$chgpw$'\x22\n'
		echo "The entry will be" $newpsk
		echo "To be Replaced $ln"
		sed -i '/'"$ln"'/c\'"$newpsk" /etc/wpa_supplicant/wpa_supplicant.conf
		f=0
	fi
}

forceswitch()
{
if [ ! -f "/etc/systemd/system/autohotspot.service" ] ;then
	echo "No Autohotspot script installed, unable to continue"
	echo "press enter to continue"
	read
	menu
fi
#Create Hotspot or connect to valid wifi networks
echo 0 > /proc/sys/net/ipv4/ip_forward #deactivate ip forwarding

if systemctl status hostapd | grep "(running)" >/dev/null 2>&1
then
    echo "The access point is already active"
    echo "Switching to Network Wifi if it is available"
    echo "this takes about 20 seconds to complete checks"
	systemctl restart autohotspot.service
	menu
elif { wpa_cli status | grep "$wifidev"; } >/dev/null 2>&1
then
	echo "Cleaning wifi files and Activating Hotspot"
	wpa_cli terminate >/dev/null 2>&1
	ip addr flush "$wifidev"
	ip link set dev "$wifidev" down
	rm -r /var/run/wpa_supplicant >/dev/null 2>&1
	get_HS_IP
    else #Neither the Hotspot or Network is active
	get_HS_IP
fi
}
##
createAdHocNetwork_N() #for Internet routed Hotspot for Force Switch
{
	#receive IP as $1
	echo "Creating Hotspot with Internet"
	ip link set dev "$wifidev" down
	ip a add $1 brd + dev "$wifidev"
	ip link set dev "$wifidev" up
	dhcpcd -k "$wifidev" >/dev/null 2>&1
	if iptables 2>&1 | grep 'no command specified' >/dev/null 2>&1 ; then
		iptables -t nat -A POSTROUTING -o "$ethdev" -j MASQUERADE
		iptables -A FORWARD -i "$ethdev" -o "$wifidev" -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -A FORWARD -i "$wifidev" -o "$ethdev" -j ACCEPT
	elif nft 2>&1 | grep 'no command specified' >/dev/null 2>&1 ; then
		nft add table inet ap
		nft add chain inet ap rthrough { type nat hook postrouting priority 0 \; policy accept \; }
		nft add rule inet ap rthrough oifname "$ethdev" masquerade
		nft add chain inet ap fward { type filter hook forward priority 0 \; policy accept \; }
		nft add rule inet ap fward iifname "$ethdev" oifname "$wifidev" ct state established,related accept
		nft add rule inet ap fward iifname "$wifidev" oifname "$ethdev" accept
	fi
	systemctl start dnsmasq
	systemctl start hostapd
	echo 1 > /proc/sys/net/ipv4/ip_forward
}

createAdHocNetwork_D() #For non Internet Routed Hotspot for Force Switch
{
	echo "Creating WiFi access point with no network/internet for connected devices"
	echo "through eth0"
	ip link set dev "$wifidev" down
	ip a add $1 brd + dev "$wifidev"
	ip link set dev "$wifidev" up
	dhcpcd -k "$wifidev" >/dev/null 2>&1
	systemctl start dnsmasq
	systemctl start hostapd
}

get_HS_IP() #get ip address from current active hotspot script for Force Switch
{
	if [ ${Aserv: -4} = "spot" ];then #Direct
		ipline=($(cat /usr/bin/autohotspot | grep "ip a add"))
		createAdHocNetwork_D "${ipline[3]}" 
	elif [ ${Aserv: -4} = "potN" ];then #Internet
		ipline=($(cat /usr/bin/autohotspotN | grep "ip a add"))
		createAdHocNetwork_N "${ipline[3]}"
	else
		echo "The Autohotspot is disabled or not installed"
		echo "unable to force a switch."
		echo "Press enter to continue"
		read
		menu
	fi
}

display_HS_IP() #get ip address from current active hotspot script
{
    Aserv=($(cat /etc/systemd/system/autohotspot.service 2>/dev/null| grep "ExecStart="))  #which hotspot is active?
    if [ ${Aserv: -4} = "spot" ] >/dev/null 2>&1  ;then #Direct
		ipline=($(cat /usr/bin/autohotspot | grep "ip a add")) 
		echo "Access Point IP Address for SSH and VNC: ${ipline[3]: :-3}" 
    elif [ ${Aserv: -4} = "potN" ] >/dev/null 2>&1 ;then #Internet
		ipline=($(cat /usr/bin/autohotspotN | grep "ip a add")) 
		echo "Access Point IP Address for SSH and VNC: ${ipline[3]: :-3}"
    else #Static Hotspot default IP
		echo "Access Point IP Address for ssh and VNC: 192.168.50.10"
    fi
}

go()
{
	opt="$1"
	#echo "Selected" "$opt"
	#echo "Action options"
	if [ "$opt" = "REM" ] ;then
		remove
		echo "Please reboot to complete the uninstall"
	elif [ "$opt" = "SSI" ] ;then
		setupssid
		echo "the new ssid will be used next time the autohotspot script is "
		echo "run at boot or manually otherwise use the Force to.... option"
		echo "if the hotspot is active"
	elif [ "$opt" = "FOR" ] ;then
		if [ ! -f "/etc/systemd/system/autohotspot.service" ] ;then
			echo "No Autohotspot script installed, unable to continue"
			echo "press enter to continue"
			read
			menu
		fi
		Aserv=($(cat /etc/systemd/system/autohotspot.service | grep "ExecStart="))
		wi=($(cat ${Aserv: 10} | grep wifidev=))
		eth=($(cat ${Aserv: 10} | grep ethdev=))
		wifidev=${wi[0]: 9:-1} #wifi device name from active autohotspot/N script
		ethdev=${eth[0]: 8:-1} #Ethernet port to use with IP tables
		forceswitch
	elif [ "$opt" = "HSS" ] ;then
		Hotspotssid
	else
		hostapd_config
		dnsmasq_config
		interface
		sysctl
		dhcpcd_config
		auto_service
		hs_routing
		auto_script
		echo ""
		echo "The hotspot setup will be available after a reboot"
		HSssid=($(cat "/etc/hostapd/hostapd.conf" | grep '^ssid='))
		HSpass=($(cat "/etc/hostapd/hostapd.conf" | grep '^wpa_passphrase='))
		echo "The Hotspots WiFi SSID name is: ${HSssid: 5}"
		echo "The WiFi password is: ${HSpass: 15}"
		display_HS_IP
	fi
	echo "Press any key to continue"
	read
	
}

menu()
{
#selection menu
clear
until [ "$select" = "8" ]; do
	echo "Raspberryconnect.com Autohotspot installation and setup"
	echo "for installation or switching between access point types"
	echo "or uninstall the access point back to standard Pi wifi"
	echo ""
	echo "Autohotspot Net = connects to a known wifi network in range,"
	echo "otherwise automatically creates a Raspberry Pi access point with network/internet access if an"
	echo "ethernet cable is connected. Uses wlan0, eth0. Pi's 3,3+,4"
	echo ""
	echo "Autohotspot NO Net = as above but connected devices to the access point"
	echo "will NOT get a network/internet connection if an ethernet cable is connected. Rpi Zero W & RPi Zero 2"
	echo ""
	echo "Permanent Access Point = permanent access point with network/internet access from eth0 for"
	echo "connected devices"
	echo ""
	echo " 1 = Install Autohotspot with eth0 access for Connected Devices"
	echo " 2 = Install Autohotspot with No eth0 for connected devices"
	echo " 3 = Install a Permanent Access Point with eth0 access for connected devices"
	echo " 4 = Uninstall Autohotspot or permanent access point"
	echo " 5 = Add a new wifi network to the Pi (SSID) or update the password for an existing one."
	echo " 6 = Autohotspot: Force to an access point or connect to WiFi network if a known SSID is in range"
	echo " 7 = Change the access points SSID and password"
	echo " 8 = Exit"
	echo ""
	echo -n "Select an Option:"
	read select
	case $select in
	1) clear ; go "AHN" ;; #Autohospot Internet
	2) clear ; go "AHD" ;; #Autohotspot Direct
	3) clear ; go "SHS" ;; #Static Hotspot
	4) clear ; go "REM" ;; #Remove Autohotspot or Static Hotspot
	5) clear ; go "SSI" ;; #Change/Add Wifi Network
	6) clear ; go "FOR" ;; #Force Hotspot <> Force Network
	7) clear ; go "HSS" ;; #Change Hotspot SSID and Password
	8) clear ; exit ;;
	*) clear; echo "Please select again";;
	esac
done
}

check_reqfiles
check_installed
check_wificountry
menu #show menu
