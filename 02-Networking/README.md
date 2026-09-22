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
- default route toward the HQ router
- NAT/PAT on the HQ router
- SSH management
- NTP
- PortFast and BPDU Guard on endpoint ports

## Core routing

CORESW1 has IP routing enabled and uses the HQ router as the default route:

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
