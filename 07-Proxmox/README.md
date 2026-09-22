# Proxmox

Proxmox hosts the NorthStar Windows Server infrastructure.

## Current virtual machines

### DC01
- Windows Server
- 10.0.20.3
- AD DS
- DNS
- DHCP
- Group Policy

### FS01
- Windows Server
- 10.0.20.4
- dedicated file server

## Networking lesson learned

The physical switchport connected to the Proxmox host is configured as an **access port in VLAN 20**. Because the switch performs the VLAN assignment, VM NICs using the same untagged bridge path should not also be tagged as VLAN 20 in Proxmox.

During FS01 deployment, adding VLAN tag 20 inside Proxmox caused connectivity failure. Removing the Proxmox VLAN tag restored gateway and Internet connectivity.

This incident is documented in the troubleshooting section.
