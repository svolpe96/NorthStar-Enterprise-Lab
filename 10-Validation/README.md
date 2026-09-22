# Validation / Proof

I'm using this folder as a place to keep proof that something actually worked after I configured it.

I don't plan to screenshot every single step. I'd rather keep a few useful screenshots or command outputs that prove the result.

## Network checks I use

```text
show ip interface brief
show vlan brief
show interfaces trunk
show etherchannel summary
show spanning-tree root
show ip route
```

## Time checks

```text
show ntp status
show ntp associations
w32tm /query /source
w32tm /query /status
```

## Group Policy checks

```text
gpupdate /force
gpresult /scope computer /r
tzutil /g
```

## File server checks I still need

- H: maps for a normal user
- P: maps for HR / Executives
- E: maps for Executives only
- unauthorized users get denied where expected

I'll add screenshots and outputs here as I get them.
