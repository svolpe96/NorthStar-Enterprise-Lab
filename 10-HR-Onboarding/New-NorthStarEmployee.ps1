[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FirstName,

    [Parameter(Mandatory = $true)]
    [string]$LastName,

    [Parameter(Mandatory = $true)]
    [string]$Department,

    [string]$JobTitle = "",

    [string]$StartDate = ""
)

$ErrorActionPreference = "Stop"

Import-Module ActiveDirectory

$DC = "DC01.north.local"
$UPNSuffix = "north.local"
$EmployeeOUBase = "OU=Users,OU=NorthStarHQ,OU=Building,DC=NORTH,DC=LOCAL"
$HomeRoot = "C:\Shares\Home"
$LogFile = "C:\Scripts\Logs\EmployeeProvisioning.log"

# The real lab password is not stored in GitHub.
# Set this locally before using the script.
$LabPassword = $env:NORTHSTAR_LAB_PASSWORD

if ([string]::IsNullOrWhiteSpace($LabPassword)) {
    throw "NORTHSTAR_LAB_PASSWORD is not set."
}

function Write-ProvisioningLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    try {
        Add-Content -Path $LogFile -Value "$TimeStamp [$Level] $Message"
    }
    catch {
        # A logging problem should not stop provisioning.
    }
}

function Get-UniqueUsername {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUsername
    )

    $Candidate = $BaseUsername
    $Counter = 2

    while ($null -ne (Get-ADUser -Filter "SamAccountName -eq '$Candidate'" -Server $DC)) {
        $Candidate = "$BaseUsername$Counter"
        $Counter++
    }

    return $Candidate
}

try {
    $FirstName = $FirstName.Trim()
    $LastName = $LastName.Trim()
    $Department = $Department.Trim()
    $JobTitle = $JobTitle.Trim()
    $StartDate = $StartDate.Trim()

    if ([string]::IsNullOrWhiteSpace($FirstName)) {
        throw "First name cannot be blank."
    }

    if ([string]::IsNullOrWhiteSpace($LastName)) {
        throw "Last name cannot be blank."
    }

    if ([string]::IsNullOrWhiteSpace($Department)) {
        throw "Department cannot be blank."
    }

    $CleanFirstName = [regex]::Replace($FirstName, "[^A-Za-z0-9]", "")
    $CleanLastName = [regex]::Replace($LastName, "[^A-Za-z0-9]", "")

    if ($CleanFirstName.Length -eq 0 -or $CleanLastName.Length -eq 0) {
        throw "Name does not contain valid username characters."
    }

    if ($CleanLastName.Length -gt 7) {
        $LastPart = $CleanLastName.Substring($CleanLastName.Length - 7)
    }
    else {
        $LastPart = $CleanLastName
    }

    $BaseUsername = ($CleanFirstName.Substring(0,1) + $LastPart).ToLower()
    $Username = Get-UniqueUsername -BaseUsername $BaseUsername

    $DepartmentConfig = @{
        "Shipping" = @{
            OU = "OU=Shipping,$EmployeeOUBase"
            Group = "Shipping"
        }

        "Accounting" = @{
            OU = "OU=Accounting,$EmployeeOUBase"
            Group = "Accounting"
        }

        "Human Resources" = @{
            OU = "OU=Human Resources,$EmployeeOUBase"
            Group = "Human Resources"
        }

        "Executives" = @{
            OU = "OU=Executives,$EmployeeOUBase"
            Group = "Executives"
        }

        "I.T" = @{
            OU = "OU=I.T,$EmployeeOUBase"
            Group = "I.T"
        }
    }

    if (-not $DepartmentConfig.ContainsKey($Department)) {
        throw "Unknown department: $Department"
    }

    $TargetOU = $DepartmentConfig[$Department].OU
    $DepartmentGroup = $DepartmentConfig[$Department].Group

    Get-ADOrganizationalUnit -Identity $TargetOU -Server $DC -ErrorAction Stop | Out-Null
    Get-ADGroup -Identity $DepartmentGroup -Server $DC -ErrorAction Stop | Out-Null

    $FormattedStartDate = $null

    if (-not [string]::IsNullOrWhiteSpace($StartDate)) {
        [datetime]$ParsedStartDate = [datetime]::MinValue

        if (-not [datetime]::TryParse($StartDate, [ref]$ParsedStartDate)) {
            throw "Invalid start date: $StartDate"
        }

        $FormattedStartDate = $ParsedStartDate.ToString("yyyy-MM-dd")
    }

    $SecurePassword = ConvertTo-SecureString $LabPassword -AsPlainText -Force

    $NewUserParameters = @{
        Server = $DC
        Name = $Username
        SamAccountName = $Username
        UserPrincipalName = "$Username@$UPNSuffix"
        GivenName = $FirstName
        Surname = $LastName
        DisplayName = $Username
        Department = $Department
        Path = $TargetOU
        AccountPassword = $SecurePassword
        Enabled = $true
        PasswordNeverExpires = $true
        ChangePasswordAtLogon = $false
    }

    if (-not [string]::IsNullOrWhiteSpace($JobTitle)) {
        $NewUserParameters["Title"] = $JobTitle
    }

    $CreatedUser = New-ADUser @NewUserParameters -PassThru

    if ($null -eq $CreatedUser) {
        throw "The AD account could not be created."
    }

    if ($null -ne $FormattedStartDate) {
        Set-ADUser -Identity $CreatedUser.DistinguishedName -Server $DC -Replace @{
            info = "Start Date: $FormattedStartDate"
        }
    }

    Add-ADGroupMember -Identity $DepartmentGroup -Members $CreatedUser -Server $DC

    $UserHomeFolder = Join-Path $HomeRoot $Username

    if (-not (Test-Path -LiteralPath $UserHomeFolder)) {
        New-Item -ItemType Directory -Path $UserHomeFolder | Out-Null
    }

    $CreatedUser = Get-ADUser -Identity $CreatedUser.DistinguishedName -Server $DC -Properties SID
    $ACL = Get-Acl -Path $UserHomeFolder

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $CreatedUser.SID,
        "Modify",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    $ACL.SetAccessRule($AccessRule)
    Set-Acl -Path $UserHomeFolder -AclObject $ACL

    Write-ProvisioningLog -Message "Provisioning complete | User='$Username' | Department='$Department' | Group='$DepartmentGroup'"

    Write-Output "Provisioning successful."
    Write-Output "Username: $Username"
    Write-Output "Department: $Department"
    Write-Output "Department Group: $DepartmentGroup"
    Write-Output "Home Folder: $UserHomeFolder"

    exit 0
}
catch {
    $ErrorMessage = $_.Exception.Message

    Write-ProvisioningLog -Level "ERROR" -Message "Provisioning failed: $ErrorMessage"
    Write-Error "Provisioning failed: $ErrorMessage"

    exit 1
}
