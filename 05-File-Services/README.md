# File Services

FS01 is the dedicated NorthStar file server.

- Hostname: **FS01**
- IP: **10.0.20.4**
- VLAN: **20 - Servers**
- Domain: **north.local**

## Planned drive structure

| Drive | Purpose | Access |
|---|---|---|
| H: | Individual user home directory | Individual user |
| P: | Personnel files | HR + Executives |
| E: | Executive files | Executives only |

## Design goals

- use Active Directory security groups rather than individual user permissions
- separate share permissions from NTFS permissions
- automatically map drives based on user/group membership
- validate access using test accounts from different departments
- document successful and denied access tests

## Current status

FS01 has been created in Proxmox, joined to the domain, and moved to the **Servers** OU.

The next phase is to create the production share structure and replace the temporary TestShare with the final H:, P:, and E: design.
