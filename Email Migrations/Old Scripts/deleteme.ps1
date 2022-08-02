#================================================================================================================================================#
#                                                                                                                     | Templates                #
#================================================================================================================================================#

#================================================================================================================================================#
#                                                                                                                     |                          #
##################################################################################
##                                                                              ##
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !

#================================================================================================================================================#
# This PowerShell process will collect and order any relevant information you will need to complete an Office 365 migration. The most important  #
# data will be output to a 'mapping.json' file, which will contain the relevant attributes of every user (and the corresponding Azure user if    #
# available) in the client's company. During the migration process, some of this data is removed from the AD users, and the data in this CSV     #
# will later be reapplied                                                                                                                        #
#                                                                                                                                                #
# It also outputs various other .json files containing attributes/data regarding other aspects of the email environment (distribution list info, #
# public folder structure, shared mailbox permissions, etc.) for use in future processes and automation efforts                                  #
#================================================================================================================================================#

#================================================================================================================================================#
#                                                                                                                     | Initialize Global        #
#                                                                                                                     | Variables and PowerShell #
#                                                                                                                     | Remote Sessions          #
#================================================================================================================================================#
##################################################################################
##                                                                              ##
##  Using this config file initialization setup makes working with multiple     ##
##  clients at once a breeze. When you need to switch, just 'cd',               ##
##  '$props_initialized = $false' and rerun                                     ##
##                                                                              ##
##################################################################################
if ($true) {
    try {
        . "..\MigrationSetup.ps1"
    } catch [System.Management.Automation.CommandNotFoundException] {
        Write-Error "Couldn't locate the 'MigrationSetup.ps1' script!"
        Exit -1
    }

    Initialize-Props
    Initialize-Creds
    Initialize-Cons
}

#================================================================================================================================================#
#                                                                                                                     | Export On-Prem Distro    #
#                                                                                                                     | Groups                   #
#================================================================================================================================================#
if($false) {
    $groups = Get-HostedDistributionGroup -OrganizationalUnit $company_ou
    $groups | % {
        $members = ""
        $members = (Get-HostedDistributionGroupMember -Identity $_.Name | select -Expand DisplayName)
        $_ | Add-Member $members -Name GroupMembers -Type NoteProperty
    }

    $groups | select Name, PrimarySmtpAddress, EmailAddresses, GroupMembers | ConvertTo-Json | Out-File "onprem_distro_groups.json"
}

#================================================================================================================================================#
#                                                                                                                     | Export On-Prem Mailbox   #
#                                                                                                                     | Full Access and Send-As  #
#                                                                                                                     | Permissions              #
#================================================================================================================================================#
if($false) {
    $unimportant_permissions = "NT AUTHORITY*",
    "S-1-5-21-*",
    "KSP_CORPORATE\kspadmin",
    "KSP_CORPORATE\Administrator",
    "KSP_CORPORATE\Domain Admins",
    "KSP_CORPORATE\Enterprise Admins",
    "KSP_CORPORATE\Organization Management",
    "KSP_CORPORATE\Exchange Servers",
    "KSP_CORPORATE\Exchange Domain Servers",
    "KSP_CORPORATE\Managed Availablility Servers",
    "KSP_CORPORATE\Organization Management",
    "KSP_CORPORATE\Public Folder Management",
    "KSP_CORPORATE\Delegated Setup",
    "KSP_CORPORATE\besadmin2010",
    "KSP_CORPORATE\Exchange Services",
    "KSP_CORPORATE\Exchange Trusted Subsystem",
    "KSP_CORPORATE\Managed Availability Servers"

    $mailboxes = Get-HostedMailbox -OrganizationalUnit $company_ou
    $mailboxes | % {
        $all_permissions = $_ | Get-HostedMailboxPermission | select User, AccessRights
        $permissions = [System.Collections.ArrayList]@()
        $all_permissions | % {
            $found = $false
            for ($i = 0; $i -lt $unimportant_permissions.Length; $i++) {
                $principal = $unimportant_permissions[$i]
                Write-Host "Looking for Principal '$principal' in Permission '$($_.User)'"
                if ($_.User -Like $principal) { $found = $true; break }
            }
            if (-not $found) { $permissions.Add($_) }
        }
        $all_sendas = $_ | Get-HostedADPermission | ? { $_.ExtendedRights -like "*send*" } | % { $_.User }
        $sendas = [System.Collections.ArrayList]@()
        $all_sendas | % {
            $found = $false
            for ($i = 0; $i -lt $unimportant_permissions.Length; $i++) {
                $principal = $unimportant_permissions[$i]
                Write-Host "Looking for Principal '$principal' in Permission '$($_)'"
                if ($_ -Like $principal) { $found = $true; break }
            }
            if (-not $found) { $sendas.Add($_) }
        }

        $_ | Add-Member -Name Permissions -Value $permissions -Type NoteProperty
        $_ | Add-Member -Name AllPermissions -Value $all_permissions -Type NoteProperty
        $_ | Add-Member -Name SendAs -Value $sendas -Type NoteProperty
        $_ | Add-Member -Name AllSendAs -Value $all_sendas -Type NoteProperty
    }

    $mailboxes | sort Name | select Name, Permissions, SendAs | ConvertTo-Json -Depth 100 | Out-File "onprem_mailbox_permissions.json"
    $mailboxes | sort Name | select Name, AllPermissions, AllSendAs | ConvertTo-Json -Depth 100 | Out-File "onprem_mailbox_permissions_all.json"
}

