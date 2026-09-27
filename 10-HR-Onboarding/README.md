# HR Onboarding

I built a small internal onboarding page so I could stop creating every test employee manually in Active Directory.

The lab version is hosted on **FS01** with IIS because I didn't have enough Proxmox storage for another VM. In a real environment I would separate the web application from the file server.

## What the page collects

- First name
- Last name
- Department
- Job title
- Start date

## Current departments

- Shipping
- Accounting
- Human Resources
- Executives
- I.T

## What happens when HR creates a user

~~~text
Authorized HR user
        ↓
Onboarding page
        ↓
SVC_Onboarding
        ↓
Create AD account
        ↓
Put user in the correct OU
        ↓
Add user to the correct department group
        ↓
Create the user's home folder
        ↓
GPO / nested groups handle the rest
~~~

The website only needs to know which department the employee belongs to.

The department group can be nested into file-share or other permission groups later, so I don't have to keep changing the onboarding script every time a department gets access to something new.

## Access to the site

The site uses Windows Authentication.

Only users in:

~~~text
NorthStar HR Onboarding
~~~

are allowed to use it.

The HR user does not get direct rights to create AD accounts. The backend runs as:

~~~text
NORTH\SVC_Onboarding
~~~

That account has delegated permissions for the specific onboarding tasks it needs.

## Files in this folder

- **index.aspx** - onboarding page
- **New-NorthStarEmployee.ps1** - backend provisioning script

The copies in GitHub are sanitized. I do not keep real passwords in the repo, and environment-specific paths can be adjusted locally.

## Lab vs production

This is a lab project, so I intentionally kept some parts simple.

If I were building this for a real environment I would change things like:

- separate web/app server instead of hosting on FS01
- generated temporary passwords instead of a fixed lab password
- normal password expiration/change requirements
- HTTPS
- tighter auditing
- probably a managed service identity / gMSA depending on the design
- approval or ticket workflow before provisioning
