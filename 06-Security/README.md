# Security

Security controls implemented or planned in NorthStar.

## Implemented

- SSH management on Cisco devices
- local administrative accounts
- RSA keys
- SSH v2
- management VLAN
- PortFast on endpoint access ports
- BPDU Guard on endpoint access ports
- unused VLAN 999 used as native/parking VLAN in the switching design
- Windows Firewall used on servers/endpoints

## Planned

- extended ACLs between business VLANs
- restrict Shipping, Accounting, and HR access to the Executive VLAN
- permit appropriate IT and Executive access
- DHCP Snooping
- Dynamic ARP Inspection
- IP Source Guard
- LAPS
- improved Windows security GPOs
- centralized logging and monitoring
