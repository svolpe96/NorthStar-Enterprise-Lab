# IP Addressing Plan

| VLAN | Name | Network | Default Gateway |
|---:|---|---|---|
| 10 | Management | 10.0.10.0/24 | 10.0.10.1 |
| 20 | Servers | 10.0.20.0/24 | 10.0.20.1 |
| 100 | Shipping | 10.0.100.0/24 | 10.0.100.1 |
| 110 | Accounting | 10.0.110.0/24 | 10.0.110.1 |
| 120 | Human Resources | 10.0.120.0/24 | 10.0.120.1 |
| 130 | Executives | 10.0.130.0/24 | 10.0.130.1 |
| 140 | IT | 10.0.140.0/24 | 10.0.140.1 |
| 999 | Native / unused | N/A | N/A |

## Server addresses

- DC01: **10.0.20.3**
- FS01: **10.0.20.4**
- Proxmox: **10.0.20.10**

## Transit network

- HQ router: **10.255.255.1/24**
- CORESW1: **10.255.255.2/24**


## Addressing Reasoning

I used the 10.0.0.0/8 private address range because it gives me plenty of room to expand the lab while keeping the addressing simple and easy to recognize. I assigned each department its own /24 subnet and used the third octet to match the VLAN number where possible, such as VLAN 100 using 10.0.100.0/24 and VLAN 140 using 10.0.140.0/24.

This makes it easier for me to look at an IP address and quickly tell which VLAN or department it belongs to. I also separated infrastructure networks such as Management and Servers from the user VLANs so I can apply different routing, security, and access policies later as the lab grows.

For the router-to-core transit network, I used the 10.255.255.0 range to keep point-to-point infrastructure links separate from the normal LAN networks.
