<#
.SYNOPSIS
    Creates multiple test users in Microsoft Entra ID (Azure AD) test tenant
.DESCRIPTION
    This script creates 100+ test users with realistic names and properties in your Entra ID test tenant
    using the Microsoft.Graph.Entra PowerShell module
.PARAMETER UserCount
    Number of users to create (default: 100)
.PARAMETER Domain
    Your tenant domain (e.g., contoso.onmicrosoft.com)
.PARAMETER Password
    Password for all test users (optional - will generate secure password if not provided)
.EXAMPLE
    .\Create-EntraTestUsers.ps1 -UserCount 150 -Domain "contoso.onmicrosoft.com"
#>

param(
    [int]$UserCount = 100,
    [Parameter(Mandatory=$true)]
    [string]$Domain,
    [string]$Password = $null
)

# Install and import required module if not already available
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Entra)) {
    Write-Host "Installing Microsoft.Graph.Entra module..." -ForegroundColor Yellow
    Install-Module Microsoft.Graph.Entra -Scope CurrentUser -Force
}

Import-Module Microsoft.Graph.Entra

# Connect to Entra ID
Write-Host "Connecting to Microsoft Entra ID..." -ForegroundColor Green
try {
    Connect-Entra -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"
    Write-Host "Successfully connected to Entra ID" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect to Entra ID: $($_.Exception.Message)"
    exit 1
}

# Generate secure password if not provided
if (-not $Password) {
    $Password = -join ((65..90) + (97..122) + (48..57) + (33, 35, 36, 37, 38, 42, 43, 45, 61, 63, 64) | Get-Random -Count 12 | ForEach-Object {[char]$_})
    Write-Host "Generated secure password: $Password" -ForegroundColor Cyan
}

# Sample first names and last names for realistic test data
$FirstNames = @(
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda", 
    "William", "Elizabeth", "David", "Barbara", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Christopher", "Karen", "Charles", "Nancy", "Daniel", "Lisa",
    "Matthew", "Betty", "Anthony", "Helen", "Mark", "Sandra", "Donald", "Donna",
    "Steven", "Carol", "Paul", "Ruth", "Andrew", "Sharon", "Joshua", "Michelle",
    "Kenneth", "Laura", "Kevin", "Sarah", "Brian", "Kimberly", "George", "Deborah",
    "Timothy", "Dorothy", "Ronald", "Lisa", "Jason", "Nancy", "Edward", "Karen",
    "Jeffrey", "Betty", "Ryan", "Helen", "Jacob", "Sandra", "Gary", "Donna"
)

$LastNames = @(
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas",
    "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White",
    "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker", "Young",
    "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Gomez", "Phillips", "Evans", "Turner", "Diaz", "Parker"
)

$Departments = @(
    "IT", "HR", "Finance", "Marketing", "Sales", "Operations", "Legal", "Engineering",
    "Customer Service", "Research", "Development", "Quality Assurance", "Product Management"
)

$JobTitles = @(
    "Manager", "Analyst", "Specialist", "Coordinator", "Director", "Associate", 
    "Senior Analyst", "Team Lead", "Supervisor", "Consultant", "Administrator"
)

# Function to create a single user
function New-TestUser {
    param(
        [int]$UserNumber,
        [string]$Domain,
        [string]$Password
    )
    
    $firstName = Get-Random -InputObject $FirstNames
    $lastName = Get-Random -InputObject $LastNames
    $department = Get-Random -InputObject $Departments
    $jobTitle = Get-Random -InputObject $JobTitles
    
    # Create unique username
    $userName = "$firstName$lastName$UserNumber".ToLower()
    $userPrincipalName = "$userName@$Domain"
    $displayName = "$firstName $lastName"
    $mailNickname = $userName
    
    # Create user parameters
    $userParams = @{
        DisplayName = $displayName
        UserPrincipalName = $userPrincipalName
        MailNickname = $mailNickname
        GivenName = $firstName
        Surname = $lastName
        Department = $department
        JobTitle = "$jobTitle - $department"
        UsageLocation = "US"
        PasswordProfile = @{
            Password = $Password
            ForceChangePasswordNextSignIn = $false
        }
        AccountEnabled = $true
    }
    
    try {
        $user = New-EntraUser @userParams
        Write-Host "✓ Created user: $displayName ($userPrincipalName)" -ForegroundColor Green
        return $user
    }
    catch {
        Write-Warning "✗ Failed to create user $displayName`: $($_.Exception.Message)"
        return $null
    }
}

