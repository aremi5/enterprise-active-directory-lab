# Fix-PrintSpooler.ps1
# Stops the Print Spooler, clears the print queue, and restarts the service
# Author: Alexander Remi | RemiTech IT Lab
# Run as Administrator on DC01

$spoolPath = "$env:SystemRoot\System32\spool\PRINTERS"

Write-Host "Starting Print Spooler recovery..." -ForegroundColor Cyan

try {
    # Stop the Print Spooler service
    Write-Host "Stopping Print Spooler service..." -ForegroundColor Yellow
    Stop-Service -Name Spooler -Force -ErrorAction Stop
    Write-Host "Print Spooler stopped." -ForegroundColor Green

    # Clear the spool queue
    Write-Host "Clearing print queue at $spoolPath..." -ForegroundColor Yellow
    $files = Get-ChildItem -Path $spoolPath -ErrorAction SilentlyContinue
    if ($files) {
        Remove-Item "$spoolPath\*" -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "Print queue cleared. ($($files.Count) file(s) removed)" -ForegroundColor Green
    } else {
        Write-Host "Print queue was already empty." -ForegroundColor Green
    }

    # Restart the Print Spooler service
    Write-Host "Restarting Print Spooler service..." -ForegroundColor Yellow
    Start-Service -Name Spooler -ErrorAction Stop
    Write-Host "Print Spooler restarted successfully." -ForegroundColor Green

    # Confirm service status
    $status = Get-Service -Name Spooler
    Write-Host "Current status: $($status.Status)" -ForegroundColor Cyan
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Try running this script as Administrator." -ForegroundColor Yellow
}
