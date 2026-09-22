# NorthStar Project Log

This is just a running log of what I'm working on and problems I run into. It is not meant to be polished documentation.

## September 22, 2026

### FS01 / file services

Started working on the file-server side of the lab.

FS01 is built in Proxmox, joined to **north.local**, and sitting in the **Servers** OU.

Current plan:
- H: user home drives
- P: Personnel share
- E: Executive share

I still need to build the final folder structure, groups, permissions, and GPO drive mappings.

### FS01 time / domain issue

Ran into a really strange issue where FS01 somehow ended up with the year set to **3964**.

The machine still had basic network connectivity, but:
- computer-side GPO failed
- SMB/domain authentication started throwing clock errors
- secure-channel verification returned access denied

I checked DNS, LDAP, SMB, DC discovery, and NTP communication before fixing anything.

After getting the clock back into a normal range and repairing the computer secure channel, `gpupdate /force` started working again.

Full write-up:
[FS01 Time / Secure Channel Failure](08-Troubleshooting/fs01-time-secure-channel.md)

### Proxmox VLAN issue

While setting up FS01, I accidentally tagged VLAN 20 inside Proxmox even though the physical switchport was already an access port in VLAN 20.

That killed connectivity until I removed the VM VLAN tag.

Full write-up:
[Proxmox VLAN Tagging Mismatch](08-Troubleshooting/proxmox-vlan-tagging.md)

## Earlier work

### Network rebuild

The original build started in Jan 2026. Later in the year the access switch failed, so I had to rebuild the switching side of the lab on replacement hardware.

Things rebuilt / verified:
- VLANs
- trunks
- LACP EtherChannels
- Rapid PVST+
- management access
- DHCP relay
- routing
- NAT/PAT
- NTP
- SSH

I still want to write up the hardware failure and rebuild separately because it ended up being a good troubleshooting / recovery example.
