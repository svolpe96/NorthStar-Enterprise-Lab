# Networking

NorthStar uses a hierarchical switching/routing design with a Layer 3 core and Layer 2 access switches.

## Implemented

- VLAN segmentation
- SVIs on CORESW1
- inter-VLAN routing
- Rapid PVST+
- CORESW1 configured as spanning-tree root
- LACP EtherChannels between core and access switches
- 802.1Q trunks
- access-port VLAN assignments
- DHCP relay using `ip helper-address 10.0.20.3`
- default routing toward the HQ router
- NAT/PAT at the HQ router
- SSH management
- NTP
- PortFast and BPDU Guard on endpoint-facing ports

## Core routing

CORESW1 uses:

```cisco
ip routing
ip route 0.0.0.0 0.0.0.0 10.255.255.1
```

The HQ router maintains a return route toward the internal lab networks through CORESW1.

## DHCP relay

User VLAN SVIs relay DHCP broadcasts to DC01:

```cisco
ip helper-address 10.0.20.3
```

## Spanning Tree

Rapid PVST+ is used. CORESW1 is the preferred root bridge for the production VLANs.

PortFast and BPDU Guard are limited to true endpoint-facing access ports, not infrastructure links.
