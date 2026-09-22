# Active Directory

NorthStar uses the **north.local** Active Directory domain.

## DC01

DC01 currently provides:
- Active Directory Domain Services
- DNS
- DHCP
- Group Policy

IP address: **10.0.20.3**

## OU design

The domain is being organized so infrastructure and endpoints can receive separate policies.

Current design includes:
- Domain Controllers
- Servers
- Building
  - NorthStarHQ
    - Computers
    - Users

FS01 was moved into the dedicated **Servers** OU.

## Domain clients

Windows 11 systems are joined to the domain and used to test:
- user authentication
- computer policies
- DNS
- DHCP
- Group Policy
- file-share access

## Time hierarchy

DC01 synchronizes with an external NTP source. Domain members are intended to follow the Active Directory domain time hierarchy.
