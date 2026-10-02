# NorthStar Project Log

This is a quick running log of what I worked on, ideas I tried, and problems I ran into. The detailed technical documentation lives in the individual project folders.

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
