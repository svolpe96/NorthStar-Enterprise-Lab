# File Services

FS01 is my dedicated file server:

- Hostname: **FS01**
- IP: **10.0.20.4**
- VLAN: **20 - Servers**
- Domain: **north.local**

## Current shares

| Drive | Share | Use | Access |
|---|---|---|---|
| H: | \\FS01\Home$ | User home folders | Each user gets their own folder |
| P: | \\FS01\Personnel$ | Personnel files | Human Resources + Executives |
| E: | \\FS01\Executive$ | Executive files | Executives only |
| - | \\FS01\Accounting$ | Accounting files | Accounting |

I used hidden shares so the share names do not show up during normal browsing of \\FS01.

## Folder structure

The shares are stored under:

~~~text
C:\Shares
├── Home
├── Personnel
├── Executive
└── Accounting
~~~

## How I'm handling permissions

I separated the department groups from the groups that are actually assigned permissions to the file shares.

Example:

~~~text
Accounting user
    ↓
Accounting
    ↓
Accounting Share RW
    ↓
\\FS01\Accounting$
~~~

This means I can add a user to **Accounting** and let the group nesting handle the share access.

I don't have to add every new employee directly to the folder permissions.

Current examples:

~~~text
Human Resources
    └── Personnel Share RW

Executives
    ├── Personnel Share RW
    └── Executive Share RW

Accounting
    └── Accounting Share RW
~~~

## Personnel share

C:\Shares\Personnel

NTFS permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Personnel Share RW - Modify

Share permissions:

- Personnel Share RW - Change / Read

The Personnel share is mapped as **P:** through Group Policy.

## Executive share

C:\Shares\Executive

NTFS permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Executive Share RW - Modify

Share permissions:

- Executive Share RW - Change / Read

The Executive share is mapped as **E:** through Group Policy.

## Accounting share

C:\Shares\Accounting

The **Accounting** department group is nested into **Accounting Share RW**.

The permission group is then used on the Accounting share instead of assigning permissions to each Accounting user.

## Home folders

C:\Shares\Home

The Home root is set up differently because each user's folder needs to stay private.

Root permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Domain Users - Read & Execute on **This folder only**

Each user folder then gets that individual user with **Modify** permissions.

The H: drive maps to:

~~~text
\\FS01\Home$\%USERNAME%
~~~

through Group Policy.

## Quotas

I installed File Server Resource Manager and added hard quotas to the file shares.

Current limits:

- **H:** 5 GB per user folder
- **P:** 20 GB total
- **E:** 50 GB total

The H: quota is auto-applied to subfolders under C:\Shares\Home, so every new home folder gets its own 5 GB limit automatically.

## Home-folder creation

I originally experimented with an Event ID 4720 Scheduled Task to create home folders after a user was created.

I ended up replacing that idea with the HR onboarding workflow.

The onboarding script now creates the user's AD account and home folder together. Group Policy then maps the H: drive when the user signs in.

More details are under [HR Onboarding](../10-HR-Onboarding/README.md).

## Troubleshooting

There have already been a few useful troubleshooting cases around FS01, especially the Proxmox VLAN tagging issue and the time / secure-channel problem.

Those are under [Troubleshooting](../08-Troubleshooting/README.md).
