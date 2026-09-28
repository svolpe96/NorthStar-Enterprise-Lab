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
| 110 | Accounting | 10.0.110.0/24 | ACCOUNTING-IN |
| 120 | Human Resources | 10.0.120.0/24 | HR-IN |
| 130 | Executives | 10.0.130.0/24 | EXECUTIVES-IN |
| 140 | I.T | 10.0.140.0/24 | IT-IN |

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

### Completed user VLAN ACLs

The same base design is now configured on Shipping, Accounting, Human Resources, Executives, and I.T.

Shipping is an example of the base policy:

~~~cisco
ip access-list extended SHIPPING-IN
 permit udp any eq bootpc any eq bootps
 permit icmp 10.0.100.0 0.0.0.255 host 10.0.100.1 echo
 permit ip 10.0.100.0 0.0.0.255 10.0.20.0 0.0.0.255
 deny ip 10.0.100.0 0.0.0.255 10.0.0.0 0.255.255.255
 permit ip 10.0.100.0 0.0.0.255 any
~~~

The other user VLAN ACLs use the same logic with their own source subnet and gateway.

Each ACL is applied inbound on its matching SVI:

~~~text
Vlan100 -> SHIPPING-IN
Vlan110 -> ACCOUNTING-IN
Vlan120 -> HR-IN
Vlan130 -> EXECUTIVES-IN
Vlan140 -> IT-IN
~~~

### I.T. admin exception

I wanted one I.T. workstation, **10.0.140.10**, to be able to initiate administrative traffic to the other user VLANs while normal I.T. clients remain segmented.

I added this before the normal internal deny in `IT-IN`:

~~~cisco
permit ip host 10.0.140.10 10.0.0.0 0.255.255.255
~~~

The other user VLAN ACLs need return-path exceptions because standard IOS ACLs are stateless.

For example, `SHIPPING-IN` includes:

~~~cisco
permit icmp 10.0.100.0 0.0.0.255 host 10.0.140.10 echo-reply
permit tcp 10.0.100.0 0.0.0.255 host 10.0.140.10 established
~~~

Accounting, Human Resources, and Executives use the same return-path pattern with their own source subnet.

This allows:

~~~text
10.0.140.10 -> user VLAN             allowed to initiate
ICMP echo-reply -> 10.0.140.10       allowed
established TCP -> 10.0.140.10       allowed
user VLAN -> new connection to I.T.  denied
~~~

I intentionally did not add a broad UDP return permit. If an administrative tool later requires UDP, I will add only the specific service that is needed.

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

I tested the ACLs from the user VLANs and confirmed:

- each user VLAN can reach its own gateway
- user VLANs can reach DC01 / the Server VLAN
- Internet access still works
- user VLANs cannot freely initiate traffic to the other user VLANs
- ACL deny entries showed matches during testing
- the I.T. admin workstation at `10.0.140.10` can initiate traffic to Shipping, Accounting, Human Resources, and Executives
- those VLANs still cannot initiate new traffic toward `10.0.140.10`

Before ACL testing, I also had to allow ICMPv4 Echo Requests through Windows Defender Firewall on the test clients so endpoint firewall behavior would not be confused with an ACL deny.

That troubleshooting note is here:

[Windows Firewall Blocking Inter-VLAN Ping](../08-Troubleshooting/windows-firewall-icmp-testing.md)

## Next security work

The user VLAN segmentation portion is complete and working.

Future security work can be handled separately, including:

- decide whether the Server VLAN should be restricted to specific services instead of allowing the whole subnet
- harden access to the Management VLAN
- add service-specific UDP exceptions for the I.T. admin workstation only if an admin tool actually needs them
- continue with additional Layer 2 security controls and monitoring

