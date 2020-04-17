# vars
$csvname        = ""
$targetou       = ""
$ftpgroup       = ""
$adcontroller   = ""
$fileserver     = ""
$ftprootpath    = ""

# Get admin credentials
if($credential -eq $null) { $credential = (Get-Credential) }

# Import AD commands from
$session = (New-PSSession -ComputerName $adcontroller -Credential $credential)
Invoke-Command $session { Import-Module ActiveDirectory }
Import-PSSession -Session $session -Module ActiveDirectory
Import-module \\<server>\c$\scripts\ntfssecurity\NTFSSecurity

#Copy NTFS Module to FS
xcopy '\\<AD>\c$\scripts\ntfssecurity' \\$fileserver\c$\scripts\ntfssecurity\

# Import users
$csv = Import-Csv $csvname

# Create users in AD
$csv | % {
    New-ADUser -GivenName $_.firstname -Surname $_.lastname -DisplayName "$($_.firstname) $($_.lastname)" -name "$($_.firstname) $($_.lastname)" -SamAccountName $_.username  -UserPrincipalName "$($_.username)@<domain>" -AccountPassword ($_.password | ConvertTo-SecureString -AsPlainText -Force) -Enabled $true -PasswordNeverExpires $true -Path $targetou
}

# Get new AD objects
$users = ($csv.username | get-aduser)

# Add users to the FTP group
$users.distinguishedname | % { Add-ADGroupMember $ftpgroup -Members $_ }

# Create FTP folders on the remote FS - Remove comment next to permission needed for user
# IF this fails, you need to enable PS remoting on the FS: Enable-PSRemoting
Invoke-Command -ComputerName $fileserver -Credential $credential {
    Import-module 'c:\scripts\ntfssecurity\NTFSSecurity' 
    $using:users.SamAccountName | % {
        #New-Item -Type Directory -Path $using:ftprootpath\$_
        #Get-Item -Path $using:ftprootpath\$_ | disable-ntfsaccessinheritance
        #get-item -Path $using:ftprootpath\$_ | Add-ntfsaccess -account $_ -AccessRights modify
        #get-item -Path $using:ftprootpath\$_ | Add-ntfsaccess -account $_ -AccessRights read
        get-item -Path $using:ftprootpath\$_ | Add-ntfsaccess -account $_ -AccessRights write
        get-item -Path $using:ftprootpath\$_ | Add-NTFSAccess -Account $_ -AccessRights ListDirectory
        get-item -path $using:ftprootpath\$_ | Remove-ntfsaccess -account $fileserver\user -AccessRights Read
        get-item -Path $using:ftprootpath\$_ | Remove-ntfsaccess -account builtin\Users -AccessRights GenericAll
        #This one doesn't work, idk why... Get-Item -Path $using:ftprootpath\$_ | Remove-NTFSAccess -account "CREATOR OWNER" -AccessRights GenericAll
       
    }
}


# Close AD connection
Remove-PSSession -Session $session
