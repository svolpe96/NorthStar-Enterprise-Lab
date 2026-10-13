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

## OSPF

I chose OSPF even though static routes would be sufficient for the current two-site design. The goal is to make the environment easier to scale as more networks or sites are added and to get hands-on experience with dynamic routing, neighbor relationships, route advertisement, path selection, and troubleshooting.

I also chose OSPF because it is an open-standard link-state routing protocol rather than a vendor-specific protocol.

### Current OSPF design

~~~text
NY VLANs
   |
CORESW1
RID 3.3.3.3
   |
   | OSPF Area 0
   |
NY
RID 1.1.1.1
   |
   | OSPF Area 0 over GRE Tunnel0
   |
FL
RID 2.2.2.2
   |
FL test LAN
10.1.10.0/24
~~~

OSPF process **1** is being used throughout the internal NorthStar routing domain.

The router-to-router links are non-passive, while `passive-interface default` is used so user-facing networks can be advertised without trying to form OSPF neighbors with endpoints.

### FL test LAN

I created `Loopback10` on FL to represent an internal Florida network:

~~~cisco
interface Loopback10
 description FL-LAN
 ip address 10.1.10.1 255.255.255.0
 ip ospf network point-to-point
~~~

The point-to-point OSPF network type is intentional. Cisco normally advertises a loopback as a /32, so this lets the simulated Florida LAN be advertised as the full `10.1.10.0/24` network.

### FL OSPF

~~~cisco
router ospf 1
 router-id 2.2.2.2
 passive-interface default
 no passive-interface Tunnel0

interface Tunnel0
 ip ospf 1 area 0

interface Loopback10
 ip ospf 1 area 0
~~~

### NY OSPF

NY uses router ID **1.1.1.1**.

OSPF is active on:

- `Tunnel0` toward FL
- `GigabitEthernet0/1` toward CORESW1

Both links are explicitly made non-passive.

### CORESW1 OSPF

CORESW1 uses router ID **3.3.3.3**.

OSPF is active on the existing routed transit interface toward NY:

- `GigabitEthernet1/0/25`
- address: `10.255.255.2/24`
- Area 0

The NY side of that same link is `10.255.255.1/24`.

### Current validation

The following has been confirmed:

- NY and FL can ping each other across the GRE tunnel
- NY and FL have formed an OSPF adjacency across `Tunnel0`
- NY sees FL as router ID `2.2.2.2`
- CORESW1 and NY have formed an OSPF adjacency across their routed transit link
- the WAN underlay remains separate from the internal OSPF routing domain

At this point the OSPF neighbor relationships are working. The next step is route advertisement testing.

I am intentionally starting with a single NY VLAN first instead of advertising every VLAN at once. That makes it easier to prove the full route path works before expanding the configuration.

The first test will be Shipping:

- VLAN 100
- `10.0.100.0/24`

The goal is to confirm that FL learns `10.0.100.0/24` dynamically through:

~~~text
CORESW1 -> NY -> GRE Tunnel0 -> FL
~~~

Once that works, I can add the other required NY networks.

OSPF provides reachability information; it does not replace security policy. ACLs or firewall rules will still control which departments or services are actually allowed to communicate between sites.

## Next step

Advertise VLAN 100 from CORESW1, verify the OSPF route appears on FL, then expand the advertisements to the other required internal networks.

IPsec can be added afterward if I want to encrypt the GRE traffic across the simulated provider network.
