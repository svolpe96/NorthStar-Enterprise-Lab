# NorthStar Enterprise Lab

NorthStar is my home enterprise environment. I built it to get more hands-on with Cisco networking, Windows Server, Active Directory, Proxmox, security, troubleshooting, and eventually Azure.

This repo is a work in progress. I'm using it to keep track of what I've built, what changed, what broke, and how I fixed it.

## Current setup

### Network
- CORESW1 handles Layer 3 routing for the lab
- ASW1 and ASW2 are Layer 2 access switches
- HQ router provides the path out to my home network / Internet
- Rapid PVST+
- LACP EtherChannels
- NAT/PAT
- DHCP relay
- SSH management
- NTP
- PortFast / BPDU Guard on endpoint-facing ports

### Windows / virtualization
- **Proxmox** hosts the server VMs
- **DC01 - 10.0.20.3** - AD DS, DNS, DHCP, Group Policy
- **FS01 - 10.0.20.4** - file server and current lab host for the internal onboarding site
- Domain: **north.local**
- Windows 11 clients are used as test endpoints

## VLANs

| VLAN | Purpose | Subnet | Gateway |
|---:|---|---|---|
| 10 | Management | 10.0.10.0/24 | 10.0.10.1 |
| 20 | Servers | 10.0.20.0/24 | 10.0.20.1 |
| 100 | Shipping | 10.0.100.0/24 | 10.0.100.1 |
| 110 | Accounting | 10.0.110.0/24 | 10.0.110.1 |
| 120 | Human Resources | 10.0.120.0/24 | 10.0.120.1 |
| 130 | Executives | 10.0.130.0/24 | 10.0.130.1 |
| 140 | IT | 10.0.140.0/24 | 10.0.140.1 |
| 999 | Native / unused | N/A | N/A |

## Current Windows work

FS01 now has user home folders, department shares, quotas, and GPO drive mappings.

I also built a small internal HR onboarding site. An authorized HR user can create an employee, and the backend handles the AD account, department placement, department group membership, and home folder.

Department groups are being used as the main entry point for permissions. Instead of assigning access user by user, I can nest a department group into the resource groups that department needs.

## Project sections

- [Architecture](01-Architecture/README.md)
- [Networking](02-Networking/README.md)
- [Active Directory](03-Active-Directory/README.md)
- [Group Policy](04-Group-Policy/README.md)
- [File Services](05-File-Services/README.md)
- [Security](06-Security/README.md)
- [Proxmox](07-Proxmox/README.md)
- [Troubleshooting](08-Troubleshooting/README.md)
- [Device Configs](09-Configs/README.md)
- [HR Onboarding](10-HR-Onboarding/README.md)
- [Project log](PROJECT-LOG.md)

## Things I want to add later

- branch connectivity
- OSPF
- inter-VLAN ACLs
- wireless / VoIP
- centralized logging and monitoring
- backups / restore testing
- more security controls
- hybrid Azure integration

I'll keep updating this as the lab changes.
