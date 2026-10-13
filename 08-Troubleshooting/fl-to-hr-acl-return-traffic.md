# Florida-to-HR ping blocked by an inbound ACL

During the NY/FL OSPF testing, I could ping the HR VLAN gateway (`10.0.120.1`) from Florida, but a ping to the actual HR workstation (`10.0.120.51`) failed.

## What I checked

I verified that OSPF had learned the NY department networks across GRE. The HR workstation had received its normal `10.0.120.1` gateway through DHCP, but Windows also had an old persistent default route toward `10.0.10.1`. I removed that incorrect route.

I then checked Windows Defender Firewall. Its normal inbound ICMP Echo Request rule was disabled, so I added a narrowly scoped rule allowing ICMPv4 Echo Requests from Florida's `10.1.10.1` test address. The ping still failed.

## What actually caused it

CORESW1 applies the `HR-IN` extended ACL **inbound on the HR VLAN SVI**. The Florida Echo Request could travel toward HR, but the reply from the HR workstation was filtered as it entered the core from VLAN 120.

The ACL had a broad deny:

```cisco
90 deny ip 10.0.120.0 0.0.0.255 10.0.0.0 0.255.255.255
```

Because Florida's `10.1.10.1` address belongs to `10.0.0.0/8`, the ICMP Echo Reply matched that deny.

## Fix and verification

I inserted a specific permit above the deny:

```cisco
ip access-list extended HR-IN
 85 permit icmp host 10.0.120.51 host 10.1.10.1 echo-reply
```

After adding that line, the ping from FL's Loopback10 to the HR workstation succeeded.

## What I learned

A FULL OSPF adjacency and correct routes do not guarantee that a ping will work. I had to check the Windows route table, endpoint firewall, and return path through a **stateless** Cisco ACL. ACL direction matters: an inbound ACL on the user VLAN can block a reply even when the original request reached the host.

The permit is intentionally narrow for this test. It does not establish a general policy allowing Florida to reach all NY departments.

Related: [Multi-Site WAN](../11-Multi-Site-WAN/README.md) and [Security](../06-Security/README.md).
