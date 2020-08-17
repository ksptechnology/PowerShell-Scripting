Write-Host "Running '$PSScriptRoot\src\Fix-BrokerWolf.ps1' as admin..."
Start-Process PowerShell -ArgumentList "-File $PSScriptRoot\src\Fix-BrokerWolf.ps1" -Verb Runas
Read-Host "Done..."