# Group Policy

This section tracks Group Policy Objects created for the NorthStar environment.

## Implemented / tested

### Lab Power Settings
Applied to lab workstation computer accounts.

Purpose:
- prevent domain lab machines from sleeping while plugged in
- prevent the display from turning off while plugged in

### Domain Member Time Sync
Applied to domain member servers and workstations.

Purpose:
- use the Active Directory domain time hierarchy
- keep domain members aligned with DC01

The Windows NTP client type is configured as **NT5DS** for domain members.

### NorthStar - Eastern Time Zone
Purpose:
- standardize domain systems on Eastern Time

The working deployment method uses **Group Policy Preferences → Immediate Task** running as SYSTEM.

Command:

```text
C:\Windows\System32\tzutil.exe /s "Eastern Standard Time"
```

## Validation

Useful commands:

```cmd
gpupdate /force
gpresult /scope computer /r
w32tm /query /source
w32tm /query /status
tzutil /g
```

Future GPO work will include security baselines, drive mapping, firewall settings, LAPS, and other endpoint controls.