#================================================================================================================================================#
# TODO: Export Send-As permissions as well                                                                            | Export Online Mailbox    #
#                                                                                                                     | Full Access Permissions  #
#================================================================================================================================================#
if($false) {
    $unimportant_permissions = "NT AUTHORITY*",
    "S-1-5-21-*",
    "KSP_CORPORATE\kspadmin",
    "KSP_CORPORATE\Administrator",
    "KSP_CORPORATE\Domain Admins",
    "KSP_CORPORATE\Enterprise Admins",
    "KSP_CORPORATE\Organization Management",
    "KSP_CORPORATE\Exchange Servers",
    "KSP_CORPORATE\Exchange Domain Servers",
    "KSP_CORPORATE\Managed Availablility Servers",
    "KSP_CORPORATE\Organization Management",
    "KSP_CORPORATE\Public Folder Management",
    "KSP_CORPORATE\Delegated Setup",
    "KSP_CORPORATE\besadmin2010",
    "KSP_CORPORATE\Exchange Services",
    "KSP_CORPORATE\Exchange Trusted Subsystem",
    "KSP_CORPORATE\Managed Availability Servers",

    "CANPRD01\*",
    "PRDTSB01\*"

    $mailboxes = (Get-O365Mailbox)
    $mailboxes | % {
        $all_permissions = $_ | Get-O365MailboxPermission | select User, AccessRights
        $permissions = [System.Collections.ArrayList]@()
        $all_permissions | % {
            $found = $false
            for ($i = 0; $i -lt $unimportant_permissions.Length; $i++) {
                $principal = $unimportant_permissions[$i]
                Write-Host "Looking for Principal '$principal' in Permission '$($_.User)'"
                if ($_.User -Like $principal) { $found = $true; break }
            }
            if (-not $found) { $permissions.Add($_) }
        }
        
        # TODO(dallas): Get SendAs permissions working
        #$all_sendas = $_ | Get-HostedADPermission | ? { $_.ExtendedRights -like "*send*" } | % { $_.User }
        #$sendas = [System.Collections.ArrayList]@()
        #$all_sendas | % {
            #$found = $false
            #for ($i = 0; $i -lt $unimportant_permissions.Length; $i++) {
                #$principal = $unimportant_permissions[$i]
                #Write-Host "Looking for Principal '$principal' in Permission '$($_)'"
                #if ($_ -Like $principal) { $found = $true; break }
            #}
            #if (-not $found) { $sendas.Add($_) }
        #}

        $_ | Add-Member -Name Permissions -Value $permissions -Type NoteProperty
        $_ | Add-Member -Name AllPermissions -Value $all_permissions -Type NoteProperty
        #$_ | Add-Member -Name SendAs -Value $sendas -Type NoteProperty
        #$_ | Add-Member -Name AllSendAs -Value $all_sendas -Type NoteProperty
    }

    #$mailboxes | sort Name | select Name, Permissions, SendAs | ConvertTo-Json -Depth 100 | Out-File onprem_mailbox_permissions.json
    #$mailboxes | sort Name | select Name, AllPermissions, AllSendAs | ConvertTo-Json -Depth 100 | Out-File onprem_mailbox_permissions_all.json
    $mailboxes | sort Name | select Name, Permissions | ConvertTo-Json -Depth 100 | Out-File "o365_mailbox_permissions.json"
    $mailboxes | sort Name | select Name, AllPermissions | ConvertTo-Json -Depth 100 | Out-File "o365_mailbox_permissions_all.json"
}

