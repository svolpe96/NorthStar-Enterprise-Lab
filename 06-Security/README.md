# Security

## In place now

- SSH management on Cisco devices
- SSH v2
- RSA keys for SSH
- VTY access restricted to the dedicated I.T. admin workstation
- separate management VLAN
- PortFast on endpoint access ports
- BPDU Guard on endpoint access ports
- unused ports shutdown
- VLAN 999 as the native VLAN
- inter-VLAN user segmentation with named extended ACLs
- service-based access controls into the Server VLAN
- dedicated I.T. admin workstation exception
- inbound Server VLAN ACL controlling server-originated traffic
- Server VLAN blocked from initiating traffic into the home LAN

## Management plane / SSH

Remote management of the Cisco infrastructure is restricted to the dedicated I.T. admin workstation at **10.0.140.10**.

A standard named ACL is applied directly to the VTY lines with `access-class`, so the restriction applies to SSH management regardless of which routed interface address is targeted.

~~~cisco
ip access-list standard VTY-MGMT
 remark Dedicated IT admin workstation only
 permit host 10.0.140.10
 deny any

line vty 0 15
 access-class VTY-MGMT in
 login local
 transport input ssh
~~~

The same VTY management policy is in place on:

- CORESW1
- ASW1
- ASW2
- NY router

SSH version 2 and RSA keys are used for remote management. The NY router uses SSHv2 with a 2048-bit RSA key pair.

I tested management access from the dedicated admin workstation and confirmed that non-admin clients are denied.

Some of the older Cisco IOS code in the lab only offers legacy SSH cryptographic algorithms. I documented that separately because it was an SSH compatibility problem rather than an ACL or routing problem:

[SSH Cryptographic Compatibility on Older Cisco IOS](../08-Troubleshooting/ssh-key-exchange-compatibility.md)

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

The ACLs handle two things:

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

Applying the ACL inbound means traffic is checked as it enters CORESW1 from that user VLAN, before the core routes it somewhere else.

### Server access policy

Current server addresses:

| Server | Address | Access |
|---|---|---|
| DC01 | 10.0.20.3 | normal domain services from all user VLANs |
| FS01 | 10.0.20.4 | SMB from all user VLANs |
| HR onboarding site on FS01 | 10.0.20.4 TCP 80 | Human Resources and I.T. only |
| Proxmox | 10.0.20.10 | dedicated I.T. admin workstation only |

User VLANs are allowed full IP access to **DC01** for normal Active Directory/domain services. Domain clients rely on several services and RPC ranges, so DC01 is treated as an approved infrastructure host while the rest of the Server VLAN remains restricted.

All user VLANs are allowed to reach **FS01 over TCP 445** for SMB/file shares.

Shipping, Accounting, and Executives follow this server pattern:

~~~cisco
permit ip <user-subnet> host 10.0.20.3
permit tcp <user-subnet> host 10.0.20.4 eq 445
deny ip <user-subnet> 10.0.20.0 0.0.0.255
~~~

#### Standard user VLAN example — Shipping

<img width="596" height="185" alt="Final SHIPPING-IN ACL" src="https://github.com/user-attachments/assets/788b0605-ae02-41a8-8860-ab8d339c6f4c" />

Shipping can reach SMB on FS01, while Proxmox management is blocked:

<img width="885" height="571" alt="Shipping SMB allowed and Proxmox management blocked" src="https://github.com/user-attachments/assets/e60954a1-3bc3-4d7f-9c52-63af6721cd22" />

<details>
<summary>Additional standard VLAN ACLs</summary>

**Accounting**

<img width="584" height="168" alt="Final ACCOUNTING-IN ACL" src="https://github.com/user-attachments/assets/dff0d507-6701-47bb-b60c-8a97289b84d7" />

**Executives**

<img width="582" height="169" alt="Final EXECUTIVES-IN ACL" src="https://github.com/user-attachments/assets/36efa13a-7b03-4e1a-952d-4b45fb9711ea" />

</details>

### Human Resources exception

Human Resources gets the same domain and SMB access as the other user VLANs, plus TCP 80 to FS01 for the onboarding site:

~~~cisco
permit tcp 10.0.120.0 0.0.0.255 host 10.0.20.4 eq 80
~~~

<img width="596" height="180" alt="Final HR-IN ACL" src="https://github.com/user-attachments/assets/e98072e2-470b-4dbf-9cc9-1605319ed161" />

The onboarding site is reachable from the HR VLAN as intended:

<img width="1289" height="632" alt="HR onboarding site accessible from the HR VLAN" src="https://github.com/user-attachments/assets/aee4a280-3a0b-49a6-8c76-f15d34e45437" />

### I.T. admin workstation exception

The dedicated I.T. admin workstation is **10.0.140.10**.

Normal I.T. clients get domain services, SMB, and access to the onboarding site. The admin workstation exception is placed before the Server VLAN and internal denies:

~~~cisco
permit ip host 10.0.140.10 10.0.0.0 0.255.255.255
~~~

