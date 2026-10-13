# NorthStar Project Log

This is a quick running log of what I worked on, ideas I tried, and problems I ran into. The detailed technical documentation lives in the individual project folders.

## October 12, 2026

### Completed NY/FL OSPF routing and tested tunnel recovery

Finished advertising the five NY department VLANs into OSPF and confirmed FL learned all five through the GRE tunnel. FL also successfully reached the HR VLAN gateway.

I wanted to go one step further and ping an actual HR workstation. That initially failed. I found an old persistent default route on the Windows client and removed it, then added a scoped Windows Firewall ICMP rule. The ping still failed until I checked the `HR-IN` ACL on CORESW1. Its broad `10.0.0.0/8` deny was blocking the Echo Reply back to Florida. I added a host-specific ICMP reply permit above the deny and confirmed the ping worked.

I also shut down NY's Tunnel0 for a controlled OSPF test. FL's neighbor and its specific OSPF route disappeared, while the CORESW1 adjacency stayed FULL. A route lookup fell back to the existing broader static `10.0.0.0/8` route. I brought Tunnel0 back up and the Florida connection returned.

Florida is only meant to be a remote routing test site, not a fully built branch office. The remaining work is documentation and any future routing/security improvements I choose to practice.

Details: [Multi-Site WAN](11-Multi-Site-WAN/README.md) and [ACL troubleshooting](08-Troubleshooting/fl-to-hr-acl-return-traffic.md).

### OSPF across the NY / FL multi-site design

Started the dynamic-routing phase of the NY-to-FL project.

I chose OSPF even though static routing would be enough for the current two-site environment. The reason is scalability: I want NorthStar to be able to grow beyond NY and FL without having to maintain static routes everywhere. It also gives me hands-on experience with OSPF neighbors, route advertisement, path selection, and troubleshooting.

Current OSPF router IDs:

- NY: 1.1.1.1
- FL: 2.2.2.2
- CORESW1: 3.3.3.3

FL now has a test internal network represented by Loopback10 at 10.1.10.1/24. I set the loopback OSPF network type to point-to-point so it can represent the full 10.1.10.0/24 Florida LAN instead of being advertised only as a /32.

OSPF process 1 is running in Area 0.

The current neighbor path is:

~~~text
CORESW1 <-> NY <-> GRE Tunnel0 <-> FL
~~~

NY and FL successfully formed an OSPF adjacency across the GRE tunnel. CORESW1 and NY also formed an OSPF adjacency across the existing 10.255.255.0/24 routed link.

I am using passive-interface default and only allowing the actual router-to-router links to form neighbors.

At this stage I planned to advertise Shipping first, verify the route, and then add the remaining NY networks. I completed that later in the same session (see above).

I also separated routing from security in the design. OSPF will tell the routers how to reach the remote networks, while ACLs or firewall policy will still decide which departments and services are allowed to communicate between sites.

Full write-up:

[Multi-Site WAN](11-Multi-Site-WAN/README.md)

## October 9-10, 2026

### Built the NY-to-FL simulated WAN and GRE tunnel

Started the multi-site portion of NorthStar.

Instead of directly connecting the New York and Florida routers with one Ethernet cable, I built a small simulated ISP so the two routers behave more like separate geographic sites.

The provider side now uses:

- VLAN 901 for the NY-to-ISP circuit
- VLAN 902 for the FL-to-ISP circuit
- a lightweight Debian LXC container in Proxmox acting as the ISP router
- separate /30 WAN networks on each side

I converted the Proxmox switchport to a trunk while keeping VLAN 20 native so existing Proxmox management stayed online. The Proxmox bridge was also made VLAN-aware so the ISP container could connect to both WAN VLANs.

After proving that both routers could reach each other through the ISP, I built a GRE tunnel between NY and FL:

- NY Tunnel0: 10.255.254.1/30
- FL Tunnel0: 10.255.254.2/30

The GRE tunnel is up and passing traffic.

One useful issue came up while assigning the tunnel addresses. I originally planned to use 10.255.255.4/30, but IOS rejected it as overlapping with NY GigabitEthernet0/1. Checking the existing interface showed that the NY-to-core link is actually configured as 10.255.255.1/24, not /30. I left the existing link alone and moved the GRE tunnel to 10.255.254.0/30 instead.

The WAN underlay and GRE overlay are complete. The next step is OSPF across Tunnel0.

Full write-up:

[Multi-Site WAN](11-Multi-Site-WAN/README.md)

## October 1, 2026

### Management and server hardening

Spent the session tightening the security side of NorthStar.

- Restricted remote Cisco management so only the dedicated I.T. admin workstation can SSH to the network devices
- Applied the same management policy to CORESW1, ASW1, ASW2, and the NY router
- Updated the NY router from SSHv1 to SSHv2
- Added Server VLAN controls so servers cannot freely initiate traffic toward user networks or my home LAN
- Kept the required return traffic working for file services and Proxmox administration

