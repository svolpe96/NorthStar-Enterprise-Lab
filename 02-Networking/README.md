# Networking

I'm using CORESW1 for the Layer 3 side of the lab and keeping ASW1/ASW2 as Layer 2 access switches.

## What is working so far

- VLAN segmentation
- SVIs on CORESW1
- inter-VLAN routing
- Rapid PVST+
- CORESW1 as spanning-tree root
- LACP EtherChannels to the access switches
- 802.1Q trunks
- DHCP relay to DC01
- default route toward the NY router
- NAT/PAT on the NY router
- SSH management
- NTP
- PortFast and BPDU Guard on endpoint ports
- simulated NY-to-FL WAN through a routed ISP container
- GRE tunnel between NY and FL
- OSPF Area 0 adjacency between NY and FL over GRE
- OSPF Area 0 adjacency between CORESW1 and NY

## Core routing

CORESW1 has IP routing enabled and uses the NY router as the default route:

```cisco
ip routing
ip route 0.0.0.0 0.0.0.0 10.255.255.1
```

## DHCP relay

DC01 is the DHCP server at **10.0.20.3**. Client VLAN SVIs use:

```cisco
ip helper-address 10.0.20.3
```

## Spanning tree

I'm running Rapid PVST+ and keeping CORESW1 as the root for the lab VLANs.

One thing I had to clean up during the rebuild was PortFast/BPDU Guard placement. I only want those on real endpoint-facing access ports, not switch or router uplinks.

## Multi-site WAN

NY and FL now use separate simulated WAN circuits instead of a direct router-to-router cable.

A lightweight Debian LXC container in Proxmox acts as the ISP between VLAN 901 and VLAN 902, and a GRE tunnel provides the private overlay between the two Cisco routers.

Current tunnel addresses:

- NY Tunnel0: **10.255.254.1/30**
- FL Tunnel0: **10.255.254.2/30**

The underlay and GRE tunnel have been tested successfully in both directions.

Detailed build notes: [Multi-Site WAN](../11-Multi-Site-WAN/README.md)

## OSPF

OSPF process 1 is now running through the multi-site path.

Current router IDs:

- CORESW1: **3.3.3.3**
- NY: **1.1.1.1**
- FL: **2.2.2.2**

NY and FL have formed a full OSPF adjacency across `Tunnel0`, and CORESW1 has formed a full adjacency with NY across the existing routed transit link.

I am using `passive-interface default` and only making the actual router-to-router links non-passive. This keeps OSPF from trying to form neighbor relationships on user-facing networks.

FL also has a test internal network represented by `Loopback10`:

- FL LAN: **10.1.10.0/24**
- Loopback10: **10.1.10.1/24**

The loopback uses OSPF point-to-point network behavior so the full /24 can be advertised instead of only a /32 host route.

I advertised all five NY department VLANs (100, 110, 120, 130, and 140) and verified that FL learned their /24 networks dynamically through the GRE tunnel. NY also learned FL's simulated 10.1.10.0/24 LAN. I tested OSPF route withdrawal by shutting down NY Tunnel0 and restoring it afterward. The FL-to-HR endpoint test also exposed a return-traffic ACL issue, which I fixed with a narrowly scoped permit.

Detailed build notes: [Multi-Site WAN](../11-Multi-Site-WAN/README.md)
