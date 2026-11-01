#!/bin/bash

# make sure NetworkManager is ignoring wlan0
# sudo nano /etc/NetworkManager/NetworkManager.conf
# [keyfile]
# unmanaged-devices=interface-name:wlan0

# make sure dnsmasq assigns the IP to wlan0 and serves DHCP
# sudo nano /etc/dnsmasq.conf
#interface=wlan0
#dhcp-range=192.168.100.100,192.168.100.150,255.255.255.0,24h
#domain-needed (optional)
#bogus-priv (optional)

# configure hostapd
#sudo nano /etc/hostapd/hostapd.conf
#interface=wlan0
#driver=nl80211
#ssid=
#hw_mode=g     (g for 2.4GHz, a for 5GHz)
#channel=6
#wpa=2
#wpa_passphrase=
#wpa_key_mgmt=WPA-PSK
#rsn_pairwise=CCMP
#auth_algs=1
#macaddr_acl=0
#sudo nano /etc/default/hostapd
#DAEMON_CONF="/etc/hostapd/hostapd.conf"

sudo sysctl -w net.ipv4.ip_forward=1
sudo ip addr add 192.168.100.1/24 dev wlan0
sudo ip link set wlan0 up
ip a show wlan0

sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

sudo systemctl restart hostapd
sudo systemctl restart dnsmasq

#caido-cli --listen 0.0.0.0:8080
# go to interception/proxy settings in caido, and ensure 'Transparent Proxying' is enabled

# make sure clients trust caido's root CA for https
#sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-ports 8080
#sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-ports 8080

#mitmproxy --mode transparent --showhost -p 8081
#mitmweb --mode transparent --showhost -p 8081 --web-host 0.0.0.0 --web-port 8082
#sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-ports 8081
#sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-ports 8081

#sudo tshark -i wlan0 -P -s 0 -w packets.pcapng