#================================================================================================================================================#
#                                                                                                                     | Export On-Prem Contacts  #
#================================================================================================================================================#
if($false)
{
    $contacts = (Get-HostedContact -OrganizationalUnit $company_ou)
    $contacts | ConvertTo-Json | Out-File "./onprem_contacts.json"
}

#================================================================================================================================================#
#                                                                                                                     | Export On-Prem Public    #
#                                                                                                                     | Folder Permissions       #
#================================================================================================================================================#
if ($false) {
    $folders = Get-HostedPublicFolder -Identity $public_folders -Recurse
    $folders | % {
        $full_path = "$($_.ParentPath)\$($_.Name)"
        $perms = ($full_path | Get-HostedPublicFolderClientPermission | select User, AccessRights)
        $_ | Add-Member -Name Permissions -Value $perms -Type NoteProperty
    } 
    $folders | select Name, ParentPath, Permissions | ConvertTo-Json -Depth 100 | Out-File "onprem_public_folder_permisisons.json"
}

#================================================================================================================================================#
# WARNING: haven't tested this much. seems to often miss some mailboxes                                               | Export On-Prem Shared    #
#                                                                                                                     | Mailboxes                #
#================================================================================================================================================#
if($false)
{
    $export_folder_root = "\\kspemail06\e$\MailboxImportExport\${company_name}"

    # TODO(dallas): would 'Invoke-Command' be smarter?
    if(-not (Test-Path $export_folder_root)) { New-Item -Type Directory -Path $export_folder_root }

    if (Test-Path $export_folder_root) {
        # TEST(dallas): VVV
        #$export_folder_root = "\\kspemail06\e$\MailboxImportExport\${company_name}" (used to be above '$export_folder_root = ...')
        #Get-HostedMailbox -OrganizationalUnit $shared_mailboxes_ou | % {
        Get-HostedMailbox -OrganizationalUnit $shared_ou | % {
            $export_name = "$($_.PrimarySmtpAddress).pst"
            $export_path = "${export_folder_root}\${export_name}"

            Write-Host "(OnPrem)Exporting '$_' to '$export_path'"
            New-HostedMailboxExportRequest -Mailbox $_.Alias -FilePath $export_path
        }
    }
    else
    {
        Write-Error "Can't export mailboxes because folder '$export_folder_root' can't be accessed"
    }
}

