# Active Directory

The lab domain is **north.local**.

## DC01

DC01 is currently doing most of the Windows infrastructure work:

- Active Directory Domain Services
- DNS
- DHCP
- Group Policy

IP: **10.0.20.3**

## OU layout

I'm separating normal users, servers, service accounts, and security groups so the domain is easier to work with.

<img width="750" height="522" alt="security grops" src="https://github.com/user-attachments/assets/c113a4c0-71f9-45e4-81b4-cdf97bb440e7" />


At the top level I mostly work in:

- **Building**
- **Security Groups**
- **Servers**
- **Service Accounts**

Under **Building** I have site OUs for NorthStar locations, including **NorthStar-NY** and **NorthStar-FL**.

The normal built-in AD containers are still there, but I leave those alone unless I actually need them.

## Department groups

The main department groups are:

- **Shipping**
- **Accounting**
- **Human Resources**
- **Executives**
- **I.T**

<img width="752" height="529" alt="Users" src="https://github.com/user-attachments/assets/1a2d01e6-bdc1-4cbc-ae47-22f25ae9b4ca" />


When a new employee is created, they are added to their main department group.

The department group can then be nested into whatever permission groups that department needs.

Example:

~~~text
Accounting user
    ↓
Accounting
    ↓
Accounting Share RW
    ↓
Accounting share permissions
~~~

That way I don't have to assign the same permissions to users one at a time.

## Permission groups

The groups that are actually assigned to resources are kept separate from the department groups.

Current examples:

- **Personnel Share RW**
- **Executive Share RW**
- **Accounting Share RW**

Human Resources and Executives are already nested into the file-share groups they need.

## Service accounts

Service accounts are kept in their own top-level **Service Accounts** OU.

The main one right now is:

- **SVC_Onboarding**

It is used by the HR onboarding site to create new users and home folders.

I gave it only the delegated rights needed for that job instead of making it a Domain Admin.

## What I'm using AD for in the lab

- domain joining clients
- user authentication
- department / role groups
- file-share permissions
- computer policies
- DNS
- DHCP
- Group Policy
- onboarding automation

The OU and group structure will keep changing as I add more to the lab.