<img width="536" height="171" alt="Final IT-IN ACL with dedicated admin workstation exception" src="https://github.com/user-attachments/assets/2e17e757-9e2f-44ab-97f5-3cd6dc151a69" />

That lets this one host initiate administrative traffic to internal NorthStar networks, including Proxmox, while normal I.T. clients remain restricted.

#### Proxmox validation

A normal client cannot reach the Proxmox management interface:

<img width="1365" height="631" alt="Proxmox management blocked from a non-admin client" src="https://github.com/user-attachments/assets/d185aad1-0d72-4fd9-9ab2-a0c130715806" />

The dedicated admin workstation can reach it:

<img width="1014" height="560" alt="Proxmox management reachable from the dedicated IT admin workstation" src="https://github.com/user-attachments/assets/0c1c9804-c719-492a-8c85-1811418d5f20" />

The other user VLAN ACLs also need return-path exceptions because standard IOS ACLs are stateless.

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

Accounting was also tested directly for allowed SMB access and blocked Proxmox management:

<img width="896" height="550" alt="Accounting SMB allowed and Proxmox management blocked" src="https://github.com/user-attachments/assets/a2ca033d-28e5-48ed-8980-5f26af2af26f" />

Before ACL testing, I also had to allow ICMPv4 Echo Requests through Windows Defender Firewall on the test clients so endpoint firewall behavior would not be confused with an ACL deny.

That troubleshooting note is here:

[Windows Firewall Blocking Inter-VLAN Ping](../08-Troubleshooting/windows-firewall-icmp-testing.md)


## Server VLAN hardening

The Server VLAN is **Vlan20 / 10.0.20.0/24**.

I added a named extended ACL called **SERVER-IN** and applied it inbound on the Vlan20 SVI:

~~~cisco
interface Vlan20
 ip access-group SERVER-IN in
~~~

<img width="636" height="233" alt="SERVER-IN applied inbound on Vlan20" src="https://github.com/user-attachments/assets/264426ad-79d0-426d-a3d9-0ebfc79a58af" />

This controls traffic as it leaves the Server VLAN and enters CORESW1 for routing toward other networks.

### Current SERVER-IN policy

~~~cisco
5 deny ip 10.0.20.0 0.0.0.255 192.168.1.0 0.0.0.255
10 permit ip host 10.0.20.3 any
20 permit tcp host 10.0.20.4 10.0.0.0 0.255.255.255 established
30 permit tcp host 10.0.20.10 host 10.0.140.10 established
32 permit icmp host 10.0.20.10 host 10.0.140.10 echo-reply
40 deny ip 10.0.20.0 0.0.0.255 10.0.0.0 0.255.255.255
50 permit ip 10.0.20.0 0.0.0.255 any
~~~

<img width="652" height="175" alt="Final SERVER-IN ACL" src="https://github.com/user-attachments/assets/2f892b70-526e-405b-b228-58cc4d11e066" />

The policy is intentionally ordered so the home network deny is evaluated before the broader DC01 permit.

Current behavior:

| Source | Allowed behavior |
|---|---|
| Any Server VLAN host | blocked from initiating traffic into the home LAN at 192.168.1.0/24 |
| DC01 - 10.0.20.3 | allowed to communicate with internal NorthStar networks and external destinations |
| FS01 - 10.0.20.4 | allowed to send established TCP return traffic toward internal clients |
| Proxmox - 10.0.20.10 | allowed to return established TCP and ICMP echo-reply traffic to 10.0.140.10 |
| Other Server VLAN traffic | blocked from initiating into the internal 10.0.0.0/8 space |
| Remaining Server VLAN traffic | allowed toward external destinations |

DC01 remains broadly permitted after the home-network deny because Active Directory, DNS, DHCP, Kerberos, and RPC dependencies make it an infrastructure host in the current design.

The `established` keyword is still a stateless ACL check based on TCP ACK/RST flags. It allows expected return TCP traffic without creating a state table.

### Validation

I tested the Server VLAN policy and confirmed:

- a normal user workstation can still reach FS01 over SMB/TCP 445
- FS01 cannot initiate traffic to the home network at 192.168.1.0/24

<img width="907" height="323" alt="FS01 blocked from reaching the home LAN" src="https://github.com/user-attachments/assets/a701d92a-9ac8-4eb3-83df-a9bd6e217420" />

- the home-network deny entry increments its match counter during testing
- FS01 cannot initiate traffic toward another internal NorthStar VLAN

<img width="797" height="215" alt="FS01 blocked from initiating toward a user VLAN" src="https://github.com/user-attachments/assets/fd7dc8ac-06cb-45be-9e6e-37554e8f9447" />

- the internal 10.0.0.0/8 deny entry matches the blocked server-originated traffic
- the dedicated admin workstation at 10.0.140.10 can still reach Proxmox on TCP 8006

<img width="755" height="199" alt="Dedicated IT admin workstation can reach Proxmox on TCP 8006" src="https://github.com/user-attachments/assets/45312898-3159-407c-93c2-5a306acc1ce7" />

- a normal user workstation cannot reach the Proxmox management interface

This adds server-originated traffic control without changing the existing user-to-server service policy.


