# File Services

This is the part of the lab I'm working on right now.

FS01 is my dedicated file server:

- Hostname: **FS01**
- IP: **10.0.20.4**
- VLAN: **20 - Servers**
- Domain: **north.local**

## What I want the final setup to look like

| Drive | Use | Who should get it |
|---|---|---|
| H: | User home folder | each individual user |
| P: | Personnel files | HR + Executives |
| E: | Executive files | Executives only |

I want permissions to be group-based instead of assigning individual users directly.

That means I still need to finish:
- AD security groups
- folder structure
- share permissions
- NTFS permissions
- drive mappings
- testing with different user accounts

## Current status

FS01 is:
- built in Proxmox
- on VLAN 20
- joined to north.local
- moved into the **Servers** OU

I made a temporary TestShare while troubleshooting connectivity, but that is not the final file-share layout.

There have already been a couple good troubleshooting cases around FS01, especially Proxmox VLAN tagging and the time/secure-channel issue. Those are under [Troubleshooting](../08-Troubleshooting/README.md).
