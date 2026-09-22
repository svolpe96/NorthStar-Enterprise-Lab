# Active Directory

The lab domain is **north.local**.

## DC01

DC01 is currently doing most of the Windows infrastructure work:

- Active Directory Domain Services
- DNS
- DHCP
- Group Policy

IP: **10.0.20.3**

## OU layout

I'm starting to separate servers, users, and workstations so I can apply policies without throwing everything into the default containers.

Current layout:

- Domain Controllers
- Servers
- Building
  - NorthStarHQ
    - Computers
    - Users

FS01 is in the **Servers** OU. DC01 stays in **Domain Controllers**.

## What I'm using AD for in the lab

- domain joining clients
- user authentication
- computer policies
- DNS
- DHCP
- Group Policy
- file-share permissions / groups

The OU structure will probably keep changing as the lab gets bigger.
