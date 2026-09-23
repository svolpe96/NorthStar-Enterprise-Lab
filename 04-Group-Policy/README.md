# Group Policy

This is where I'm keeping track of the GPOs I've created. I'm not going to document every command I used to test them here. If a GPO causes an issue or leads to something worth troubleshooting, I'll document that separately.

## GPOs I've Created

### Lab Power Settings

Created this for the lab workstations so they stay awake while they're plugged in.

I don't want the laptops going to sleep in the middle of testing, updates, or when I'm working on something.

**What I changed:**
- Prevent sleep while plugged in
- Prevent the display from turning off while plugged in
- Left the battery settings alone

---

### Domain Member Time Sync

Created this so domain-joined machines follow the Active Directory time hierarchy instead of using their own external time source.

DC01 gets its time externally and the domain members get their time through the domain.

**Applied to:**
- Servers
- computers

---

### Time Zone

Created this because I wanted all of the lab machines using the same time zone.

I originally tried handling this through a script, but I found it to be too clunky, so I ended up using a Group Policy Preferences Immediate Task to set the machines to Eastern Time.

**Time zone:**
- Eastern Standard Time

---
