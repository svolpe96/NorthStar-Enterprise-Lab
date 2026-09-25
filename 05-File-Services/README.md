# File Services

FS01 is my dedicated file server:

- Hostname: **FS01**
- IP: **10.0.20.4**
- VLAN: **20 - Servers**
- Domain: **north.local**

## Current shares

| Drive | Share | Use | Access |
|---|---|---|---|
| H: | `\\FS01\Home$` | User home folders | Each user gets their own folder |
| P: | `\\FS01\Personnel$` | Personnel files | Human Resources + Executives |
| E: | `\\FS01\Executive$` | Executive files | Executives only |

I used hidden shares so the share names do not show up during normal browsing of `\\FS01`.

## Folder structure

The shares are stored under:

```text
C:\Shares
├── Home
├── Personnel
└── Executive
```

## Security groups

I separated the department groups from the groups that are actually assigned permissions to the file shares.

Current groups:

- **Human Resources**
- **Executives**
- **Personnel Share RW**
- **Executive Share RW**

The memberships are set up like this:

```text
Human Resources
    └── Personnel Share RW

Executives
    ├── Personnel Share RW
    └── Executive Share RW
```

This lets me add users to their department group without having to edit the folder permissions every time someone changes roles.

## Personnel share

`C:\Shares\Personnel`

NTFS permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Personnel Share RW - Modify

Share permissions:

- Personnel Share RW - Change / Read

I tested the share with a Human Resources user and an Executive user and both were able to access it.

The Personnel share is mapped as **P:** through Group Policy.

## Executive share

`C:\Shares\Executive`

NTFS permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Executive Share RW - Modify

Share permissions:

- Executive Share RW - Change / Read

The Executive share is mapped as **E:** through Group Policy and is only targeted to the Executive permission group.

## Home folders

`C:\Shares\Home`

The Home root is set up differently because each user's folder needs to stay private.

Root permissions:

- Administrators - Full Control
- SYSTEM - Full Control
- Domain Users - Read & Execute on **This folder only**

Each user folder then gets that individual user with **Modify** permissions.

Example:

```text
C:\Shares\Home\User
```

with:

```text
NORTH\User - Modify
```

The H: drive maps to:

```text
\\FS01\Home$\%USERNAME%
```

through Group Policy.

## Quotas

I installed File Server Resource Manager and added hard quotas to the file shares.

Current limits:

- **H:** 5 GB per user folder
- **P:** 20 GB total
- **E:** 50 GB total

The H: quota is auto-applied to subfolders under `C:\Shares\Home`, so every new home folder gets its own 5 GB limit automatically.

## Home-folder automation

I didn't want to manually create every user's home folder.

I created a PowerShell script that checks for missing home folders, creates them, and gives the correct user Modify permission.

I also created a Scheduled Task on DC01 that watches for **Security Event ID 4720**, which is generated when a new Active Directory user is created. The task launches the home-folder script.

The task action is working. I still need to finish the final end-to-end test to make sure a newly created account automatically gets its home folder without me manually running the task.

## Troubleshooting

There have already been a few useful troubleshooting cases around FS01, especially the Proxmox VLAN tagging issue and the time / secure-channel problem.

Those are under [Troubleshooting](../08-Troubleshooting/README.md).
