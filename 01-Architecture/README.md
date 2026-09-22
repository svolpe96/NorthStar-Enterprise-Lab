# Architecture

This section documents the design of the NorthStar Enterprise Lab.

## Core design

NorthStar is built as a small enterprise environment with routing, core, and access-layer switching, Windows Server infrastructure, Proxmox virtualization, and multiple business VLANs.

### Main infrastructure

- **CORESW1** — Layer 3 core switch and default gateway for internal VLANs
- **ASW1 / ASW2** — Layer 2 access switches
- **HQ router** — edge router between the lab and the home network / Internet
- **Branch router** — planned branch connectivity
- **Proxmox** — virtualization platform
- **DC01** — Active Directory, DNS, DHCP, Group Policy
- **FS01** — file services
- Windows 11 laptops — simulated enterprise endpoints

## Routing path

Internal endpoints use their VLAN SVI on CORESW1 as the default gateway. CORESW1 sends default traffic to the HQ router over the 10.255.255.0/24 transit network.

- CORESW1: **10.255.255.2**
- HQ router: **10.255.255.1**

The HQ router performs NAT/PAT before forwarding traffic toward the home network and Internet.

## Documentation goals

This folder will eventually contain:
- logical topology
- physical topology
- device inventory
- IP addressing plan
- service placement
- future hybrid Azure architecture
