param(
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    $UserName
)

. $PSScriptRoot\Functions.ps1

$Creds = Check-Creds
$Props = Parse-Props

Write-Host "Killing open processes..."
Kill-Processes
Write-Host "Closing open files..."
Close-OpenFiles

Write-Host "Fixed!"
Read-Host -Prompt "Press 'Enter' to continue..."