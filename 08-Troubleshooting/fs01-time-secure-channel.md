# FS01 Time Synchronization and Secure Channel Failure

## Symptoms

FS01 experienced several domain-related failures:
- computer-side `gpupdate /force` failed
- SMB/domain access produced clock synchronization errors
- secure-channel verification returned `ERROR_ACCESS_DENIED`
- FS01's system date was discovered to be set to the year **3964**

## Investigation

Basic network connectivity to DC01 was available.

Tests included:
- DNS resolution of DC01
- TCP 445 connectivity
- TCP 389 connectivity
- domain-controller discovery
- `w32tm /stripchart` against 10.0.20.3
- secure-channel verification

The NTP stripchart showed that FS01 could receive time data from DC01, proving that basic NTP transport was functioning.

## Root cause

FS01's system clock was drastically incorrect. The extreme clock skew disrupted domain authentication and contributed to Kerberos / secure-channel failures.

## Resolution

1. The FS01 date/time was brought back into a sane range.
2. Windows Time was synchronized again.
3. The computer secure channel to the NORTH domain was repaired.
4. Group Policy processing was retried successfully.
5. FS01 was returned to the normal Active Directory domain time hierarchy.

## Validation

After repair:
- the secure-channel repair succeeded
- `gpupdate /force` succeeded
- domain connectivity was restored

## Lesson learned

Accurate time is a foundational Active Directory dependency. A system can have working IP connectivity, DNS, LDAP, and SMB ports while domain authentication still fails because Kerberos depends heavily on synchronized time.
