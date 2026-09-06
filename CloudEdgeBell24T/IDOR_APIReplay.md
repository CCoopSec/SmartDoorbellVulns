# CVE-2026-xxxx


**CVE ID:** Pending

**Problem Type:** CWE-294 (Authentication Bypass by Capture-Replay), CWE-639 (Authorization Bypass Through User-Controlled Key / IDOR)

**Vendor:** Meari Technologies

**Affected Product:** CloudEdge Bell 24T Cloud API

**Product Page:** [https://cloudedge.app/bell-24t/](https://cloudedge.app/bell-24t/)

**Firmware Version:** 3.4.1.20230404

**Researcher:** Chase Cooper

## Summary 
The CloudEdge API utilizes custom Hash-Based Message Authentication Code (HMAC) headers (X-Ca-Key, X-Ca-Nonce, X-Ca-Timestamp) for physical alerts. However, the backend infrastructure fails to strictly validate timestamp freshness and nonce uniqueness. Furthermore, API access control relies entirely on static hardware identifiers (UUIDs).

## Impact 
The failure to validate HMAC freshness/uniqueness allows an attacker to capture and arbitrarily replay valid API requests without error, manipulating device states and executing localized Denial of Service (DoS) conditions (such as battery draining or notification harassment). By modifying the static UUID within a replayed payload, an attacker can execute an Insecure Direct Object Reference (IDOR) attack, successfully triggering states on devices belonging to different accounts.

## Reproduction (PoC)

**Necessities:**
- CloudEdge Bell 24T doorbell.
- An interception proxy capable of presenting a self-signed certificate (mitmproxy).
- A controlled network interception environment (Raspberry Pi acting as a rogue wireless access point).

**Steps:**
1. **Configure the Interception Environment:**
	- Use hostapd to convert wireless interface cards into access points.
	- Use dnsmasq for DHCP/DNS.
2. **Set Up the Proxy & Port Forwarding:**
	- Launch mitmproxy as a transparent proxy and configure it to listen on a designated port (e.g., 8081).
	- Configure iptables on the Raspberry Pi to redirect all traffic destined for port 443 to the proxy's listening port:
		- `sudo iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 8080`
3. **Connect Target Device:**
	- Provision the Doorbell to connect to the rogue access point's SSID, or perform other methods (e.g., ARP cache poisoning) to connect the doorbell to the rogue access point.
4. **Capture and Execute Replay:** Utilize the proxy repeater module to capture and send the exact captured request to the server at a later time.
5. **Observation:** The backend server will accept the replayed request and execute the action, confirming the failure to validate the timestamp or nonce uniqueness.
6. **Execute IDOR:** Modify the `deviceID` parameter within the URL query string (and the X-Ca-Key header) to reflect the UUID of a separate, targeted device, and replay the request. The command will successfully execute on the targeted hardware. 

<img width="981" height="103" alt="image" src="https://github.com/user-attachments/assets/445f9964-c42e-4057-88d8-f589d43622e6" />
<img width="851" height="361" alt="image" src="https://github.com/user-attachments/assets/5217cbe6-550d-4469-b10b-5688d42e6b62" />

## Recommended Mitigation

- **Replay & API Hardening:** Enforce strict timestamp checking windows (e.g., rejecting requests older than 30 seconds) and maintain server-side nonce caches to reject replayed API calls.
- **IDOR Prevention:** Divert authorization away from static UUIDs by implementing robust Role-Based Access Control (RBAC) tied to active, authenticated session tokens.
