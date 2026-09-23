# Proxmox

Proxmox is hosting the Windows Server side of NorthStar.

## Current VMs

### DC01
- Windows Server
- IP 10.0.20.3
- AD DS
- DNS
- DHCP
- Group Policy

### FS01
- Windows Server
- IP 10.0.20.4
- file server

## One thing I learned the hard way

The physical switchport connected to Proxmox is already an **access port in VLAN 20**.

I originally added VLAN tag 20 to FS01 inside Proxmox too, which killed connectivity. Once I removed the VM-level VLAN tag, FS01 could reach the gateway and domain again.

So for this setup, the VM NICs on `vmbr0` are staying untagged and the physical switchport handles the VLAN assignment.

I wrote up the full issue here:
[Proxmox VLAN tagging mismatch](../08-Troubleshooting/proxmox-vlan-tagging.md)