#================================================================================================================================================#
# This process queries existing On-Prem/Azure users and mailboxes with the purpose of matching the corresponding      | Map and Export           #
# users and exporting the relevant attributes and data necessary for later in the migration. There are basic          | On-Prem/Azure User Data  #
# blacklist filters you can use when querying each directory, whitelist filters are TODO:. Onprem users are only      |                          #
# queried from the AD OU's we synchronize as per                                                                      |                          #
# [our standard](G:\KSP Technical Standards\Active Directory\Info - Customer OU Structure.docx)                       |                          #
# These OUs are hardcoded on lines 47-52 TODO:                                                                        |                          #
#                                                                                                                     |                          #
# A global array of '$users' is populated with individual '$class_user' objects. The user objects contain all the     |                          #
# relevant AD attributes, which you can access as an object member with a special prefix. The prefixes are            |                          #
# 'onprem_attribute_' and 'o365_attribute_' according to which object/environment you're trying to access. For        |                          #
# example, if you needed the user's On-Prem UPN, you'd look at the "$user.onprem_attribute_userPrincipalName"         |                          #
# property. There are a few outliers to this rule (onprem_base64_guid, o365_predicted_attribute_userPrincipalName)    |                          #
#                                                                                                                     |                          #
# This process builds the list of users and also performs a few other operations:                                     |                          #
#     -It attempts to guess the onprem users' o365 UPN according to how the tenant is currently configured            |                          #
#     -It calculates the onprem users' base64-encoded ObjectId (AD Sync will configure this as an Azure users'        |                          #
#       'immutableID' automatically, but previously existing O365 users need this configured by hand                  |                          #
#     -Verifies that every O365 user has a valid '.onmicrosoft.com' proxyAddresses value                              |                          #
#                                                                                                                     |                          #
# During the process, if an Azure user is encountered with no valid '.onmicrosoft.com' proxyAddresses value, an error |                          #
# is logged (because you NEED this address for the migration), though the process will continue                       |                          #
#                                                                                                                     |                          #
# Following the queries & calculations a number of sanity checks are performed on the user data to make sure it will  |                          #
# be valid for the rest of the migration. Failing these checks will not stop the process, but any failure messages    |                          #
# should be thoroughly inspected and accounted for                                                                    |                          #
#================================================================================================================================================#
if($false) {
    $class_user = [PSCustomObject]@{
        onprem_attribute_samAccountName             = "";
        onprem_attribute_userPrincipalName          = "";
        onprem_attribute_givenName                  = "";
        onprem_attribute_surname                    = "";
        onprem_attribute_displayName                = "";
        onprem_attribute_distinguishedName          = "";
        onprem_attribute_mail                       = "";
        onprem_attribute_targetAddress              = "";
        onprem_attribute_proxyAddresses             = "";
        onprem_attribute_legacyExchangeDN           = "";
        onprem_attribute_objectGuid                 = "";

        onprem_base64_guid                          = "";
        o365_predicted_attribute_userPrincipalName  = "";

        o365_onmicrosoft_address                    = "";
        o365_onmicrosoft_shared_mailbox             = [bool]$null;
        o365_attribute_userPrincipalName            = "";
        o365_attribute_givenName                    = "";
        o365_attribute_surname                      = "";
        o365_attribute_displayName                  = "";
        o365_attribute_mail                         = "";
        o365_attribute_mailNickname                 = "";
        o365_attribute_proxyAddresses               = "";
    }

    $users = [System.Collections.ArrayList]@()

    ################################################################################## 
    ##                                                                              ##
    ##  Get On-Prem AD Users                                                        ##
    ##                                                                              ##
    ##################################################################################
    $onprem_user_filter = @(
        "smhitest",
        "smhitest2",
        "wiriboardroom"
    )
    # Search AD Synced OUs only
    $onprem_users = @()
    $mailbox_ous | % {
        $onprem_users += (Get-ADUser -Filter * -SearchBase $_ -Properties DisplayName, Mail, TargetAddress, ProxyAddresses, LegacyExchangeDN)
    }
    # TODO(dallas): add a whitelist ?
    # filter out blacklisted users by samaccountname
    foreach($filter in $onprem_user_filter) {
        $filtered_users = ($onprem_users | ? { -Not ($_.UserPrincipalName -Like "$filter") } )
        $onprem_users = $filtered_users
    }

    ################################################################################## 
    ##                                                                              ##
    ##  Get Azure AD Users                                                          ##
    ##                                                                              ##
    ##################################################################################
    $azure_user_filter = @(
        "Sync_*@*.onmicrosoft.com",
        "ksp365admin@*",
        "kspadmin365@*",
        "admin@*.onmicrosoft.com",
        "365veeam@*.onmicrosoft.com",
        # any others
        "test@smhiregina.onmicrosoft.com",
        "smhitest2@smhiregina.onmicrosoft.com"
    )
    # TODO(dallas): add a whitelist ?
    # filter out blacklisted users by UPN
    $azure_users = (Get-AzureADUser)
    foreach($filter in $azure_user_filter) {
        $filtered_users = ($azure_users | ? { -Not ($_.UserPrincipalName -Like "$filter") } )
        $azure_users = $filtered_users
    }

    ################################################################################## 
    ##                                                                              ##
    ##  Get Verified Azure Domains                                                  ##
    ##                                                                              ##
    ##################################################################################
    $azure_domains = (Get-AzureADDomain | select Name)

    ################################################################################## 
    ##                                                                              ##
    ##  Get On-Prem Mailboxes                                                       ##
    ##                                                                              ##
    ##################################################################################
    # BUG(dallas):  if only one mailbox exists, returned value is a scalar, not a vector
    #               future '.Length' and '.Count' calls will fail
    #               found while debugging post-migration
    #               wontfix?
    $onprem_mailboxes = (Get-HostedMailbox -OrganizationalUnit $company_ou)

    ##################################################################################
    ##                                                                              ##
    ## Get OnPrem User Attributes                                                   ##
    ##                                                                              ##
    ##################################################################################
    $onprem_users | % {
        # NOTE(dallas): Can't do this, copies by reference and changes the class object
        #               https://stackoverflow.com/questions/9581568/how-to-create-new-clone-instance-of-psobject-object
        # $user = $class_user
        #               Not sure if this is any better...
        $user = $class_user.PsObject.Copy()

        $user.onprem_attribute_samAccountName       = $_.SamAccountName
        $user.onprem_attribute_userPrincipalName    = $_.UserPrincipalName
        $user.onprem_attribute_givenName            = $_.GivenName
        $user.onprem_attribute_surname              = $_.Surname
        $user.onprem_attribute_displayName          = $_.DisplayName
        $user.onprem_attribute_distinguishedName    = $_.DistinguishedName
        $user.onprem_attribute_mail                 = $_.Mail
        $user.onprem_attribute_targetAddress        = $_.TargetAddress
        $user.onprem_attribute_proxyAddresses       = $_.ProxyAddresses
        $user.onprem_attribute_legacyExchangeDN     = $_.LegacyExchangeDN
        $user.onprem_attribute_objectGuid           = $_.ObjectGuid

        $user.onprem_base64_guid = [system.Convert]::ToBase64String($_.ObjectGuid.tobytearray())

        ##################################################################################
        ##                                                                              ##
        ##  Try and guess the users' Azure UPN                                          ##
        ##                                                                              ##
        ##################################################################################
        if($_.Mail) {
            $found = $false
            ForEach($domain in $azure_domains.Name) {
                if($_.Mail -like "*@$domain") { $found = $true; break }
            }
            if($found) {
                $user.o365_predicted_attribute_userPrincipalName = $_.Mail
            } else {
                $user.o365_predicted_attribute_userPrincipalName = $_.Mail.split('@')[0] + "@" + "$tenant_name"
            }
        } else {
            $user.o365_predicted_attribute_userPrincipalName = $_.SamAccountName + "@" + "$tenant_name"
        }

        $users.Add($user)
    }

    ##################################################################################
    ##                                                                              ##
    ##  Get On-Prem User's Azure User Attributes                                    ##
    ##                                                                              ##
    ##################################################################################
    $users | % {
        $o365_user = Get-AzureADUser -SearchString $_.onprem_attribute_displayName

        $_.o365_attribute_userPrincipalName = $o365_user.UserPrincipalName
        # BUG(dallas): Will output multiple GivenNames if Azure contains guest users with similar onprem displaynames
        # TODO(dallas): Best fix would probably be to stop using -SearchString with Get-AzureADUser, should use a guid
        #               to get a single, exact match
        $_.o365_attribute_givenName = $o365_user.GivenName
        $_.o365_attribute_surname = $o365_user.Surname
        $_.o365_attribute_displayName = $o365_user.DisplayName
        $_.o365_attribute_mail = $o365_user.Mail
        $_.o365_attribute_mailNickname = $o365_user.MailNickname
        $_.o365_attribute_proxyAddresses = $o365_user.ProxyAddresses

        $found = $null
        ForEach ($address in $o365_user.ProxyAddresses) {
            if ($address -like "*onmicrosoft.com") { $found = $address; break }
        }
        if(!$found) {
            if($o365_user.UserPrincipalName -like "*.onmicrosoft.com") {
                $found = $o365_user.UserPrincipalName
            }
            else { Write-Error -ErrorAction Continue "Unable to find .onmicrosoft.com address for acccount '$($o365_user.DisplayName)'" }
        }
        $onmicrosoft =  $null
        if($found -like "smtp:*") { $onmicrosoft = $found.split(':')[1] }
        else { $onmicrosoft = $found }
        $_.o365_onmicrosoft_address = $onmicrosoft
    }

    ##################################################################################
    ##                                                                              ##
    ##  Sanity Checks                                                               ##
    ##                                                                              ##
    ##################################################################################
    # Check that all users have both onprem and O365 UPNs
    $no_upn = $false 
    $users | % { if(-not ($_.onprem_attribute_userPrincipalName) -or -not ($_.o365_attribute_userPrincipalName)) { $no_upn = $true} }
    if($no_upn) { # Need to account for non-dirsyncing OUs
        Write-Error "Error: user with no UPN detected"
        $users | ? { -not ($_.onprem_attribute_userPrincipalName) -or -not ($_.o365_attribute_userPrincipalName) }
        #Exit -1
    }

    # Check that there are a matching number of onprem & azure users
    # TODO(dallas): With customers like WestExcel with Guest users, this will fail.
    #               Need to account for guest users (UPNs contain '#EXT#')
    #               Need to account for service accounts (like "Discovery Search Mailbox")
    if($onprem_users.Length -ne $azure_users.Length) {
        Write-Error "Error: mismatching number of OnPrem/Azure users"
        Write-Host "OnPrem: $($onprem_users.Length), Azure: $($azure_users.Length)"
        #Exit -1
    }
    
    # Make sure there are not multiple O365 GivenName attribute values
    # ~~~saw this happen on an SMHI account once. not sure what it means~~~
    # happens when there are also contacts with similar displaynames, mail addresses, etc
    $multiple_givenNames = $false
    $users | % { if($_.o365_attribute_givenName.Count -gt 1) { $multiple_givenNames = $true } }
    if($multiple_givenNames) {
        Write-Error "Error: Azure accounts with multiple givenNames"
        $users | ? { $_.o365_attribute_givenName.Count -gt 1 }
        #Exit -1
    }

    # Check for Matching # of onprem Mailboxes:user Mail Attributes
    # NOTE(dallas): Check will be fine pre-migration, will fail post-migration
    $mail_user_count = ($users | ? { $_.onprem_attribute_mail -ne $null }).Count 
    if($onprem_mailboxes.Count -ne $mail_user_count) { 
        Write-Error "Error: mismatching number of OnPrem users/mailboxes"
        Write-Host "Users: $($mail_user_count), Mailboxes: $($onprem_mailboxes.Count)"
        #Exit -1
    }

    # Check for incorrect O365 UPN guesses
    # NOTE(dallas): This can happen if users have changed their name and either the SamAccountName
    #               or the email address was not updated (like when people get married, or a service
    #               account is made a personal account a-la 'Cubbon Shipping')
    $mismatched_users = [System.Collections.ArrayList]@() 
    # NOTE(dallas): using 'break' in regular '$users | % { ... }' exits whole script
    #               not sure why 'ForEach' has to be used here
    # $users | % {
    ForEach ($user in $users) {
        if($user.o365_predicted_attribute_userPrincipalName -ne $user.o365_attribute_userPrincipalName) {
            $mismatched_users.Add($user)
        }
    }
    if($mismatched_users.Count -gt 0) {
        Write-Error "Incorrectly predicted O365 UPN(s)"
        $mismatched_users | % {
            Write-Host "Guessed: $($_.o365_predicted_attribute_userprincipalname), Actual: $($_.o365_attribute_userprincipalname)"
        }
        #Exit -1
    }

    # Check for null .onmicrosoft.com addresses
    $null_onmicrosoft = [System.Collections.ArrayList]($users | ? { $_.o365_onmicrosoft_address -eq $null })
    if($null_onmicrosoft.Count -gt 0) {
        Write-Error "Missing user .onmicrosoft.com addresses"
        $null_onmicrosoft | % { Write-Host "$($_.onprem_attribute_displayName)" }
        #Exit -1
    }

    $users | sort onprem_attribute_givenName | ConvertTo-Json | Out-File .\mapping.json
}


