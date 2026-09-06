# CVE-2026-xxxx

**CVE ID:** Pending

**Problem Type:** CWE-319 (Cleartext Transmission of Sensitive Information), CWE-345 (Insufficient Verification of Data Authenticity), & CWE-434 (Unrestricted Upload of File with Dangerous Type) 

**Vendor:** Meari Technologies

**Affected Product:** CloudEdge Bell 24T Cloud API

**Product Page:** [https://cloudedge.app/bell-24t/](https://cloudedge.app/bell-24t/)

**Firmware Version:** 3.4.1.20230404

**Researcher:** Chase Cooper

## Summary 
The CloudEdge Bell 24T transmits event media (such as images captured during motion detection) and temporary Security Token Service (STS) credentials to a cloud Object Storage Service (OSS) over unencrypted HTTP (Port 80) before being pushed to the mobile application as an alert. This lack of transport security exposes sensitive credentials and allows active modification of media payloads in transit. Furthermore, the backend endpoint fails to validate the integrity or file type of the image payloads uploaded to the OSS container.

## Impact 
Because this transport layer lacks encryption, transmissions can be intercepted. An unauthorized adversary who intercepts the cleartext `x-oss-security-token` is granted complete read and write privileges to the victim's remote cloud storage infrastructure. Furthermore, an active Man-in-the-Middle (MitM) can intercept and modify the HTTP POST/PUT requests during transit. This allows an attacker to alter the attached media payloads, injecting falsified surveillance imagery (Data Spoofing) or uploading unauthorized file types directly to the OSS without needing to authenticate. Since the server processes non-image files, it may also allow the upload of malicious scripts (RCE/XSS).

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
4. **Trigger Event:** Physically press the doorbell button or trigger the motion sensor to initiate a media upload.
5. **Capture Traffic:** Utilize the transparent proxy to capture the outbound HTTP POST and PUT requests directed to port 80.
6. **Extract Token:** Inspect the request headers to locate the cleartext `x-oss-security-token` header, which contains the valid STS credentials. Decode the Base64-encoded `x-oss-callback` header to expose the associated userID, deviceID, and event metadata.
7. **Execute Payload Tampering:** Before forwarding the captured PUT request that uploads the file, utilize the proxy to swap the raw image bytes with a falsified image or an alternative file type (such as an executable script). The server will accept the modified payload due to the lack of transport integrity. 
8. **Note:** The firmware incorrectly *tags* the image payload with a `Content-Type: application/json` header, which the backend currently accepts without proper MIME-type enforcement.

<img width="891" height="801" alt="image" src="https://github.com/user-attachments/assets/84eb5840-98bf-4768-80d5-1d28ca50f297" />

<img width="863" height="368" alt="image" src="https://github.com/user-attachments/assets/59ce6ecc-66c9-4a74-be3a-b7411a5adf11" />




## Recommended Mitigation

- **Enforce Strict TLS Transport:** Deprecate plain HTTP (Port 80) across all media pipelines in favor of TLS 1.2+.
- **Server-Side Validation:** Implement strict file-type and magic-byte verification on the backend to prevent the storage of non-image files, providing defense-in-depth against payload tampering. To prevent data spoofing, cryptographically sign event payloads at the hardware level so the backend can verify the image genuinely originated from the device before distributing it to the end-user application.
