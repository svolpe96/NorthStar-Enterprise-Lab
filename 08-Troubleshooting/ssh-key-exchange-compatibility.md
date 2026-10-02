# SSH Key Exchange Compatibility on CORESW1

## Symptom

While testing the new VTY management restriction on CORESW1, I tried to SSH to the switch from the dedicated I.T. admin workstation.

The connection reached TCP port 22, but the Windows OpenSSH client stopped before login with this error:

~~~text
Unable to negotiate with 10.0.10.1 port 22: no matching key exchange method found.
Their offer: diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1
~~~

The VTY ACL itself was not the problem because the switch was clearly responding to the SSH negotiation.

## What I checked

I verified the VTY configuration on CORESW1:

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

That confirmed the admin workstation was allowed to reach the SSH service.

## Root cause

The Cisco IOS version on the switch was offering older SSH cryptographic algorithms that the current Windows OpenSSH client does not enable by default.

The switch offered SHA-1 based Diffie-Hellman key exchange methods, and the client also required compatibility with the switch's older RSA host key.

This was a cryptographic compatibility issue between the SSH client and the older IOS SSH implementation, not a routing or ACL failure.

## Fix

I explicitly enabled the required legacy key exchange and host key algorithms for this connection:

~~~powershell
ssh -oKexAlgorithms=+diffie-hellman-group14-sha1 -oHostKeyAlgorithms=+ssh-rsa steven@10.0.10.1
~~~

After using those options, the SSH session successfully reached the login process.

## Verification

Successful SSH from the dedicated admin workstation confirmed that:

- the VTY access-class was allowing 10.0.140.10
- TCP 22 was reachable
- the remaining issue was only SSH algorithm negotiation
- the compatibility options allowed the connection to complete

A connection from a non-admin workstation is expected to be denied by the VTY ACL.

## Takeaway

An SSH failure does not always mean the network path or ACL is wrong.

In this case, the connection reached the switch and failed during cryptographic negotiation. Reading the exact SSH error made it possible to separate a transport/access problem from an SSH compatibility problem.

The client-side legacy algorithm override is useful for the lab, but the better long-term approach would be to use newer SSH algorithms through a supported IOS upgrade or newer platform when possible.
