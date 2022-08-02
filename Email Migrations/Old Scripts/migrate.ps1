#================================================================================================================================================#
#                                                                                                                     | Templates                #
#================================================================================================================================================#

#================================================================================================================================================#
#                                                                                                                     |                          #
##################################################################################
#                                                                                #
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !

#================================================================================================================================================#
#                                                                                                                     | Setup:                   #
#                                                                                                                     | Variables, Credentials,  #
#                                                                                                                     | Connections, etc.        #
#================================================================================================================================================#

$DEBUGGING = $true

$domain_controller  = "kspad04.internal.ksphosting.com"
$domain_account     = "KSP_CORPORATE\kspadmin"
# ~~TODO(dallas)~~: figure out why 'kspemail04.internal.ksphosting.com' doesn't work
#                       It's because DNS on TS05 is resolving kspemail04 to both 204.11.51.86 and 204.11.51.88
#                       .86 sucks a butt. .86 works fine
$mail_server        = "kspemail04.internal.ksphosting.com"
$mail_server_uri    = "http://$mail_server/Powershell/"

$company_name       = "Cubbon Advertising"
$company_ou         = "OU=$company_name,OU=Customers,DC=internal,DC=ksphosting,DC=com"

$tenant_name        = "cubbonadvertising.onmicrosoft.com"
$tenant_account     = "ksp365admin@${tenant_name}"

if($ksp_cred         -eq $null) { $ksp_cred =         (Get-Credential $domain_account) }
if($ksp365admin_cred -eq $null) { $ksp365admin_cred = (Get-Credential $tenant_account) }
# NOTE(dallas): doesn't seem to actually be needed in the scripting process
#               currently only used when setting up Fly connection
# if($kspadmin365_cred -eq $null) { $kspadmin365_cred = (Get-Credential <o365 account>) }

# AD session to $domaincontroller
if($ad_session -eq $null -or $ad_session.State -ne "Opened")
{
    $ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
    Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
    Import-PSSession -Session $ad_session -Module ActiveDirectory
}

# Exchange Online session to O365
if($o365_session -eq $null -or $o365_session.State -ne "Opened")
{
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

$script_location_IncreaseMaxSendRcv = ".\Increase-MaxSendRcv.ps1"
$script_location_ExportOnmicrosoftSmtp = ".\Export-OnmicrosoftSmtp.ps1"

# TODO(dallas): debugging, remove me
if($true)
{
    $script_location_IncreaseMaxSendRcv = "..\Increase-MaxSendRcv.ps1"
    $script_location_ExportOnmicrosoftSmtp = "..\Export-OnmicrosoftSmtp.ps1"
}

. $script_location_IncreaseMaxSendRcv
# . $script_location_ExportOnmicrosoftSmtp

Increase-MaxSendRcv $true

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !
#!   "c.	Verify permissions for shared resources (Public Folders, Shared      !
#!   Mailboxes/Calendars, Resource mailboxes). Rebuild these in new environment  !
#!   as much as possible."                                                       !
#!                                                                               !
#!   Basically, just handbomb all of the hosted Exchange shared resources... -_- !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Export-OnmicrosoftSmtp $true

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !
#!   -Paste resulting '...onmicrosoft.com' into Destination Email Address column !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function Export-PrimarySmtp() {
    #================================================================================================================================================#
    #                                                                                                                     | Export Hosted Email      #
    #                                                                                                                     | Address                  #
    #================================================================================================================================================#

    ##################################################################################
    # HowTo, Step 4f                                                                 #
    # SET $ou VARIABLE                                                               #
    # \\kspemail04\c$\scripts\export list of primarysmtp addresses for single ou.ps1 #
    ##################################################################################

    $primary_smtp_csv_name = "primary_smtp.csv"
    $primary_smtp_csv_path = "."
    $primary_smtp_csv_fullpath = "${primary_smtp_csv_path}\${primary_smtp_csv_name}"

    Get-HostedMailbox -OrganizationalUnit $company_ou | sort Alias | select PrimarySmtpAddress | Export-CSV $primary_smtp_csv_fullpath
}

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !
#!  -Copy output and match addresses to the '...onmicrosoft.com' accounts in FLY !
#!      template                                                                 !
#!                                                                               !
#!  Make sure the 'Source Type' and 'Destination Type' are set properly          !
#!  Again, handbomb ALL of these settings, I guess... -_-                        !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function Create-MappingCSV() {
    #================================================================================================================================================#
    #                                                                                                                     | Generate Mapping CSV     #
    #================================================================================================================================================#

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


    # CRITICAL(dallas): generate onmicrosoft.csv w/ AAD USERS, not MAILBOXES
    $samaccountname_csv_name = "samaccountnames.csv"
    $samaccountname_csv_path = "."
    $samaccountname_csv_fullpath = "${samaccountname_csv_path}\${samaccountname_csv_name}"

    $sams = (Get-ADUser -Filter * -SearchBase $company_ou | sort SamAccountName | select -ExpandProperty SamAccountName)
    # TEST(dallas): make sure this sanity check is acceptable
    if($addresses.length -ne $sams.length)
    {
        Write-Error "Mismatching number of onmicrosoft.com vs samaccountnames. Skipping 'samaccountname' generation"

        # NOTE(dallas): This check failed during Cubbon's migration, as they had AD-synced shared-mailbox users, but only 
        #               regular email users were licensed, and we were using 'Get-Mailbox'. Fixed by Get-User'ing instead
    }
    else
    {
        for($i = 0; $i -lt $addresses.length; $i++)
        {
            $sam = $sams[$i]
            # TODO(dallas): Figure out a better way to concatenate data from the two objects than continually tacking on
            #               new members to a single, monolithic (arbitrary) object
            #               
            #               ...
            #               
            #               or maybe just stop doing this stupid shit...
            $addresses[$i] | Add-Member @{samaccountname=$sam}
        }
    }
    # TEST(dallas): Review this csv output
    $addresses | select email_addresses,samaccountname | Export-CSV $samaccountname_csv_fullpath
}

