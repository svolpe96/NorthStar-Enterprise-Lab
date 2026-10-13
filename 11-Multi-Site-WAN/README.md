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

### NY department routes advertised

After confirming the adjacencies, I enabled OSPF Area 0 on the five department SVIs on CORESW1. I kept the user-facing SVIs passive: their networks are advertised, but they do not try to form OSPF neighbors with workstations.

| VLAN | Department | Advertised network |
|---:|---|---|
| 100 | Shipping | `10.0.100.0/24` |
| 110 | Accounting | `10.0.110.0/24` |
| 120 | Human Resources | `10.0.120.0/24` |
| 130 | Executives | `10.0.130.0/24` |
| 140 | IT | `10.0.140.0/24` |

The relevant interface-level configuration follows this pattern:

```cisco
interface Vlan120
 ip ospf 1 area 0
```

On FL, `show ip route ospf` confirmed all five networks were learned through `10.255.254.1` on `Tunnel0`. The NY-to-core transit network `10.255.255.0/24` was also advertised. On NY, the Florida test LAN appeared as an intra-area OSPF route:

```text
10.1.10.0/24
Known via "ospf 1", distance 110, metric 1001
via 10.255.254.2, Tunnel0
```

### End-to-end test and ACL troubleshooting

I first confirmed FL could ping the HR VLAN gateway at `10.0.120.1` using `Loopback10` as the source. Then I tested a real Windows 11 HR workstation at `10.0.120.51`.

The workstation initially had an incorrect persistent default route toward `10.0.10.1`, alongside its correct DHCP gateway `10.0.120.1`. I removed the incorrect persistent route. I also allowed ICMPv4 Echo Requests from `10.1.10.1` through Windows Defender Firewall, but the ping still failed.

The remaining issue was the inbound `HR-IN` ACL on CORESW1. Florida's Echo Request could reach HR, but the HR workstation's Echo Reply entered the VLAN 120 SVI and hit the existing deny for destinations in `10.0.0.0/8`. Florida's `10.1.10.1` address is inside that range.

I added a narrow exception **before** the broad deny:

```cisco
ip access-list extended HR-IN
 85 permit icmp host 10.0.120.51 host 10.1.10.1 echo-reply
```

After that change, the FL-to-HR workstation ping succeeded. I kept the exception limited to this host, remote source, and ICMP reply type rather than opening general access between sites. This is a test-specific allowance, not a finished inter-site security policy.

More detail: [FL-to-HR ping blocked by ACL](../08-Troubleshooting/fl-to-hr-acl-return-traffic.md).

### OSPF withdrawal and recovery test

To see how OSPF responds to a lost tunnel, I checked the NY router's neighbors and route table, then temporarily shut down `Tunnel0`.

Before the shutdown, NY showed:

- FL neighbor `2.2.2.2` in `FULL` state on `Tunnel0`
- CORESW1 neighbor `3.3.3.3` in `FULL` state
- `10.1.10.0/24` learned via OSPF through `10.255.254.2`

With `Tunnel0` shut down, FL disappeared from the OSPF neighbor table and the specific `10.1.10.0/24` OSPF route was withdrawn. CORESW1 remained a FULL neighbor. A lookup for `10.1.10.0` then matched the existing broader static `10.0.0.0/8` route via `10.255.255.2`. That is a fallback routing-table match, **not** proof that Florida was still reachable.

I restored the tunnel with `no shutdown`, and the Florida connection came back. The final neighbor and route output should be captured as a screenshot for the repository.

This test demonstrates neighbor loss and route withdrawal on the existing single path. There is no redundant WAN path, so I am not calling this a failover test.

## Current scope and possible later work

The simulated FL site only needs to demonstrate WAN connectivity and routing. I am not building out a Florida workstation or full branch-office infrastructure right now.

Possible later improvements include GRE encryption with IPsec, more deliberate inter-site access controls, and route design review. Those are **not implemented** as part of this project.
