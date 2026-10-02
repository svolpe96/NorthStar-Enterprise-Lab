# SSH Cryptographic Compatibility on Older Cisco IOS

## Overview

While hardening remote management access, I ran into multiple SSH compatibility issues between the current Windows OpenSSH client and older Cisco IOS implementations.

The network path and VTY ACLs were working, but the SSH negotiation failed because the Cisco devices only offered older cryptographic options that modern OpenSSH disables by default.

This ended up being a useful reminder that an SSH failure can happen at several different layers: routing, ACL access, SSH protocol version, key exchange, host key type, or message authentication.

## CORESW1 - key exchange and host key compatibility

### Symptom

While testing the new VTY management restriction on CORESW1, I tried to SSH to the switch from the dedicated I.T. admin workstation.

The connection reached TCP port 22, but Windows OpenSSH stopped before login with:

~~~text
Unable to negotiate with 10.0.10.1 port 22: no matching key exchange method found.
Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1
~~~

The VTY ACL itself was not the problem because the switch was clearly responding to the SSH negotiation.

### What I checked

I verified the VTY configuration:

~~~cisco
line vty 0 4
 access-class VTY-MGMT in
 login local
 transport input ssh

line vty 5 15
 access-class VTY-MGMT in
 login local
 transport input ssh
~~~

I also verified the management ACL:

~~~cisco
ip access-list standard VTY-MGMT
 permit host 10.0.140.10
 deny any
~~~

### Root cause

CORESW1 was offering older SHA-1 based Diffie-Hellman key exchange methods and an older RSA host key type that the current Windows OpenSSH client does not enable by default.

This was a cryptographic compatibility issue, not a routing or ACL failure.

### Fix

I explicitly enabled the required legacy algorithms for this connection:

~~~powershell
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa steven@10.0.10.1
~~~

That allowed the SSH connection to proceed successfully from the dedicated admin workstation.

I also tested SSH from a non-admin VLAN workstation and confirmed that the VTY ACL blocked it as intended.

## NY router - SSH version and MAC compatibility

### First symptom - SSH protocol version mismatch

When I moved to the NY router at **10.255.255.1**, the first SSH attempt failed with:

~~~text
Protocol major versions differ: 2 vs. 1
banner exchange: Connection to 10.255.255.1 port 22: could not read protocol version
~~~

The router was still using SSH version 1.

### Fixing the protocol version

I changed the router to SSH version 2:

~~~cisco
ip ssh version 2
~~~

I also generated 2048-bit RSA keys for the router so SSHv2 could use the local key pair.

After that, `show ip ssh` reported SSH version 2.

### Second symptom - MAC algorithm mismatch

Once the protocol version issue was fixed, the SSH negotiation progressed further but failed again:

~~~text
Unable to negotiate with 10.255.255.1 port 22: no matching MAC found.
Their offer: hmac-sha1,hmac-sha1-96
~~~

This showed that routing, TCP 22, the VTY access path, SSHv2, key exchange, and the host key were getting far enough for the client and router to negotiate message authentication.

### Root cause

The older IOS version on the NY router only offered SHA-1 based HMAC algorithms that current Windows OpenSSH does not enable by default.

### Compatibility command

For the lab connection, I added the legacy MAC algorithm to the same client-side compatibility options:

~~~powershell
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa -oMACs=+hmac-sha1 steven@10.255.255.1
~~~

This keeps the legacy compatibility change scoped to the individual SSH command instead of weakening the Windows SSH client globally.

## Takeaway

These failures happened at different stages of SSH negotiation:

~~~text
TCP 22 reachable
    ↓
SSH protocol version
    ↓
Key exchange algorithm
    ↓
Host key algorithm
    ↓
MAC algorithm
    ↓
Authentication / login
~~~

Reading the exact error message made it possible to tell which stage was failing instead of assuming every SSH problem was caused by routing or an ACL.

The client-side legacy overrides are useful for this lab because the Cisco hardware is running older IOS code. In a production environment, the better solution would be to use supported software and hardware capable of modern SSH cryptography rather than relying on SHA-1 based algorithms.
