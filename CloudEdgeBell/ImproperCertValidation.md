# CVE-2026-xxxx


**CVE ID:** Pending

**Problem Type:** CWE-295 (Improper Certificate Validation)

**Vendor:** Meari Technologies

**Affected Product:** CloudEdge Bell 24T

**Product Page:** https://cloudedge.app/bell-24t/

**Firmware Version:** 3.4.1.20230404

**Researcher:** Chase Cooper


## Summary
The CloudEdge Bell 24T fails to properly validate SSL/TLS certificates when communicating with its backend cloud infrastructure. The absence of certificate pinning and chain validation in the firmware allows an attacker to intercept, decrypt, and manipulate 'secure' HTTPS communications to port 443 via a Man-in-the-Middle (MitM) attack.


## Impact
By routing the device's traffic through a rogue wireless access point paired with a transparent proxy, an attacker can completely compromise the confidentiality and integrity of the device-to-cloud communication stream. 
- **Information Disclosure:** Silent interception of video feeds, account identifiers, session tokens, and potentially plaintext credentials.
- **Data Modification:** Tampering with API requests and responses (e.g., spoof status events, inject custom payloads, utilize paid features without payment, or modify device configuration states).


## Reproduction (PoC)
Necessities:
- CloudEdge Bell 24T doorbell.
- An interception proxy capable of presenting a self-signed certificate (mitmproxy).
- A controlled network interception environment (Raspberry Pi acting as a rogue wireless access point).

1. Configure the Interception Environment:
	- Use hostapd to convert wireless interface cards into access points.
	- Use dnsmasq for DHCP/DNS.
2. Set Up the Proxy & Port Forwarding:
	- Launch mitmproxy as a transparent proxy and configure it to listen on a designated port (e.g., 8081).
	- Configure iptables on the Raspberry Pi to redirect all traffic destined for port 443 to the proxy's listening port:
		- `sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 8080`
3. Connect Target Device:
	- Provision the Doorbell to connect to the rogue access point's SSID, or perform other methods (e.g., ARP cache poisoning) to connect the doorbell to the rogue access point.
4. Execute Interception:
	- Monitor the traffic stream using the proxy.
	- **Observation:** The doorbell does not drop the connection upon receiving the proxy's untrusted, self-signed certificate. The TLS handshake completes successfully without triggering any certificate pinning or chain validation failure routines.
	- **Result:** Decrypted HTTPS traffic originating from and destined to the doorbell is fully visible and editable in the proxy.

Showcase of the captured flows using mitmproxy:
<img width="977" height="349" alt="image" src="https://github.com/user-attachments/assets/36af1385-8fb0-424c-8392-84eeeb4e0fbc" />

Detailed look into a POST request:
<img width="987" height="427" alt="image" src="https://github.com/user-attachments/assets/7b3a9e9b-8749-484e-9513-ce548434c0d4" />


## Recommended Mitigation:
- **Certificate Validation:** The firmware must be updated to enforce strict validation of the SSL/TLS certificate chain against a trusted root CA store.
- **Certificate Pinning:** Implement public key or certificate pinning for all communications between the physical device and the Meari Technologies backend APIs to explicitly reject arbitrary or self-signed certificates.
