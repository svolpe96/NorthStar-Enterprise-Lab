# NorthStar Project Log

This is just a running log of what I'm working on and problems I run into. It is not meant to be polished documentation.


## October 1, 2026

### Management-plane SSH hardening

Finished locking down remote SSH management of the Cisco infrastructure.

Created a standard named ACL called **VTY-MGMT** that only permits the dedicated I.T. admin workstation at **10.0.140.10**, then applied it to the VTY lines with `access-class`.

The policy is now in place on:

- CORESW1
- ASW1
- ASW2
- HQ router

The VTY lines use local authentication and only accept SSH. I tested from the admin workstation and from non-admin clients to make sure the management restriction works in both directions.

The HQ router needed some extra work. It was still running SSH version 1, so I changed it to SSHv2 and generated a 2048-bit RSA key pair.

After that, Windows OpenSSH still ran into compatibility problems with the older IOS SSH implementation. CORESW1 required legacy SHA-1 Diffie-Hellman / RSA compatibility, and the HQ router also required the older `hmac-sha1` MAC option. I kept those compatibility changes scoped to the individual SSH commands instead of weakening the Windows SSH client globally.

Full troubleshooting note:

[SSH Cryptographic Compatibility on Older Cisco IOS](08-Troubleshooting/ssh-key-exchange-compatibility.md)

### Server VLAN hardening

Built a separate inbound ACL for the Server VLAN called **SERVER-IN** and applied it to **Vlan20**.

The goal was to control traffic that servers initiate toward internal networks without breaking the user-to-server access controls that were already working.

Current policy:

- block all Server VLAN hosts from initiating traffic into my home network at **192.168.1.0/24**
- allow **DC01 - 10.0.20.3** to communicate with internal NorthStar networks and external destinations
- allow **FS01 - 10.0.20.4** to send established TCP return traffic toward internal clients
- allow **Proxmox - 10.0.20.10** to return established TCP and ICMP echo-reply traffic only to the dedicated admin workstation at **10.0.140.10**
- block remaining Server VLAN traffic from initiating into the internal **10.0.0.0/8** space
- allow remaining traffic toward external destinations

One important ACL-ordering detail came up while building it. I originally placed the home-network deny below the broad DC01 permit. That would have allowed DC01 to match the earlier permit and bypass the home-network restriction. I moved the home-network deny to sequence 5 so it is evaluated before the DC01 permit.

Validation completed successfully:

- user workstation -> FS01 TCP 445 still works
- FS01 -> 192.168.1.1 fails, and the home-network deny counter increases
- FS01 -> Shipping gateway fails, confirming the internal deny
- 10.0.140.10 -> Proxmox TCP 8006 works
- normal user -> Proxmox TCP 8006 remains blocked by the existing user VLAN ACLs

This completes the current Server VLAN traffic-control phase while keeping domain, file-share, and administrative access working.

## September 29, 2026

### Server access ACL hardening

Went back to the user VLAN ACLs and tightened access to the Server VLAN. The original ACL design allowed each user VLAN to reach the entire `10.0.20.0/24` Server VLAN. That worked for the first segmentation phase, but it was broader than I wanted.

The goal for this phase was to keep normal domain and file services working while limiting each VLAN to the servers and services it actually needs.

Current server policy:

- **DC01 - 10.0.20.3**: allowed from all user VLANs for normal Active Directory/domain services
- **FS01 - 10.0.20.4 TCP 445**: allowed from all user VLANs for SMB/file shares
- **FS01 - TCP 80 onboarding site**: allowed only from Human Resources and I.T.
- **Proxmox - 10.0.20.10**: blocked from normal user and I.T. clients
- **I.T. admin workstation - 10.0.140.10**: retains administrative access to internal networks, including Proxmox

For Shipping, Accounting, and Executives, I replaced the broad Server VLAN permit with:

```text
allow -> DC01
allow -> FS01 TCP 445
deny  -> remaining Server VLAN
```

Human Resources gets the same policy plus TCP 80 to FS01 for the onboarding site.

I.T. also gets SMB and onboarding access, but the existing `10.0.140.10` admin exception is placed before the Server VLAN deny. This lets the dedicated admin workstation reach Proxmox while other I.T. clients are blocked.

During the Accounting change I ran into a sequence-number issue where IOS reported unused sequence numbers as duplicates. I resequenced `ACCOUNTING-IN` and then rebuilt the entries in the correct order.

Validation completed successfully:

- normal domain services still work
- SMB to FS01 works on TCP 445
- the onboarding site works from HR and I.T.
- the onboarding site is blocked from the other user VLANs
- Proxmox management is blocked from normal clients
- Proxmox remains reachable from `10.0.140.10`
- inter-VLAN segmentation and Internet access still work

At this point the **user VLAN ACL project is complete for both department segmentation and user-to-server access control**. Server-originated traffic controls and Management VLAN hardening can be handled as separate projects later.

## September 27, 2026

### Inter-VLAN ACL project

Started building the ACL portion of the lab.

