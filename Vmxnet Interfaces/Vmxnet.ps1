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
Invoke-Command -Credential (Get-Credential) -ComputerName $computer {
    ipconfig.exe
    Get-NetAdapter | select Name, InterfaceDescription, ifIndex, MacAddress, LinkSpeed | ft
}

Write-Host "Done!"
