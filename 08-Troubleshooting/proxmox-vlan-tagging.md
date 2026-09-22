# Proxmox VLAN Tagging Mismatch

## What happened

While I was setting up FS01, it couldn't reach the gateway or the Internet.

DC01 was already working on the same Proxmox host, so I started comparing the VM network settings.

## What I found

The switchport going to Proxmox was already configured as an access port in VLAN 20.

DC01 was connected to `vmbr0` with **no VLAN tag**, but I had added VLAN tag 20 to FS01 inside Proxmox.

That was the difference.

## Cause

I was trying to tag VLAN 20 in two different places.

The physical switchport was already putting untagged traffic into VLAN 20, so tagging the VM NIC itself didn't match the access-port setup I was using.

## Fix

I removed VLAN tag 20 from the FS01 VM NIC.

## After the change

FS01 was able to:
- reach 10.0.20.1
- reach the Internet
- resolve DNS
- communicate with the domain again

This was a good reminder to check where VLAN tagging is actually supposed to happen before adding tags everywhere.