#================================================================================================================================================#
#                                                                                                                     | Import AD User           #
#                                                                                                                     | Attributes               #
#================================================================================================================================================#
if($true)
{
    $users = (gc -Raw "./mapping.json" | ConvertFrom-Json) 
    $mail_users = ($users | ? {$_.onprem_attribute_mail -ne $null})

    # Reapply the 'Mail' attribute
    $mail_users | % { Set-ADUser $_.onprem_attribute_samAccountName -Replace @{mail = $_.onprem_attribute_mail} }

    # Reapply the 'TargetAddress' attribute
    $mail_users | % { Set-ADUser $_.onprem_attribute_samAccountName -Replace @{targetaddress = $_.o365_onmicrosoft_address}}

    # Reapply the 'ProxyAddress' attribute(s)
    $mail_users | % {
        Set-ADUser $_.onprem_attribute_samAccountName -Clear proxyAddresses
        ForEach($address in $_.onprem_attribute_proxyAddresses) {
            Set-ADUser $_.onprem_attribute_samAccountName -Add @{proxyAddresses = $address}
        }
    }

    # Add the 'LegacyExchangeDN' as a 'ProxyAddress'
    $mail_users | % {
        $fake_x500 = "x500:$($_.onprem_attribute_legacyExchangeDN)"
        Set-ADUser $_.onprem_attribute_samAccountName -Add @{proxyAddresses = $fake_x500}
    }
}