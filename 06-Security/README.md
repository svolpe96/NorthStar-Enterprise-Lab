# Security

I'm keeping this page limited to things I've actually configured or am actively working toward.

## In place now

- SSH management on Cisco devices
- SSH v2
- RSA keys for SSH
- separate management VLAN
- PortFast on endpoint access ports
- BPDU Guard on endpoint access ports
- unused ports shutdown
- VLAN 999 as the native VLAN

## Inter-VLAN ACLs

I started adding traffic controls between the user VLANs.

The ACLs are being configured on **CORESW1** because that is where the VLAN SVIs and inter-VLAN routing live.

For now I am only applying ACLs to the user VLANs:

| VLAN | Department | Network | ACL |
|---:|---|---|---|
| 100 | Shipping | 10.0.100.0/24 | SHIPPING-IN |
| 110 | Accounting | 10.0.110.0/24 | planned |
| 120 | Human Resources | 10.0.120.0/24 | planned |
| 130 | Executives | 10.0.130.0/24 | planned |
| 140 | I.T | 10.0.140.0/24 | planned |

The Server and Management VLANs are not being filtered with their own ACLs yet. I want to get the user segmentation working first before tightening those networks.

### ACL design

I am using **named extended ACLs** applied inbound on each user VLAN SVI.

The basic policy is:

~~~text
User VLAN
    ↓
Allow DHCP
Allow ping to its own gateway
Allow Server VLAN
Deny the rest of the internal 10.0.0.0/8 space
Allow external destinations / Internet
~~~

Applying the ACL inbound means traffic is checked as it enters CORESW1 from that user VLAN, before the core routes it somewhere else.

### Shipping

The first completed ACL is:

~~~cisco
ip access-list extended SHIPPING-IN
 permit udp any eq bootpc any eq bootps
 permit icmp 10.0.100.0 0.0.0.255 host 10.0.100.1 echo
 permit ip 10.0.100.0 0.0.0.255 10.0.20.0 0.0.0.255
 deny ip 10.0.100.0 0.0.0.255 10.0.0.0 0.255.255.255
 permit ip 10.0.100.0 0.0.0.255 any
~~~

It is applied inbound on:

~~~cisco
interface Vlan100
 ip access-group SHIPPING-IN in
~~~

### Why the DHCP rule is separate

A new DHCP client does not have a normal Shipping IP address yet.

Its initial request uses UDP source port 68 and destination port 67, so I allow that traffic before the normal Shipping subnet rules:

~~~cisco
permit udp any eq bootpc any eq bootps
~~~

CORESW1 then uses the existing DHCP relay configuration to forward the request toward DC01.

### Why the internal deny uses 10.0.0.0/8

The goal is to stop Shipping from reaching other internal NorthStar networks while still allowing approved exceptions above the deny.

The destination:

~~~text
10.0.0.0 0.255.255.255
~~~

matches the entire internal `10.0.0.0/8` address space.

Because ACLs are processed from top to bottom, the Server VLAN permit is matched before the broad internal deny.

### Validation

I tested the Shipping ACL from a workstation in VLAN 100.

Confirmed behavior:

- Shipping can ping its own gateway
- Shipping can reach DC01 in the Server VLAN
- Shipping can reach the Internet
- Shipping cannot ping workstations in the other user VLANs
- the deny entry showed ACL matches during testing

Before ACL testing, I also had to allow ICMPv4 Echo Requests through Windows Defender Firewall on the test clients so endpoint firewall behavior would not be confused with an ACL deny.

That troubleshooting note is here:

[Windows Firewall Blocking Inter-VLAN Ping](../08-Troubleshooting/windows-firewall-icmp-testing.md)

## Next ACL work

The same basic model will be built for:

- Accounting
- Human Resources
- Executives
- I.T

After the user VLAN ACLs are complete and tested, I can decide whether to further restrict Server and Management traffic and whether the Server VLAN permit should be narrowed to specific services instead of allowing the whole subnet.
