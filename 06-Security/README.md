# Security

## In place now

- SSH management on Cisco devices
- SSH v2
- RSA keys for SSH
- separate management VLAN
- PortFast on endpoint access ports
- BPDU Guard on endpoint access ports
- unused ports shutdown
- VLAN 999 as the native VLAN
- inter-VLAN user segmentation with named extended ACLs
- service-based access controls into the Server VLAN
- dedicated I.T. admin workstation exception

## Inter-VLAN ACLs

The user VLAN ACL project is complete.

The ACLs are configured on **CORESW1** because that is where the VLAN SVIs and inter-VLAN routing live. I am using **named extended ACLs** applied inbound on each user VLAN SVI.

| VLAN | Department | Network | ACL |
|---:|---|---|---|
| 100 | Shipping | 10.0.100.0/24 | SHIPPING-IN |
| 110 | Accounting | 10.0.110.0/24 | ACCOUNTING-IN |
| 120 | Human Resources | 10.0.120.0/24 | HR-IN |
| 130 | Executives | 10.0.130.0/24 | EXECUTIVES-IN |
| 140 | I.T | 10.0.140.0/24 | IT-IN |

### Overall policy

The ACLs now handle two things:

1. **department segmentation** so normal user VLANs cannot freely initiate traffic to each other
2. **server access control** so users only reach the Server VLAN resources they actually need

The common policy is:

~~~text
User VLAN
    ↓
Allow DHCP
Allow ping to its own gateway
Allow required server services
Deny remaining Server VLAN traffic
Deny remaining internal 10.0.0.0/8 traffic
Allow external destinations / Internet
~~~

The screenshots below are from the initial user-segmentation stage of the ACL build. I later tightened the Server VLAN permits further as documented below.

**Shipping**

<img width="605" height="146" alt="completed SHIPPING ACL" src="https://github.com/user-attachments/assets/308c4da4-b4ab-4508-92c7-07583aa6645b" />

**Accounting**

<img width="621" height="148" alt="completed ACCOUNTING ACL" src="https://github.com/user-attachments/assets/dd2ef24b-3e8d-4651-9485-a01ade16584a" />

**Human Resources**

<img width="594" height="142" alt="completed HR  ACL" src="https://github.com/user-attachments/assets/f7e05ec9-5812-4888-b6a1-9704d0530fec" />

**Executives**

<img width="612" height="151" alt="completed EXECUTIVES ACL" src="https://github.com/user-attachments/assets/8f4e6c27-109f-4f08-a741-3a2b14a61418" />

**I.T.**

<img width="605" height="132" alt="completed IT acl in" src="https://github.com/user-attachments/assets/be6055bd-b6c9-4418-84a1-469329374622" />

Applying the ACL inbound means traffic is checked as it enters CORESW1 from that user VLAN, before the core routes it somewhere else.

### Server access policy

The first version of the ACLs allowed the entire Server VLAN. I later replaced that broad access with service-based rules.

Current server addresses:

| Server | Address | Access |
|---|---|---|
| DC01 | 10.0.20.3 | normal domain services from all user VLANs |
| FS01 | 10.0.20.4 | SMB from all user VLANs |
| HR onboarding site on FS01 | 10.0.20.4 TCP 80 | Human Resources and I.T. only |
| Proxmox | 10.0.20.10 | dedicated I.T. admin workstation only |

For now I allow full IP access from the user VLANs to **DC01** instead of trying to individually permit every Active Directory service. Domain clients rely on several services and RPC ranges, so I would rather keep domain operations stable and narrow that further in a separate hardening phase.

All user VLANs are allowed to reach **FS01 over TCP 445** for SMB/file shares.

Shipping, Accounting, and Executives follow this server pattern:

~~~cisco
permit ip <user-subnet> host 10.0.20.3
permit tcp <user-subnet> host 10.0.20.4 eq 445
deny ip <user-subnet> 10.0.20.0 0.0.0.255
~~~

Human Resources adds the onboarding site:

~~~cisco
permit tcp 10.0.120.0 0.0.0.255 host 10.0.20.4 eq 80
~~~

