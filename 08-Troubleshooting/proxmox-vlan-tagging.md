# Proxmox VLAN Tagging Mismatch

## Symptom

During FS01 deployment, the new server could not reach its default gateway or the Internet. Similar connectivity issues appeared when the DC VM was manually assigned VLAN tag 20 inside Proxmox.

## Investigation

The physical Proxmox switchport was verified as an access port in VLAN 20, and VLAN 20 was present across the switching path.

The existing DC VM was using `vmbr0` with no VLAN tag, while FS01 had initially been configured with VLAN tag 20.

## Root cause

The switchport already classified untagged Proxmox traffic into VLAN 20. Adding a VLAN 20 tag at the VM level introduced a mismatch with the access-port design.

## Resolution

The VLAN tag was removed from the VM NIC configuration so the VMs used the same untagged bridge behavior as DC01.

## Validation

After removing the VM VLAN tag:
- FS01 could reach 10.0.20.1
- FS01 could reach 8.8.8.8
- DNS resolution worked
- domain connectivity was restored