The first goal is to segment the user VLANs so departments cannot freely communicate with each other. I am only applying ACLs to the user VLAN SVIs for now. The Server and Management VLANs will be handled separately later.

I am using named extended ACLs on **CORESW1**, applied inbound on the user VLAN SVIs.

Current user VLANs:

- Shipping - 10.0.100.0/24
- Accounting - 10.0.110.0/24
- Human Resources - 10.0.120.0/24
- Executives - 10.0.130.0/24
- I.T - 10.0.140.0/24

Before applying the first ACL, I verified that inter-VLAN routing itself was working. I could ping the SVI/default gateway addresses for the other VLANs, but Windows workstations did not answer ICMP. That turned out to be Windows Defender Firewall blocking inbound Echo Requests.

I created an inbound ICMPv4 Echo Request rule on the test clients so ping can be used as a clean ACL validation tool.

Full troubleshooting note:
[Windows Firewall Blocking Inter-VLAN Ping](08-Troubleshooting/windows-firewall-icmp-testing.md)

### Shipping ACL

Built and applied the first ACL:

```text
SHIPPING-IN
```

The Shipping policy currently does the following:

- allows DHCP client requests
- allows Shipping clients to ping their own default gateway
- allows Shipping to reach the Server VLAN
- blocks Shipping from the rest of the internal 10.0.0.0/8 address space
- allows traffic to external destinations / the Internet

The ACL is applied inbound on **Vlan100**.

I tested the policy from a Shipping workstation and confirmed:

- Shipping can reach its own gateway
- Shipping can reach DC01 in the Server VLAN
- Shipping can reach the Internet
- Shipping cannot reach workstations in the other user VLANs

I also used the ACL hit counters to confirm that the inter-VLAN deny rule was matching traffic.

One useful mistake during the build was accidentally using the wrong wildcard mask on the internal deny. I first entered a wildcard that IOS interpreted as `any`, which would have blocked Shipping from everything. I corrected the destination to `10.0.0.0 0.255.255.255`, which matches the internal `10.0.0.0/8` space.

### User VLAN ACL rollout completed

Finished the same base ACL design for all five user VLANs:

- **SHIPPING-IN** on Vlan100
- **ACCOUNTING-IN** on Vlan110
- **HR-IN** on Vlan120
- **EXECUTIVES-IN** on Vlan130
- **IT-IN** on Vlan140

Each ACL is applied inbound on its SVI and follows the same basic policy:

- allow DHCP client requests
- allow the VLAN to ping its own gateway
- allow access to the Server VLAN at `10.0.20.0/24`
- deny the rest of the internal `10.0.0.0/8` space
- allow external / Internet destinations

I tested the user VLANs and confirmed the segmentation works: normal user VLANs cannot initiate traffic to the other user VLANs, while Server VLAN and Internet access still work.

### I.T. admin workstation exception

Added a controlled exception for the I.T. admin workstation at **10.0.140.10**.

In `IT-IN`, I added a permit before the normal internal deny so that this one host can initiate traffic to internal NorthStar networks:

```cisco
permit ip host 10.0.140.10 10.0.0.0 0.255.255.255
```

Because the ACLs are stateless, the other user VLAN ACLs also needed return-path exceptions before their internal deny rules.

For Shipping, Accounting, Human Resources, and Executives I added:

- ICMP `echo-reply` back to `10.0.140.10`
- TCP traffic with the `established` keyword back to `10.0.140.10`

This lets the I.T. admin workstation initiate ping and TCP sessions to the other user VLANs without allowing those VLANs to freely initiate new traffic toward I.T.

I tested the exception in both directions and confirmed:

- `10.0.140.10` can initiate traffic to the other user VLANs
- the other user VLANs can return the allowed traffic
- normal user VLAN clients still cannot initiate connections toward `10.0.140.10`

The current exception only handles ICMP replies and established TCP return traffic. If an admin tool later needs UDP, I will add a specific UDP exception instead of broadly opening return traffic.

At this point the **user VLAN ACL segmentation project is working**. Server VLAN and Management VLAN hardening will be treated as separate security work later.

## September 25-26, 2026

### HR onboarding portal

Changed direction on the new-user automation. Instead of relying on the Event ID 4720 Scheduled Task to react after accounts are created, I built a small internal onboarding portal so the account is created through the provisioning workflow from the start.

Because I didn't have enough Proxmox storage for another VM, I hosted the lab version of the portal on **FS01** using IIS. In a real environment I would separate the web application from the file server.

The portal now collects:
- first name
- last name
- department
- job title
- start date

I removed the manager field because it wasn't really adding anything useful to the lab.

The backend PowerShell script now:
- creates the username automatically
- creates the user in the correct department OU
- adds the user to the correct department group
- creates the user's H: folder
- lets the existing FSRM and GPO setup handle quotas and mapped drives

The portal now works for **Shipping, Accounting, Human Resources, Executives, and I.T.**

I also cleaned up the result page so HR only sees the useful account information instead of raw PowerShell output.

The lab password is currently **Logmein1**, set to not expire and not require a change at first logon. This is a lab-only choice and not how I would handle passwords in production.