I.T. also gets the onboarding site, but its dedicated admin workstation exception is placed before the Server VLAN deny.

### I.T. admin workstation exception

The dedicated I.T. admin workstation is **10.0.140.10**.

<img width="606" height="246" alt="IT matchine can ping outside matchines" src="https://github.com/user-attachments/assets/f44d5170-7e99-40fc-b10a-ead601134bc0" />

This rule is placed before the normal internal denies in `IT-IN`:

<img width="605" height="132" alt="completed IT acl in" src="https://github.com/user-attachments/assets/1102d4e0-bab8-4b48-8ced-0985ec99b6ac" />

~~~cisco
permit ip host 10.0.140.10 10.0.0.0 0.255.255.255
~~~

That lets this one host initiate administrative traffic to internal NorthStar networks, including Proxmox, while normal I.T. clients remain restricted.

The other user VLAN ACLs need return-path exceptions because standard IOS ACLs are stateless.

For example, `SHIPPING-IN` includes:

~~~cisco
permit icmp 10.0.100.0 0.0.0.255 host 10.0.140.10 echo-reply
permit tcp 10.0.100.0 0.0.0.255 host 10.0.140.10 established
~~~

Accounting, Human Resources, and Executives use the same return-path pattern with their own source subnet.

This allows:

~~~text
10.0.140.10 -> user VLAN             allowed to initiate
ICMP echo-reply -> 10.0.140.10       allowed
established TCP -> 10.0.140.10       allowed
user VLAN -> new connection to I.T.  denied
~~~

The TCP `established` keyword checks ACK/RST traffic; it is not a stateful firewall session table. I also did not add a broad UDP return rule. If an administrative tool later needs UDP, I will add the specific service it requires.

### Why the DHCP rule is separate

A new DHCP client does not have a normal VLAN IP address yet.

Its initial request uses UDP source port 68 and destination port 67, so each user ACL allows:

~~~cisco
permit udp any eq bootpc any eq bootps
~~~

CORESW1 then uses the existing DHCP relay configuration to forward the request toward DC01.

### Why the internal deny uses 10.0.0.0/8

The destination:

~~~text
10.0.0.0 0.255.255.255
~~~

matches the internal `10.0.0.0/8` address space.

Approved traffic is permitted above that line. Everything else destined for an internal NorthStar network is denied before the final external permit.

### Validation

I tested the ACLs and confirmed:

- each user VLAN can reach its own gateway
- normal domain services still work through DC01
- SMB to FS01 works on TCP 445
- the HR onboarding site works from Human Resources and I.T.
- the onboarding site is blocked from Shipping, Accounting, and Executives
- Proxmox management is blocked from normal user and I.T. clients
- `10.0.140.10` can reach Proxmox and initiate administrative traffic to the other user VLANs
- normal user VLANs cannot freely initiate traffic to each other
- Internet access still works
- ACL deny entries show matches during testing

<img width="606" height="246" alt="IT matchine can ping outside matchines" src="https://github.com/user-attachments/assets/e02b3585-9d17-4fb2-8df7-23dccda1ba60" />
<img width="620" height="216" alt="non it matchine can ping it matchine" src="https://github.com/user-attachments/assets/aa72a0f3-093b-4787-af64-9066c0bd162b" />

Before ACL testing, I also had to allow ICMPv4 Echo Requests through Windows Defender Firewall on the test clients so endpoint firewall behavior would not be confused with an ACL deny.

That troubleshooting note is here:

[Windows Firewall Blocking Inter-VLAN Ping](../08-Troubleshooting/windows-firewall-icmp-testing.md)

## Next security work

The **user VLAN ACL project is complete**, including both department segmentation and user-to-server access controls.

Future security work can be handled separately, including:

- control traffic initiated from the Server VLAN
- harden access to the Management VLAN
- narrow DC01 access to specific AD services if I decide the added complexity is worthwhile
- add service-specific UDP exceptions for the I.T. admin workstation only if an admin tool actually needs them
- continue with additional Layer 2 security controls and monitoring