function Export-AliasesAndAttributes() {
    #================================================================================================================================================#
    #                                                                                                                     | Export On-Prem Exchange  #
    #                                                                                                                     | Aliases and Attributes   #
    #================================================================================================================================================#

    ##################################################################################
    # HowTo, Step 7g-j                                                               #
    # SET $csv & $companyname VARIABLE                                               #
    # ~~\\kspad06\c$\Scripts\O365\migratetargetandmailattributes.ps1~~               #
    # \\kspad06\c$\Scripts\O365\MigrateProxyTargetandMailAttributes.ps1              #
    ##################################################################################

    # TODO(dallas): Clean up all this shit.

    # TODO(dallas): no need to import this, we should have everything we need already in a variable
    $csv = ".\samaccountnames.csv"
    $username = import-csv $csv

    #Locates the accounts from the csv, copies their "mail" attribute. Saves as $mail variable and exports to CSV
    $mail_target_csv_name = "mail_target.csv"
    $mail_target_csv_path = "."
    $mail_target_csv_fullpath = "${mail_target_csv_path}\${mail_target_csv_name}"
    $mail = ($username | % { Get-ADUser $_.SamAccountName -Properties Mail })
    $mail | Export-CSV $mail_target_csv_fullpath # WHY EXPORT THESE CSVS WHEN THEY'RE ALL THE SAME AND THEY'RE NEVER USED AHUGOIWIAESRG IOPJT'RJWRGUOI'IHJBRWNHJL  

    #Locates the accounts from the csv, copies their proxy addresses, seperates them into usable text. Saves to $proxy variable and exports as csv.
    $proxy_address_csv_name = "proxy_addresses.csv"
    $proxy_address_csv_path = "."
    $proxy_address_csv_fullpath = "${proxy_address_csv_path}\${proxy_address_csv_name}"
    $proxy = ($username                                                                                 |
        % { Get-ADUser $_.SamAccountName -Properties * }                                                |
        # NOTE(dallas): The original script flattened all the proxyaddresses, joining them with ';'.    |
        #               Because X.500 addresses have tons of ';'s in them, this was a poor delimiter;   |
        #               the script later split this flat string using ';' and added all tokens to the   |
        #               user's proxyaddress, leading to shit like:                                      |
        #                                                                                               |
        #                           "{ , G=John , S=Doe , O=KSP?CORPORATE ...}"                         |
        #                                                                                               |
        #               I can only assume it was written like this so the addresses could be            |
        #               serialized to a CSV nicely, so that a separate script could parse them, but     |
        #               it's so much nicer to just use a single script so the addresses are in an       |
        #               array that you can just index                                                   |
        # select SamAccountName, @{"name"="proxyaddresses";"expression"={ $_.proxyaddresses -join ";" }})

        # NOTE(dallas): is it common for there to be ONLY smtp addresses?...

        # TEST(dallas): make sure that the object & CSV looks ok using this method                      |
        select SamAccountName, ProxyAddresses)
    $proxy | Export-CSV $proxy_address_csv_fullpath # WHY EXPORT THESE CSVS WHEN THEY'RE ALL THE SAME AND THEY'RE NEVER USED AHUGOIWIAESRG IOPJT'RJWRGUOI'IHJBRWNHJL  

    #Gets the users' legacy DN attributes
    $legdn_csv_name = "legdn.csv"
    $legdn_csv_path = "."
    $legdn_csv_fullpath = "${legdn_csv_path}\${legdn_csv_name}"
    $legdn = ($username | % { Get-ADUser $_.SamAccountName -Properties * | select SamAccountName, LegacyExchangeDN })
    $legdn | Export-CSV $legdn_csv_fullpath # WHY EXPORT THESE CSVS WHEN THEY'RE ALL THE SAME AND THEY'RE NEVER USED AHUGOIWIAESRG IOPJT'RJWRGUOI'IHJBRWNHJL  
}

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !
#!   -Verify the 3 (3 ?!?!?!??!?!?!??!??!?!!!??!) CSVs                           !
#!   -Delete mailboxes, address lists, address policies, ABPs, domains, LEAVE    !
#!              ABP->AL->EAP->AD                                                 !
#!              Apparently the order matters for some reason...                  !
#!      DISTRO GROUPS ALONE                                                      !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# IMPORTANT(dallas): VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
# TEST(dallas):      Acme's migration was FUBAR. Test this thoroghly
function Reapply-AliasesAndAttributes() {
    #================================================================================================================================================#
    #                                                                                                                     | Reapply Exchange         #
    #                                                                                                                     | Attributes               #
    #================================================================================================================================================#

    ##################################################################################
    # HowTo, Step 7m                                                                 #
    # ~~\\kspad06\c$\Scripts\O365\migratetargetandmailattributes.ps1~~               #
    # \\kspad06\c$\Scripts\O365\MigrateProxyTargetandMailAttributes.ps1              # 
    ##################################################################################

    # TODO(dallas): for debugging, remove me
    if($false)
    {
        $mail_target_csv_fullpath = ".\mail_target.csv"
        $proxy_address_csv_fullpath = ".\proxy_addresses.csv"
        $legdn_csv_fullpath = ".\legdn.csv"
        $mail = import-csv $mail_target_csv_fullpath
        $proxy = Import-Csv $proxy_address_csv_fullpath
        $legdn = Import-Csv $legdn_csv_fullpath
    }

    #Takes email addresses from previously stored variables and restores them following deletion of mailbox.
    $mail | % { Set-ADUser $_.SamAccountName -Replace @{mail = $_.mail } }

    #~~Locates the accounts from csv, adds "Destination" field as target address.~~
    # NOTE(dallas): the CSV is now being created dynamically with an 'email addresses" field rather than 'destination'
    #               it looks like the 'Destination' was never actually used though, as the target address is replaced with
    #               '$_.targetaddress', which never existed in the original, by-hand CSV -_-
    #~~$username | % { Set-ADUser $_.SamAccountName -Replace @{targetaddress = $_.targetaddress } -WhatIf }~~
    $username | % { Set-ADUser $_.SamAccountName -Replace @{targetaddress = $_.email_addresses } }

    #Takes proxy addresses stored in variable, restores them to the account following deletion of mailboxes.

    Foreach($p in $proxy) {
        Set-ADUser $p.SamAccountName -Clear proxyaddresses
        foreach($address in $p.proxyaddresses)
        {
            # TODO(dallas): Do we need to transfer X.400 addresses? Filter out, maybe...
            Set-ADUser $p.SamAccountName -Add @{proxyaddresses = $address}
        }
    }

    #Takes legacyexchangedn property stored in variable, restores it as an x500 proxy address
    # NOTE(dallas): because of the bad delimiter on line 343, this likely won't work...
    #               also, because 1 x400 addresses has many ';'s, won't this add a ton of incomplete proxyaddresses?
    #               also, can you just upgrade x400 addresses to x500 addresses? even if you could, this still won't work
    #               because the first split "x400" token would still exist, leading the resulting proxyaddresses to look like:
    #                   {
    #                       "x400:x500:"
    #                       "x400:C=US"
    #                       "x400:A="
    #                       "x400:P=KSP HOSTING"
    #                       ...
    #                   }
    # NOTE(dallas): Seems that adding the legacyExchangeDN as an X.500 address to the list of proxyadresses may be
    #               equivalent to adding it back to the legacyExchangeDN attribute. What are the differences, if any?
    #               Check with Kevin
    $legdn | % {
        $fake_x500 = "x500:$($_.legacyexchangedn)"

        #Set-ADUser $_.SamAccountName -Add @{proxyaddresses="x500:" + $_.legacyexchangedn } -WhatIf
        Set-ADUser $_.SamAccountName -Add @{proxyaddresses=$fake_x500 } 
    }
}

#================================================================================================================================================#
#                                                                                                                     | Final Tasks & Cleanup    #
#================================================================================================================================================#
$LAST_MANUAL_TASKS=$false

##################################################################################
# HowTo, Step 7n-p                                                               #
##################################################################################

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#! MANUAL WORK:                                                                  !
#!   -Enable AD Sync                                                             !
#!   -"o.	Add target addresses for distribution groups manually. This could    !
#!      potentially be scripted, but hasn’t been tested at time of writing."     !
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

if($LAST_MANUAL_TASKS)
{
    (get-distributiongroup | set-distrigutiongroup -requiresenderauthentication $false)

    if (-not $DEBUGGING) {
        # if($X_session -and...) would probably work too, right?
        if ($ad_session       -ne $null -and $ksp_session.State      -eq "Opened") { Remove-PSSession -Session $ksp_session      }
        if ($o365_session     -ne $null -and $o365_session.State     -eq "Opened") { Remove-PSSession -Session $o365_session     }
        if ($exchange_session -ne $null -and $exchange_session.State -eq "Opened") { Remove-PSSession -Session $exchange_session }
        # TODO(dallas): remove csvs
    }
}