### Department groups and permissions

I changed the way I want department permissions to work.

Instead of giving permissions directly to each employee, new users are added to one main department group when they are created.

Example:

```
New Accounting user
    ↓
Accounting
    ↓
Accounting Share RW
    ↓
Accounting permissions
```

The same idea will be used for Human Resources, Executives, Shipping, and I.T.

This makes onboarding much simpler. The website only needs to put the employee in the right department group. From there, I can nest other permission groups under that department and everyone in the department automatically gets the correct access.

I created the **Accounting** and **Accounting Share RW** groups and nested Accounting inside Accounting Share RW. I also created the **Shipping** and **I.T** department groups so all five departments now follow the same basic layout.

### Service account / delegated permissions

Created a dedicated **SVC_Onboarding** account instead of running the portal as Domain Administrator.

I delegated the permissions it needs to:
- create and manage users under the NorthStar user OUs
- add users to the department groups
- create and manage home folders under `C:\Shares\Home`
- write provisioning logs to a dedicated log folder

The provisioning script was tested successfully while running as `NORTH\SVC_Onboarding`.

I also moved **Service Accounts** to the top level of the domain so it is easier to separate service identities from normal employee accounts.

### Portal access control

Created the **NorthStar HR Onboarding** security group and restricted the IIS onboarding application with Windows Authentication.

Current behavior:
- users in `NorthStar HR Onboarding` can open the portal using their existing domain sign-in
- users outside that group are not authorized
- the HR user only gets access to the portal; the actual provisioning actions still run under `SVC_Onboarding`

I tested the provisioning flow and confirmed users are being created in the correct OU, added to the correct department group, and given their home folder.

### AD cleanup

I cleaned up the layout a little so the parts I actually work in are easier to find.

The main areas I care about now are:
- Building
- Security Groups
- Servers
- Service Accounts

I left the default Active Directory containers like **Builtin**, **Users**, **Computers**, **Domain Controllers**, and **ForeignSecurityPrincipals** alone since they are part of the normal AD structure.

## September 24-25, 2026

### File services

Spent most of the session building out FS01.

- Created the **Home**, **Personnel**, and **Executive** folders and set NTFS/share permissions
- Built security groups for Human Resources, Executives, and the two department shares
- Set up **H:** home drives, **P:** Personnel, and **E:** Executive
- Verified the Personnel share with an HR user and an Executive user
- Added FSRM quotas: **5 GB per home folder**, **20 GB for Personnel**, and **50 GB for Executive**
- Started using Group Policy drive maps so the department drives appear automatically at logon

### Home-folder automation

I didn't want to manually create every user's home folder, so I started automating it.

Created a PowerShell script that creates missing home folders and gives each user Modify permission. I also built a Scheduled Task on DC01 that watches for **Security Event ID 4720** when a new AD user is created and launches the script.

The task action is working now. I still need to do the final end-to-end test with a brand-new user to make sure the event trigger creates the folder automatically.

### FS01 performance / time issue

FS01 started getting extremely slow again while its clock was also jumping thousands of years into the future.

The Proxmox host and DC01 both had correct time, so I narrowed it down to FS01. Windows was reporting 100% CPU even though normal processes were not using it. After changing the Windows per-CPU clock tick scheduling setting, CPU usage dropped and the server became responsive again.

I then corrected the date and returned FS01 to the normal domain time hierarchy.

## September 22, 2026

### FS01 / file services

Started working on the file-server side of the lab.

FS01 is built in Proxmox, joined to **north.local**, and sitting in the **Servers** OU.

Current plan:
- H: user home drives
- P: Personnel share
- E: Executive share

I still need to build the final folder structure, groups, permissions, and GPO drive mappings.

### FS01 time / domain issue

Ran into a really strange issue where FS01 somehow ended up with the year set to **3964**.

The machine still had basic network connectivity, but:
- computer-side GPO failed
- SMB/domain authentication started throwing clock errors
- secure-channel verification returned access denied

I checked DNS, LDAP, SMB, DC discovery, and NTP communication before fixing anything.

After getting the clock back into a normal range and repairing the computer secure channel, `gpupdate /force` started working again.

Full write-up:
[FS01 Time / Secure Channel Failure](08-Troubleshooting/fs01-time-secure-channel.md)

### Proxmox VLAN issue

While setting up FS01, I accidentally tagged VLAN 20 inside Proxmox even though the physical switchport was already an access port in VLAN 20.

That killed connectivity until I removed the VM VLAN tag.

Full write-up:
[Proxmox VLAN Tagging Mismatch](08-Troubleshooting/proxmox-vlan-tagging.md)

## Earlier work

### Network rebuild

The original build started in Jan 2026. Later in the year the access switch failed, so I had to rebuild the switching side of the lab on replacement hardware.

Things rebuilt / verified:
- VLANs
- trunks
- LACP EtherChannels
- Rapid PVST+
- management access
- DHCP relay
- routing
- NAT/PAT
- NTP
- SSH

I still want to write up the hardware failure and rebuild separately because it ended up being a good troubleshooting / recovery example.
