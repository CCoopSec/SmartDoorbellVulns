# CVE-2026-xxxx

**CVE ID:** Pending

**Problem Type:** CWE-319 (Cleartext Transmission of Sensitive Information), CWE-346 (Origin Validation Error), CWE-290 (Authentication Bypass by Spoofing)

**Vendor:** Meari Technologies

**Affected Product:** CloudEdge Bell 24T

**Product Page:** [https://cloudedge.app/bell-24t/](https://cloudedge.app/bell-24t/)

**Firmware Version:** 3.4.1.20230404

**Researcher:** Chase Cooper

## Summary
During real-time video streaming, the CloudEdge Bell 24T initiates Peer-to-Peer (P2P) session negotiation by broadcasting its Device UUID and Session ID (SID) in plaintext JSON via UDP across the local subnet.

## Impact
Because this Interactive Connectivity Establishment (ICE) signaling occurs entirely in plaintext without mutual authentication, an attacker on the local network can exploit a hole-punching race condition. This allows the attacker to forcefully redirect the unencrypted UDP packet stream (containing the live H.264 video feed) directly to an arbitrary listening socket for unauthorized real-time surveillance.

## Reproduction (PoC)

**Necessities:**
- CloudEdge Bell 24T doorbell.
- Local network access (same LAN as the doorbell).
- Packet sniffer (e.g., `tshark` or Wireshark) and `netcat`.
**Steps:**
1. **Configure the Interception Environment:**
	- Use hostapd to convert wireless interface cards into access points.
	- Use dnsmasq for DHCP/DNS.
2. **Set Up the Proxy & Port Forwarding:**
	- Launch mitmproxy as a transparent proxy and configure it to listen on a designated port (e.g., 8081).
	- Configure iptables on the Raspberry Pi to redirect all traffic destined for port 443 to the proxy's listening port:
		- `sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 8080`
3. **Connect Target Device:**
	- Provision the Doorbell to connect to the rogue access point's SSID, or perform other methods (e.g., ARP cache poisoning) to connect the doorbell to the rogue access point. and observe the plaintext JSON UDP broadcasts containing the device ID and SID.
4. **Intercept & Modify:** Capture the response payload from the mobile application (which advertises the local IP and port `16685`).
5. **Exploit Race Condition:** Substitute the legitimate client's destination IP address with an attacker-controlled IP address within the JSON payload, and transmit it to the doorbell.
6. **Stream Hijacking:** Bind a local listener to port `16685` and pipe the incoming stream into a media player to view the unauthorized surveillance feed (e.g., `nc -u -l 16685 | ffplay -f h264 -`).

<img width="982" height="58" alt="image" src="https://github.com/user-attachments/assets/2360fb8d-132b-4c04-a6e6-9c52faf826a1" />

<img width="882" height="77" alt="image" src="https://github.com/user-attachments/assets/c274e5df-55ae-4940-a81e-6682ba7ada2e" />

## Recommended Mitigation

- **Encrypted Local Signaling:** Deprecate plaintext UDP broadcasts in favor of encrypted signaling protocols (e.g., DTLS or TLS) to protect session identifiers from interception.
- **Endpoint Validation and Mutual Authentication:** Implement mutual authentication (e.g., mTLS) between the doorbell and the authorized client. The device must cryptographically verify the origin and integrity of the ICE signaling payload before binding the video stream to a destination IP and port, preventing unauthorized redirection.
