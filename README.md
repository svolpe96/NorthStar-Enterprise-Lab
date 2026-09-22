# NorthStar Enterprise Lab

NorthStar is a physical/virtual enterprise infrastructure homelab built to practice networking, systems administration, Active Directory, virtualization, security controls, troubleshooting, and eventually hybrid Azure integration.

## Project goals

- Build a realistic multi-VLAN enterprise network using Cisco switching and routing.
- Run Windows Server services including Active Directory Domain Services, DNS, DHCP, Group Policy, and file services.
- Host infrastructure workloads in Proxmox.
- Practice centralized management, security hardening, monitoring, troubleshooting, and documentation.
- Use the lab as a portfolio project that demonstrates both implementation and problem-solving.

## Current environment

### Networking
- Layer 3 core switch with inter-VLAN routing
- Two Layer 2 access switches
- HQ router connected to the home network / Internet
- Branch router planned
- Rapid PVST+
- LACP EtherChannel uplinks
- NAT/PAT
- DHCP relay
- SSH management
- Centralized NTP
- PortFast and BPDU Guard on endpoint-facing ports

### VLANs

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

### Windows infrastructure
- **DC01** — Active Directory, DNS, DHCP, Group Policy
- **FS01** — dedicated file server
- Domain: **north.local**
- Proxmox hosts the Windows Server VMs
- Domain-joined Windows 11 endpoints simulate company workstations

## Documentation

- [Architecture](01-Architecture/README.md)
- [Networking](02-Networking/README.md)
- [Active Directory](03-Active-Directory/README.md)
- [Group Policy](04-Group-Policy/README.md)
- [File Services](05-File-Services/README.md)
- [Security](06-Security/README.md)
- [Proxmox](07-Proxmox/README.md)
- [Troubleshooting](08-Troubleshooting/README.md)
- [Device Configurations](09-Configs/README.md)
- [Validation](10-Validation/README.md)

## Current work

The current subproject is the deployment of **FS01** and centralized file services:

- **H:** private home drive for each user
- **P:** Personnel drive for HR and Executives
- **E:** Executive-only drive

The design will use Active Directory security groups, share/NTFS permissions, and Group Policy drive mapping.

## Future expansion

Planned work includes branch connectivity, OSPF, inter-VLAN ACLs, wireless, VoIP, centralized logging/monitoring, backups, additional Group Policy security baselines, and hybrid Azure integration.
