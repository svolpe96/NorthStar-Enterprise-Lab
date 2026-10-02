# NorthStar Enterprise Environment

A physical enterprise-style environment I built to design, secure, automate, and troubleshoot infrastructure across Cisco networking, Windows Server, Active Directory, virtualization, and security.

<img width="1200" alt="NorthStar physical enterprise environment" src="https://github.com/user-attachments/assets/02263361-6f1f-4de6-9fb4-b68c126f9874" />

## What I Built

- Cisco Layer 3 / Layer 2 network with VLANs, SVIs, 802.1Q trunks, LACP EtherChannels, Rapid PVST+, NAT/PAT, DHCP relay, SSH, and NTP
- Inter-VLAN segmentation using named extended ACLs
- Service-based access controls into the Server VLAN and ACLs controlling server-originated traffic
- Dedicated I.T. admin workstation for restricted infrastructure management and Proxmox access
- Proxmox virtualization hosting Windows Server infrastructure
- Active Directory, DNS, DHCP, Group Policy, file services, quotas, and department-based permissions
- Internal HR onboarding portal using IIS and PowerShell automation
- Troubleshooting documentation for issues encountered during the build

## Environment at a Glance

**Networking:** Cisco IOS / IOS-XE, VLANs, Layer 3 routing, ACLs, STP, EtherChannel, NAT/PAT  
**Identity:** Active Directory, security groups, delegated permissions  
**Systems:** Windows Server, Windows 11, Proxmox  
**Security:** network segmentation, management-plane restrictions, service-based server access  
**Automation:** PowerShell-based employee onboarding  
**Documentation:** architecture, troubleshooting, validation, and project history

## Core Infrastructure

### Network

- **CORESW1** handles Layer 3 routing and the VLAN SVIs
- **ASW1 / ASW2** operate as Layer 2 access switches
- **NY router** provides the path toward the home network / Internet
- SSH management is restricted to a dedicated I.T. admin workstation
- User VLANs are segmented with inbound named extended ACLs
- Server access is restricted by service, with separate controls on server-originated traffic

### Windows / Virtualization

- **Proxmox** hosts the server VMs
- **DC01 - 10.0.20.3** - AD DS, DNS, DHCP, Group Policy
- **FS01 - 10.0.20.4** - file services and current host for the internal onboarding site
- Domain: **north.local**
- Windows 11 clients are used as department test endpoints

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

## Windows Infrastructure

FS01 provides user home folders, department file shares, quotas, and GPO drive mappings.

I also built an internal HR onboarding site that creates new Active Directory users, places them in the correct department, assigns group membership, and creates their home folder.

Department groups are used as the main entry point for permissions, with resource access handled through nested security groups instead of assigning permissions directly to individual users.

## Project Sections

- [Architecture](01-Architecture/README.md)
- [Networking](02-Networking/README.md)
- [Active Directory](03-Active-Directory/README.md)
- [Group Policy](04-Group-Policy/README.md)
- [File Services](05-File-Services/README.md)
- [Security](06-Security/README.md)
- [Proxmox](07-Proxmox/README.md)
- [Troubleshooting](08-Troubleshooting/README.md)
- [HR Onboarding](10-HR-Onboarding/README.md)
- [Project Log](PROJECT-LOG.md)

## Planned Expansion

- branch connectivity
- OSPF
- wireless / VoIP
- centralized logging and monitoring
- backups / restore testing
- additional security controls
- hybrid Azure integration