The interesting part of the session was SSH troubleshooting. The older Cisco IOS versions and the current Windows OpenSSH client did not agree on several cryptographic algorithms. I had to work through key-exchange, host-key, and MAC compatibility issues before SSH worked correctly.

Full write-up:

[SSH Cryptographic Compatibility on Older Cisco IOS](08-Troubleshooting/ssh-key-exchange-compatibility.md)

I also caught an ACL-ordering mistake while working on the Server VLAN. A broad permit would have bypassed the home-network restriction, so I moved the deny above it and retested everything.

## September 29, 2026

### Tightened access to the Server VLAN

Went back to the user VLAN ACLs because access to the Server VLAN was still broader than I wanted.

The final idea was simple:

- everyone still gets normal domain services from DC01
- everyone still gets file-share access from FS01
- only HR and I.T. can reach the onboarding site
- Proxmox management is reserved for the dedicated I.T. admin workstation

Shipping, Accounting, HR, Executives, and I.T. were all tested after the changes.

Accounting gave me a weird sequence-number issue where IOS claimed an unused ACL number was already taken. Resequencing the ACL fixed it.

By the end of the session, the user-VLAN ACL project was finished and the policies matched what I originally wanted.

## September 27, 2026

### Inter-VLAN ACL project

Started the network-segmentation portion of the lab.

The goal was to stop the user departments from freely talking to each other while keeping normal server and Internet access working.

I started with Shipping, tested it, and then rolled the same basic design out to Accounting, HR, Executives, and I.T.

Two useful problems came up:

- Windows Defender Firewall was blocking ping replies, which initially made the routing/ACL testing look broken
- I entered the wrong wildcard mask on one of the early deny rules and IOS interpreted it much more broadly than I intended

Both were good reminders to verify endpoint behavior and read ACLs carefully instead of assuming the network is the problem.

Full troubleshooting note:

[Windows Firewall Blocking Inter-VLAN Ping](08-Troubleshooting/windows-firewall-icmp-testing.md)

I also added a dedicated exception for the I.T. admin workstation so it can initiate management traffic toward the other user VLANs without opening those VLANs up to I.T. in general.

## September 25-26, 2026

### HR onboarding portal

Changed direction on the new-user automation.

Instead of reacting to new accounts after they were created, I built a small internal HR onboarding page that creates the account through the workflow from the start.

By the end of the session the portal could:

- create a new employee
- place the account in the correct department
- add the employee to the correct department group
- create the user's home folder
- let the existing GPO and file-service setup handle the rest

I also switched the backend to a dedicated service account instead of using a highly privileged administrator account, and restricted access to the site with Windows Authentication.

This was also when I cleaned up the AD layout and started leaning more heavily on department groups plus separate resource-permission groups instead of assigning access user by user.

## September 24-25, 2026

### File services

Spent most of the session building out FS01.

Created the home, Personnel, Executive, and Accounting share structure, added quotas, and started mapping drives through Group Policy.

I also started automating home-folder creation because I did not want to manually build a folder every time I created a user.

### FS01 performance / time issue

FS01 became extremely slow and its clock started jumping thousands of years into the future.

The Proxmox host and DC01 both had the correct time, so the issue was isolated to FS01. Windows was reporting 100% CPU even though normal processes were not actually consuming it.

After correcting the clock behavior and returning FS01 to the normal domain time hierarchy, the server became usable again.

## September 22, 2026

### FS01 build

Started the dedicated file-server side of the lab.

Built FS01 in Proxmox, joined it to the domain, and started planning the home-drive and department-share layout.

### FS01 time / domain failure

Ran into one of the stranger problems in the lab so far: FS01 somehow ended up with the year set to **3964**.

That broke Group Policy, SMB/domain authentication, and the computer secure channel.

After correcting the time and repairing the secure channel, the server returned to normal.

Full write-up:

[FS01 Time / Secure Channel Failure](08-Troubleshooting/fs01-time-secure-channel.md)

### Proxmox VLAN tagging mistake

While setting up FS01, I tagged VLAN 20 inside Proxmox even though the physical switchport was already configured as an access port in VLAN 20.

That completely killed connectivity until I removed the extra VM-side tag.

Full write-up:

[Proxmox VLAN Tagging Mismatch](08-Troubleshooting/proxmox-vlan-tagging.md)

## Earlier work

### Network rebuild

The original NorthStar build started in January 2026.

Later in the year an access switch failed, so I ended up rebuilding a large portion of the switching side of the lab on replacement hardware.

That rebuild gave me a chance to recreate and verify the major pieces again, including VLANs, trunks, EtherChannels, spanning tree, routing, DHCP relay, NAT/PAT, NTP, and SSH.

I still want to write the hardware failure/rebuild up separately because it turned into a useful troubleshooting and recovery exercise.
