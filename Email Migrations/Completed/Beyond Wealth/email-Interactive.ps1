#================================================================================================================================================#
#                                                                                                                     | Setup:                   #
#                                                                                                                     | Variables, Credentials,  #
#                                                                                                                     | Connections, etc.        #
#================================================================================================================================================#

$domain_controller  = "kspad04.internal.ksphosting.com"
$domain_account     = "KSP_CORPORATE\kspadmin"

$mail_server        = "kspemail04.internal.ksphosting.com"
$mail_server_uri    = "http://$mail_server/Powershell/"

$company_name       = "Beyond Wealth"
$company_ou         = "OU=$company_name,OU=Customers,DC=internal,DC=ksphosting,DC=com"

$tenant_name        = "beyondwealthsk.onmicrosoft.com"
$company_domain     = "beyondwealth.ca"
$tenant_account     = "ksp365admin@${company_domain}"

if($ksp_cred         -eq $null) { $ksp_cred =         (Get-Credential $domain_account) }
if($ksp365admin_cred -eq $null) { $ksp365admin_cred = (Get-Credential $tenant_account) }


# AD session to $domaincontroller
if($ad_session -eq $null -or $ad_session.State -ne "Opened")
{
    $ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
    Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
    Import-PSSession -Session $ad_session -Module ActiveDirectory
}

# Exchange Online session to O365
if($o365_session.State -ne "Opened")
{
    if($o365_session -ne $null) { Remove-PSSession $o365_session; $o365_session = $null }
    # TODO(dallas): Basic auth is going bye-bye
    $o365_session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $ksp365admin_cred -Authentication Basic -AllowRedirection
    Import-PSSession -Prefix O365 -Session $o365_session -DisableNameChecking # TODO(dallas): figure out what -DisableNameChecking does
}

# Exchange session to $mail_server
if($exchange_session -eq $null -or $exchange_session.State -ne "Opened")
{
    $exchange_session = New-PSSession -ConfigurationName Microsoft.Exchange -Authentication Kerberos -ConnectionUri $mail_server_uri -Credential $ksp_cred 
    Import-PSSession -Prefix Hosted -Session $exchange_session -DisableNameChecking # TODO(dallas): figure out what -DisableNameChecking does
}
Clear-Host

#Create Menu
function show-menu
{
    Param (
        [String]$Title = '365 Migrations!'
    )
    Write-Host "================ $Title ================"
    
    Write-Host "1: Increase Send/Receive Limits"
    Write-Host "2: Export .onmicrosoft.com addresses"
    Write-Host "3: Export Primary SMTP (on-prem)"
    Write-Host "4: Create Mapping CSV"
    Write-host "5: Export Aliases and Attributes"
    Write-Host "6: Reapply Attributes"
    Write-Host "Q: Quit scripts"
}

