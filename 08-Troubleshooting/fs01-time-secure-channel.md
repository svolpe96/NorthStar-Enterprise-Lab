# FS01 Time / Secure Channel Failure

This was one of the weirder problems I've hit so far.

## What I saw

FS01 started having domain problems even though the network itself looked fine.

Symptoms included:
- computer-side `gpupdate /force` failing
- SMB access complaining about clock synchronization
- secure-channel verification returning `ERROR_ACCESS_DENIED`
- FS01 somehow showing the year **3964**

## What I checked

I didn't want to assume it was just "the network," so I checked the pieces separately.

Things that worked:
- DNS could find DC01
- TCP 445 to DC01 worked
- TCP 389 to DC01 worked
- domain-controller discovery worked

I also ran:

```cmd
w32tm /stripchart /computer:10.0.20.3 /dataonly /samples:5
```

That actually returned time data, so NTP traffic itself was getting through.

The offset was enormous because FS01 thought it was in the year 3964.

## What was actually wrong

The clock was so far off that normal domain authentication was breaking.

That explained why the machine could still reach DC01 on the network but computer-side Group Policy and domain trust operations were failing.

## Fix

I got the clock back into a sane range first, then got Windows Time working again.

After that I repaired the computer secure channel back to the domain.

Once the secure channel was fixed:
- `gpupdate /force` worked again
- domain access came back
- FS01 could go back to using the normal AD time hierarchy

## What I learned

Working IP connectivity does not mean Active Directory is healthy.

In this case DNS, LDAP, SMB ports, and NTP transport could all be reachable while Kerberos / machine trust was still broken because the clock was completely wrong.
