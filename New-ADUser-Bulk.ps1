# New-ADUser-Bulk.ps1
# Creates 10 Active Directory users across 5 departmental OUs
# Author: Alexander Remi | RemiTech IT Lab

$base = "DC=remitech,DC=local"
$password = ConvertTo-SecureString "Remitech@2024!" -AsPlainText -Force

$users = @(
    @{First="Sarah"; Last="Chen";     Dept="Engineering"; Title="Software Engineer"},
    @{First="James"; Last="Okafor";   Dept="Engineering"; Title="DevOps Engineer"},
    @{First="Maria"; Last="Santos";   Dept="Finance";     Title="Financial Analyst"},
    @{First="David"; Last="Kim";      Dept="Finance";     Title="Accountant"},
    @{First="Priya"; Last="Patel";    Dept="HR";          Title="HR Manager"},
    @{First="Tom";   Last="Bradley";  Dept="HR";          Title="HR Coordinator"},
    @{First="Aisha"; Last="Johnson";  Dept="Sales";       Title="Sales Lead"},
    @{First="Liam";  Last="Murphy";   Dept="Sales";       Title="Sales Representative"},
    @{First="Zoe";   Last="Williams"; Dept="Operations";  Title="Systems Admin"},
    @{First="Carlos";Last="Rivera";   Dept="Operations";  Title="IT Analyst"}
)

foreach ($u in $users) {
    $sam = ($u.First[0] + "." + $u.Last).ToLower()
    $ouPath = "OU=$($u.Dept),OU=Departments,$base"

    try {
        New-ADUser `
            -Name "$($u.First) $($u.Last)" `
            -GivenName $u.First `
            -Surname $u.Last `
            -SamAccountName $sam `
            -UserPrincipalName "$sam@remitech.local" `
            -Path $ouPath `
            -Title $u.Title `
            -Department $u.Dept `
            -AccountPassword $password `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        Write-Host "Created: $sam in $($u.Dept)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create $sam : $_" -ForegroundColor Red
    }
}

Write-Host "`nBulk user creation complete." -ForegroundColor Cyan