#Loop options while not quitting
do{
#Prompt user for option and connect based on selection
Show-menu -title $title
$selection = Read-host "Please make a selection"
switch ($selection)
{
'1'{
#================================================================================================================================================#
#                                                                                                                     | Increase Send/Receive    #
#                                                                                                                     | Limits                   #
#================================================================================================================================================#
$INCREASE_MAX_SEND_RCV=$true

##################################################################################
# HowTo, Step 3b                                                                 #
# \\kspad06\c$\Scripts\O365\increase max send and receive.ps1                    #
##################################################################################

if($INCREASE_MAX_SEND_RCV) {
    $mailbox_stats_csv_name = "o365_mailbox_stats.csv"
    $mailbox_stats_csv_path = "."
    $mailbox_stats_csv_fullpath = "${mailbox_stats_csv_path}\${mailbox_stats_csv_name}"

    Get-O365Mailbox | sort Alias | Get-O365MailboxStatistics | select DisplayName, TotalItemSize | sort totalitemsize | Export-CSV $mailbox_stats_csv_fullpath

    # NOTE(dallas): Original MaxReceiveSize: 36MB (37,748,736 bytes), MaxSendSize: 35MB (36,700,160 bytes)
    #                  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    #                  !! DiscoverySearchMailbox{<GUID>} WAS 100MB (104,857,600 bytes)/100MB (104,857,600 bytes) !!
    #                  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    Get-O365Mailbox | Set-O365Mailbox -MaxReceiveSize 150MB -MaxSendSize 150MB

    # NOTE(dallas): Original (all 4 Online, OnlineEnterprise, OnlineEssentials, and OnlineDeskless plans)
    #               MaxReceiveSize: 36MB (37,748,736 bytes), MaxSendSize: 36MB (37,748,736 bytes)
    Get-O365MailboxPlan | Set-O365MailboxPlan -MaxReceiveSize 150MB -MaxSendSize 150MB
    pause
    Clear-host
    write-host "Finished Step 1"
   
}



}
'2'{
#================================================================================================================================================#
#                                                                                                                     | Export *.onmicrosoft.com #
#                                                                                                                     | Addresses                #
#================================================================================================================================================#
$EXPORT_ONMICROSOFT_SMTP=$true

##################################################################################
# HowTo, Step 4b                                                                 #
# SET $usercredential VARIABLE                                                   #
# \\kspad06\c$\Scripts\O365\exportonmicrosoftaddresses.ps1                       #
##################################################################################

if($EXPORT_ONMICROSOFT_SMTP)
{
    $onmicrosoft_csv_name = "onmicrosoft_addressess.csv"
    $onmicrosoft_csv_path = "."
    $onmicrosoft_csv_fullpath = "${onmicrosoft_csv_path}\${onmicrosoft_csv_name}"

    $mailboxes = (Get-O365Mailbox -Filter { -not (DisplayName -like "Discovery Search Mailbox") } | sort Alias) 

    $addresses = ($mailboxes | select DisplayName, @{n = "smtp"; e = { $_.EmailAddresses | ? { $_ -like "smtp*.onmicrosoft.com" } } })
 
    $addresses | % {
        $str = ""
        $e = $null
        if($_.smtp)
        {
            # $_.smtp currently in the "SMTP:<address1> smtp:<address2> smtp:..." format
            # Split into separate "SMTP:<address1>" "smtp:<address2>" tokens
            $e = $_.smtp.split(' ')
            # TODO(dallas): pick better names
            $e | % {
                # For each token, split again into string arrays of ("smtp", "<address>")
                $t = $_.split(':')
                # Since the first element of this array will always be "SMTP"/"smtp", it can be discarded
                # Add the second (email address) element to the return string
                $str += $t[1]

                $str += " "
            }
            $str = $str.trim()
        }

        # Add the completed email string as a member of the current address entry for serialization to the CSV
        $_ | Add-Member @{email_addresses=$str}
    }

    
    $addresses | Export-CSV $onmicrosoft_csv_fullpath
    pause
    Clear-host
    write-host "Finished Step 2"
}

}
'3'{
#================================================================================================================================================#
#                                                                                                                     | Export Hosted Email      #
#                                                                                                                     | Address                  #
#================================================================================================================================================#
$EXPORT_PRIMARY_SMTP=$true

##################################################################################################################################################
#                                                                                                                                                #
#                                                           THIS IS WHERE THE NONSENSE STARTS                                                    #
#                                                                                                                                                #
##################################################################################################################################################

##################################################################################
# HowTo, Step 4f                                                                 #
# SET $ou VARIABLE                                                               #
# \\kspemail04\c$\scripts\export list of primarysmtp addresses for single ou.ps1 #
##################################################################################

if($EXPORT_PRIMARY_SMTP)
{
    $primary_smtp_csv_name = "primary_smtp.csv"
    $primary_smtp_csv_path = "."
    $primary_smtp_csv_fullpath = "${primary_smtp_csv_path}\${primary_smtp_csv_name}"

    Get-HostedMailbox -OrganizationalUnit $company_ou | sort Alias | select PrimarySmtpAddress | Export-CSV $primary_smtp_csv_fullpath
}
pause
Clear-host
write-host "Finished Step 3"
}
'4'{

#================================================================================================================================================#
#                                                                                                                     | Generate Mapping CSV     #
#================================================================================================================================================#
$CREATE_MAPPING_CSV=$True


##################################################################################
# HowTo, Step 7e-f                                                               #
#   e.	Create CSV that matches up previously documented onmicrosoft addresses   #
#       to their corresponding samAccount names. It should have the headings:    #
#       samaccountname,destination. (get-aduser -filter * -SearchBase            #
#       "ou=$companyname,OU=Customers,DC=internal,DC=ksphosting,DC=com" | \      #
#       select -expandproperty samaccountname) will generate a list of           #
#       samaccountnames for the ou specified.                                    #
#   f.	Save this csv in "C:\scripts\o365\TargetAddressImports\ \                #
#       targetaddcompanyname.csv"                                                #
##################################################################################

if($CREATE_MAPPING_CSV)
{
    # CRITICAL(dallas): generate onmicrosoft.csv w/ AAD USERS, not MAILBOXES
    $samaccountname_csv_name = "samaccountnames.csv"
    $samaccountname_csv_path = "."
    $samaccountname_csv_fullpath = "${samaccountname_csv_path}\${samaccountname_csv_name}"

    $sams = (Get-ADUser -Filter * -SearchBase $company_ou | sort SamAccountName | select -ExpandProperty SamAccountName)
    # TEST(dallas): make sure this sanity check is acceptable
    
        
        # NOTE(evan): There was an if/else statement here that double-check the resulting CSV. It looked for matching 
        #             number of accounts in AD and in 365. This would ALWAYS fail due to Admins in 365 that aren't in 
        #             the client's OU and accounts in the 'No AD Sync' OU getting picked up in AD. Cutting out the 
        #             whole check. It's just dumb as it never worked and had to be avoided anyways. 
        #             Added pop-up box prompting a review of the CSV manually
    
    
    
        for($i = 0; $i -lt $addresses.length; $i++)
        {
            $sam = $sams[$i]
            
            $addresses[$i] | Add-Member @{samaccountname=$sam}
        }
    
    # TEST(dallas): Review this csv output
    $addresses | select email_addresses,samaccountname | Export-CSV $samaccountname_csv_fullpath
    $CSVCheckBox = [System.Windows.MessageBox]::Show('The Mapping CSV Needs a check. Open Now?','CSV Check','YesNo','Question')
    Switch ($CSVCheckBox) {
        'Yes' {
        Invoke-Item $samaccountname_csv_fullpath
        }
        'No' {
        
        }
      }


  
}
    pause
    Clear-host
    write-host "Finished Step 4"
}
'5'{
#================================================================================================================================================#
#                                                                                                                     | Export On-Prem Exchange  #
#                                                                                                                     | Aliases and Attributes   #
#================================================================================================================================================#
$EXPORT_ALIASES_AND_ATTRIBUTES=$true

##################################################################################
# HowTo, Step 7g-j                                                               #
# SET $csv & $companyname VARIABLE                                               #
# ~~\\kspad06\c$\Scripts\O365\migratetargetandmailattributes.ps1~~               #
# \\kspad06\c$\Scripts\O365\MigrateProxyTargetandMailAttributes.ps1              #
##################################################################################


if($EXPORT_ALIASES_AND_ATTRIBUTES)
{
    
    $csv = ".\samaccountnames.csv"
    $username = import-csv $csv

    #Locates the accounts from the csv, copies their "mail" attribute. Saves as $mail variable and exports to CSV
    $mail_target_csv_name = "mail_target.csv"
    $mail_target_csv_path = "."
    $mail_target_csv_fullpath = "${mail_target_csv_path}\${mail_target_csv_name}"
    $mail = ($username | % { Get-ADUser $_.SamAccountName -Properties Mail })
    $mail | Export-CSV $mail_target_csv_fullpath  

    #Locates the accounts from the csv, copies their proxy addresses, seperates them into usable text. Saves to $proxy variable and exports as csv.
    $proxy_address_csv_name = "proxy_addresses.csv"
    $proxy_address_csv_path = "."
    $proxy_address_csv_fullpath = "${proxy_address_csv_path}\${proxy_address_csv_name}"
    $proxy = ($username | % { Get-ADUser $_.SamAccountName -Properties * } |select SamAccountName, ProxyAddresses)
    $proxy | Export-CSV $proxy_address_csv_fullpath   

    #Gets the users' legacy DN attributes
    $legdn_csv_name = "legdn.csv"
    $legdn_csv_path = "."
    $legdn_csv_fullpath = "${legdn_csv_path}\${legdn_csv_name}"
    $legdn = ($username | % { Get-ADUser $_.SamAccountName -Properties * | select SamAccountName, LegacyExchangeDN })
    $legdn | Export-CSV $legdn_csv_fullpath  
}


    pause
    Clear-host
    write-host "Finished Step 5"
}
'6'{
#================================================================================================================================================#
#                                                                                                                     | Reapply Exchange         #
#                                                                                                                     | Attributes               #
#================================================================================================================================================#
$REAPPLY_ALIASES_AND_ATTRIBUTES=$true

##################################################################################
# HowTo, Step 7m                                                                 #
# ~~\\kspad06\c$\Scripts\O365\migratetargetandmailattributes.ps1~~               #
# \\kspad06\c$\Scripts\O365\MigrateProxyTargetandMailAttributes.ps1              # 
##################################################################################

if($REAPPLY_ALIASES_AND_ATTRIBUTES)
{
        $mail_target_csv_fullpath = ".\mail_target.csv"
        $proxy_address_csv_fullpath = ".\proxy_addresses.csv"
        $legdn_csv_fullpath = ".\legdn.csv"
        $csv = ".\samaccountnames.csv"
        $mail = import-csv $mail_target_csv_fullpath
        $proxy = Import-Csv $proxy_address_csv_fullpath
        $legdn = Import-Csv $legdn_csv_fullpath
        $username = import-csv $csv
    

    #Takes email addresses from previously stored variables and restores them following deletion of mailbox.
    $mail | % { Set-ADUser $_.SamAccountName -Replace @{mail = $_.mail } }

    #Locates the accounts from csv, adds "Destination" field as target address.
    $username | % { Set-ADUser $_.SamAccountName -Replace @{targetaddress = $_.email_addresses } }

    #Takes proxy addresses stored in variable, restores them to the account.
    Foreach($p in $proxy) {
        Set-ADUser $p.SamAccountName -Clear proxyaddresses
        foreach($address in $p.proxyaddresses.split(' '))
        {
            # TODO(dallas): Do we need to transfer X.400 addresses? Filter out, maybe...
            Set-ADUser $p.SamAccountName -Add @{proxyaddresses = $address}
        }
    }

    #Takes legacyexchangedn property stored in variable, restores it as an x500 proxy address
    $legdn | % {
        $fake_x500 = "x500:$($_.legacyexchangedn)"

        #Set-ADUser $_.SamAccountName -Add @{proxyaddresses="x500:" + $_.legacyexchangedn } -WhatIf
        Set-ADUser $_.SamAccountName -Add @{proxyaddresses=$fake_x500 } 
    }
}
    pause
    Clear-host
    write-host "Finished Step 6"
}
'Q'{
clear-host
write-host "Quitting the script..."
}
}
}while ($selection -ne "Q")
#================================================================================================================================================#
#                                                                                                                     | Final Tasks & Cleanup    #
#================================================================================================================================================#
<#

$LAST_MANUAL_TASKS=$false

Get-HostedDistributionGroup -OrganizationalUnit $company_ou  | Set-HostedDistributionGroup -RequireSenderAuthenticationEnabled $false


#Commenting out, this was a good idea but it doesn't work because these are wrong
#if($LAST_MANUAL_TASKS)
#{
    #(get-distributiongroup | set-distrigutiongroup -requiresenderauthentication $false)

   if (-not $DEBUGGING) {
        # Remove PSSessions. Please do this.
        if ($ad_session       -ne $null -and $ksp_session.State      -eq "Opened") { Remove-PSSession -Session $ksp_session      }
        if ($o365_session     -ne $null -and $o365_session.State     -eq "Opened") { Remove-PSSession -Session $o365_session     }
        if ($exchange_session -ne $null -and $exchange_session.State -eq "Opened") { Remove-PSSession -Session $exchange_session }
        # TODO(dallas): remove csvs
    }

#>