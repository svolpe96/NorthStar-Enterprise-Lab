# Multi-Site WAN

This section documents the simulated WAN between the New York and Florida sites.

The goal is to make the two physical Cisco routers behave like separate geographic locations instead of connecting them directly with one Ethernet cable.

## Current design

~~~text
NY
203.0.113.2/30
      |
   VLAN 901
      |
203.0.113.1/30
     ISP
198.51.100.1/30
      |
   VLAN 902
      |
198.51.100.2/30
      FL

GRE overlay:
NY Tunnel0  10.255.254.1/30
        <---------------->
FL Tunnel0  10.255.254.2/30
~~~

The ISP is a lightweight Debian 12 LXC container running on Proxmox. It has two virtual interfaces and IPv4 forwarding enabled so it can route between the two simulated WAN circuits.

## WAN VLANs

| VLAN | Purpose |
|---:|---|
| 901 | NY-to-ISP WAN |
| 902 | FL-to-ISP WAN |

The Proxmox switchport on ASW2 was converted from an access port in VLAN 20 to a trunk:

- native VLAN 20 keeps normal Proxmox management untagged
- VLAN 901 carries the NY-side ISP circuit
- VLAN 902 carries the FL-side ISP circuit

The Proxmox bridge `vmbr0` is VLAN-aware so the ISP container can attach one interface to each WAN VLAN.

## ISP container

The ISP container is intentionally small because it only needs to route between the two WAN networks.

Current interfaces:

| Interface | VLAN | Address |
|---|---:|---|
| eth0 | 901 | 203.0.113.1/30 |
| eth1 | 902 | 198.51.100.1/30 |

IPv4 forwarding is enabled and made persistent with:

~~~text
net.ipv4.ip_forward=1
~~~

## Site WAN interfaces

### New York

~~~text
GigabitEthernet0/2
203.0.113.2/30
~~~

NY reaches the Florida WAN network through the ISP at `203.0.113.1`.

### Florida

~~~text
GigabitEthernet0/2
198.51.100.2/30
~~~

FL reaches the New York WAN network through the ISP at `198.51.100.1`.

## GRE tunnel

After the WAN underlay was working in both directions, I built a GRE tunnel between the two site routers.

### NY

~~~cisco
interface Tunnel0
 description GRE-TUNNEL-TO-FL
 ip address 10.255.254.1 255.255.255.252
 tunnel source GigabitEthernet0/2
 tunnel destination 198.51.100.2
~~~

### FL

~~~cisco
interface Tunnel0
 description GRE-TUNNEL-TO-NY
 ip address 10.255.254.2 255.255.255.252
 tunnel source GigabitEthernet0/2
 tunnel destination 203.0.113.2
~~~

The tunnel was validated by successfully pinging between `10.255.254.1` and `10.255.254.2`.

## Addressing issue I caught

I originally planned to use `10.255.255.4/30` for the GRE tunnel.

IOS rejected it because the existing NY-to-core interface is actually configured as `10.255.255.1/24`, which means `10.255.255.4/30` overlaps that connected network.

Instead of changing the existing NY-to-core link during the WAN build, I moved the GRE tunnel to the separate `10.255.254.0/30` network.

## Next step

The WAN underlay and GRE overlay are working.

The next phase is to run **OSPF across Tunnel0** so the NY and FL sites can dynamically exchange their internal routes.

IPsec can be added afterward if I want to encrypt the GRE traffic across the simulated provider network.
