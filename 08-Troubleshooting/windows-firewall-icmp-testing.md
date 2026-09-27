# Windows Firewall Blocking Inter-VLAN Ping

While getting ready to build the inter-VLAN ACLs, I ran into an issue where the VLAN gateways were reachable but the Windows workstations in the other VLANs would not respond to ping.

## What I saw

From a client in one user VLAN, I could ping:

- its own VLAN gateway
- the SVI/default gateway addresses for the other user VLANs

But I could not ping the Windows workstations inside those VLANs.

At first this looked like an inter-VLAN routing problem.

## What I checked

I tested the gateway addresses for the other VLANs first.

Because those SVI addresses were reachable, I knew the traffic was reaching CORESW1 and being routed between the VLANs.

That narrowed the problem down to the endpoint side instead of the Layer 3 routing on the core.

## Root cause

Windows Defender Firewall was blocking inbound ICMPv4 Echo Requests on the workstations.

The routing between VLANs was already working. The Windows clients were just not answering ping requests.

## What fixed it

On the Windows test workstation, I opened **Windows Defender Firewall with Advanced Security** and created a new inbound rule that:

- uses ICMPv4
- allows Echo Request
- allows the connection
- applies to the Domain profile

I named the rule:

```text
NorthStar - Allow ICMPv4 Echo
```

## Why I made the change

I want ping to be a reliable validation tool while I build the ACLs.

If Windows Firewall is blocking ICMP at the same time I am testing an ACL, it becomes harder to tell whether the ACL is actually responsible for the failure.

Allowing ICMP Echo Requests on the lab test clients gives me a clean way to verify which VLAN-to-VLAN paths are being permitted or denied by the ACLs.

## How I verified it

After enabling the firewall rule, I tested the same workstation from a device in another VLAN.

The workstation responded to ping, confirming that:

- inter-VLAN routing was working
- the original problem was Windows Defender Firewall
- ICMP can now be used to help validate the ACL project
