Write-Host "Running..."

# Get needed arguements
if(-Not $args[0])
{
    $computer = Read-Host "Enter the computer name"
}
else
{
    $computer = $args[0]
}
# todo(dallas): Add services here also

# Connect to remote computer
Invoke-Command -Credential kspadmin -ComputerName $computer {
    # Get services
    #
    # The three services that always go down together are:
    #   Citrix Print Manager Service        (cpsvc)
    #   Citrix XTE Server                   (CitrixXTEServer)
    #   Citrix Universal Printing Service   (UpSvc)
    #
    # todo(dallas): is there a lambda Filter that will do this nicer?
    $services = Get-Service | ? { $_.Name -eq "cpsvc" -or $_.Name -eq "CitrixXTEServer" -or $_.Name -eq "UpSvc" }
    $all_good = $true
    $services | % {
        # Check if running
        if($_.Status -ne "Running")
        {
            $all_good = $false
            Write-Host "Service '$($_.DisplayName) not running!'"

            # Try to restart
            Write-Host "Trying to restart now..."
            Start-Service $_
        }
    }

    if($all_good) { Write-Host "All services were fine!" }
}

Write-Host "Done!"