# Group Policy

These are the GPOs I've actually built and tested so far.

## Lab Power Settings

This is linked to the lab workstation computers.

I use it to keep the machines awake while plugged in so they don't go to sleep during testing.

## Domain Member Time Sync

I set domain members to use the AD time hierarchy instead of picking their own external NTP source.

Windows NTP client type:

```text
NT5DS
```

The goal is basically:

```text
external time source
        ↓
       DC01
        ↓
domain members
```

## NorthStar - Eastern Time Zone

I wanted all of the lab systems to stay on the same time zone too.

The method that ended up working cleanly was a Group Policy Preferences **Immediate Task** running as SYSTEM:

```text
C:\Windows\System32\tzutil.exe /s "Eastern Standard Time"
```

## Commands I use to check GPO / time

```cmd
gpupdate /force
gpresult /scope computer /r
w32tm /query /source
w32tm /query /status
tzutil /g
```

Next up for Group Policy will probably be drive mappings for the file server.
