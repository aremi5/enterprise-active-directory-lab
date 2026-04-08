# Disable-StaleAccounts.ps1
# Queries Active Directory for accounts inactive for 90+ days and disables them
# Author: Alexander Remi | RemiTech IT Lab

$inactiveDays = 90
$cutoffDate = (Get-Date).AddDays(-$inactiveDays)
$disabledOU = "OU=_Disabled_Accounts,DC=remitech,DC=local"

Write-Host "Scanning for accounts inactive since $($cutoffDate.ToString('yyyy-MM-dd'))..." -ForegroundColor Cyan

try {
    $staleUsers = Search-ADAccount -AccountInactive -TimeSpan (New-TimeSpan -Days $inactiveDays) `
        -UsersOnly | Where-Object { $_.Enabled -eq $true }

    if ($staleUsers.Count -eq 0) {
        Write-Host "No stale accounts found." -ForegroundColor Green
        exit
    }

    Write-Host "Found $($staleUsers.Count) stale account(s):" -ForegroundColor Yellow

    foreach ($user in $staleUsers) {
        try {
            # Disable the account
            Disable-ADAccount -Identity $user.SamAccountName

            # Move to disabled OU
            Move-ADObject -Identity $user.DistinguishedName -TargetPath $disabledOU

            Write-Host "Disabled and moved: $($user.SamAccountName)" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to process $($user.SamAccountName): $_" -ForegroundColor Red
        }
    }

    Write-Host "`nStale account cleanup complete." -ForegroundColor Cyan
}
catch {
    Write-Host "Error querying Active Directory: $_" -ForegroundColor Red
}
