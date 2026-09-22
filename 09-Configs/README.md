# Device Configurations

This folder will contain sanitized configuration backups and rebuild documentation for NorthStar network devices.

Planned files:
- `CORESW1.txt`
- `ASW1.txt`
- `ASW2.txt`
- `R1.txt`
- `R2.txt`

## Publishing rules

Before publishing any configuration:
- remove passwords and secrets
- do not publish RSA private key material
- remove unnecessary serial numbers or identifying information
- review public/WAN addressing before publishing
- keep useful interface, VLAN, routing, STP, EtherChannel, NTP, and management configuration
