# Architecture

This is the current layout of NorthStar.

## Main pieces

- **CORESW1** - Layer 3 core switch and default gateway for the VLANs
- **ASW1 / ASW2** - Layer 2 access switches
- **HQ router** - connects the lab toward the home network / Internet
- **Branch router** - planned for later
- **Proxmox** - hosts the server VMs
- **DC01** - Active Directory, DNS, DHCP, Group Policy
- **FS01** - file server
- Windows 11 laptops - test clients

## Routing

The client VLANs use SVIs on CORESW1 as their default gateways.

CORESW1 sends default traffic to the HQ router over the transit network:

- HQ router: **10.255.255.1**
- CORESW1: **10.255.255.2**

The HQ router then handles NAT/PAT out toward my home network.

I still want to add a proper logical and physical diagram here once I settle on the final layout.