# Create users
Write-Host "`nCreating $UserCount test users in domain: $Domain" -ForegroundColor Yellow
Write-Host "Password for all users: $Password" -ForegroundColor Cyan
Write-Host "Starting user creation...`n" -ForegroundColor Yellow

$createdUsers = @()
$failedCount = 0

for ($i = 1; $i -le $UserCount; $i++) {
    Write-Progress -Activity "Creating Test Users" -Status "Creating user $i of $UserCount" -PercentComplete (($i / $UserCount) * 100)
    
    $user = New-TestUser -UserNumber $i -Domain $Domain -Password $Password
    
    if ($user) {
        $createdUsers += [PSCustomObject]@{
            DisplayName = $user.DisplayName
            UserPrincipalName = $user.UserPrincipalName
            Department = $user.Department
            JobTitle = $user.JobTitle
            ObjectId = $user.Id
        }
    }
    else {
        $failedCount++
    }
    
    # Add small delay to avoid throttling
    Start-Sleep -Milliseconds 200
}

Write-Progress -Activity "Creating Test Users" -Completed

# Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "USER CREATION SUMMARY" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Total users requested: $UserCount" -ForegroundColor White
Write-Host "Successfully created: $($createdUsers.Count)" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host "Domain: $Domain" -ForegroundColor White
Write-Host "Password for all users: $Password" -ForegroundColor Yellow
Write-Host "="*60 -ForegroundColor Cyan

# Export created users to CSV
if ($createdUsers.Count -gt 0) {
    $csvPath = ".\EntraTestUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $createdUsers | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "`nUser details exported to: $csvPath" -ForegroundColor Green
}

# Optional: Create sample groups and assign users
$createGroups = Read-Host "`nDo you want to create sample security groups and assign users? (y/N)"
if ($createGroups -eq 'y' -or $createGroups -eq 'Y') {
    Write-Host "`nCreating sample security groups..." -ForegroundColor Yellow
    
    $groupNames = @("TestGroup-IT", "TestGroup-HR", "TestGroup-Finance", "TestGroup-Marketing")
    
    foreach ($groupName in $groupNames) {
        try {
            $group = New-EntraGroup -DisplayName $groupName -MailEnabled $false -SecurityEnabled $true -MailNickname $groupName
            Write-Host "✓ Created group: $groupName" -ForegroundColor Green
            
            # Assign random users to groups
            $randomUsers = $createdUsers | Get-Random -Count (Get-Random -Minimum 5 -Maximum 15)
            foreach ($user in $randomUsers) {
                try {
                    Add-EntraGroupMember -GroupId $group.Id -DirectoryObjectId $user.ObjectId
                }
                catch {
                    Write-Warning "Failed to add user $($user.DisplayName) to group $groupName"
                }
            }
        }
        catch {
            Write-Warning "✗ Failed to create group $groupName`: $($_.Exception.Message)"
        }
    }
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
Write-Host "You can now use these test users for your Entra ID testing." -ForegroundColor White

# Cleanup function (optional)
function Remove-AllTestUsers {
    Write-Host "WARNING: This will delete ALL created test users!" -ForegroundColor Red
    $confirm = Read-Host "Type 'DELETE' to confirm removal of all test users"
    
    if ($confirm -eq "DELETE") {
        foreach ($user in $createdUsers) {
            try {
                Remove-EntraUser -ObjectId $user.ObjectId
                Write-Host "✓ Deleted user: $($user.DisplayName)" -ForegroundColor Yellow
            }
            catch {
                Write-Warning "✗ Failed to delete user: $($user.DisplayName)"
            }
        }
    }
}

Write-Host "`nTo remove all created users later, run: Remove-AllTestUsers" -ForegroundColor Cyan