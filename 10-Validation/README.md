# Validation

This folder tracks proof that the environment works as designed.

## Examples to capture

### Networking
- `show ip interface brief`
- `show vlan brief`
- `show interfaces trunk`
- `show etherchannel summary`
- `show spanning-tree root`
- `show ip route`
- successful endpoint Internet connectivity

### NTP
- `show ntp status`
- `show ntp associations`
- `w32tm /query /source`
- `w32tm /query /status`

### Group Policy
- `gpresult /scope computer /r`
- successful `gpupdate /force`
- `tzutil /g` showing Eastern Standard Time

### Active Directory / File Services
- domain membership
- mapped H:, P:, and E: drives
- successful/denied access based on department membership

Screenshots should be used selectively as evidence, not as a replacement for written documentation.
