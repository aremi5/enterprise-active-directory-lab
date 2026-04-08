# Reset-ADPassword.ps1
# Resets an Active Directory user password and forces change at next logon
# Author: Alexander Remi | RemiTech IT Lab
# Usage: .\Reset-ADPassword.ps1 -Username "j.okafor"

param (
    [Parameter(Mandatory=$true)]
    [string]$Username
)

$newPassword = ConvertTo-SecureString "TempPass@2024!" -AsPlainText -Force

try {
    # Verify user exists
    $user = Get-ADUser -Identity $Username -ErrorAction Stop
    Write-Host "Found user: $($user.Name) ($Username)" -ForegroundColor Cyan

    # Reset password
    Set-ADAccountPassword -Identity $Username -NewPassword $newPassword -Reset
    Write-Host "Password reset successfully for $Username" -ForegroundColor Green

    # Force password change at next logon
    Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
    Write-Host "User will be prompted to change password at next logon." -ForegroundColor Yellow

    # Ensure account is unlocked
    Unlock-ADAccount -Identity $Username
    Write-Host "Account unlocked for $Username" -ForegroundColor Green
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Host "Error: User '$Username' not found in Active Directory." -ForegroundColor Red
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
