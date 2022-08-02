#==================================================================
#==============Stolen first part from email.ps1====================
#==================================================================

$domain_controller  = "kspad04.internal.ksphosting.com"
$domain_account     = "KSP_CORPORATE\kspadmin"

$mail_server        = "kspemail04.internal.ksphosting.com"
$mail_server_uri    = "http://$mail_server/Powershell/"

$company_name       = "Construction Labour Relations"
$company_ou         = "OU=$company_name,OU=Customers,DC=internal,DC=ksphosting,DC=com"

$tenant_name        = "clrsask.onmicrosoft.com"
$company_domain     = "clrs.org"
$tenant_account     = "kspadmin365@${company_domain}"

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

#==========================================================================
#================Contact and DL Export test - Evan=========================
#==========================================================================

#Get groups and contacts
$groups = get-adgroup -filter 'GroupCategory -eq "Distribution"' -searchbase $company_ou -properties mail,name | select mail,name,SamAccountName
$contacts = get-adobject -filter 'objectclass -eq "contact"' -SearchBase $company_ou -Properties name,mail | select mail,name
#--->Line I'm kinda stuck on. Exports the "MemberOf" as the CN rather than the email. Need to talk with Dallas on how to fix that - EA
$contact_membership = get-adobject -Filter 'objectclass -eq "contact"' -SearchBase $company_ou -Properties name,mail,memberof | Select mail,name,memberof

#CSV Paths
$memberscsv = "Z:\Email Migrations\$company_name\membersAD.csv"
$groupscsv = "Z:\Email Migrations\$company_name\groupsAD.csv"
$contactscsv = "Z:\Email Migrations\$company_name\contactsAD.csv"
$Contactmemberscsv = "Z:\Email Migrations\$company_name\ContactMembers.csv"
$contactCleanupCSV = "Z:\Email Migrations\$company_name\ContactCleanup.csv"
#Get members of groups - WIP see above {line 52-53 atm} -- This one doesn't 
$dist_membership = $null
foreach ($group in $groups) {
    try {
        $members = get-adgroupmember $group.SamAccountName
        $dist_membership += $members | select-object * , @{n = 'GroupName'; E = { $group.Name } }, @{n = 'Groupemail'; E = { $group.mail } }
    }
    catch {
        [system.exception]
        write-host$error
        write-host"Error get group member data for$group.name"
    }
}
#Create CSV's
$groups | export-csv -Path $groupscsv
$contacts | export-csv -path $contactscsv
$contact_membership | Export-Csv -path $Contactmemberscsv
$dist_membership|export-csv -Path $memberscsv

#Export group memberships -- New
$Membership_cleanup = import-csv $Contactmemberscsv | ForEach-object {
    $_.memberof = $_.memberof -replace ",OU=Construction Labour Relations - External Distribution Groups,OU=Construction Labour Relations - Mail Contacts,OU=Construction Labour Relations,OU=Customers,DC=internal,DC=ksphosting,DC=com","" -replace "CN=",""
    $_
}
$Membership_cleanup | Export-csv -path $contactCleanupCSV

#==========================================================================
#================Contact and DL Import test - Evan=========================
#==========================================================================

$members = Import-Csv $memberscsv
$groups = import-csv $groupscsv
$contacts = import-csv $contactscsv

foreach ($contact in $contacts ) {
        try {
            #Creates the contacts 
            New-O365MailContact -name $contact.Name -ExternalEmailAddress $contact.mail
            write-host "Creating $contact.name"
        }
        Catch{
            [System.Exception]
            write-host "Error making $contact.name"
        }
}

foreach ($group in $Groups) {
        Try {
            #Creates new groups and allows external Senders
            $g = New-O365DistributionGroup -name $group.Name -PrimarySmtpAddress $group.mail -Type Distribution -RequireSenderAuthenticationEnabled $false
            write-host "Creating $group.mail"
                       
        }

        Catch {
            [System.exception]
            write-host "Error making $group.mail"
        }

        try {
            #Adds members to their groups
            $members_d = $members | Where-Object -FilterScript { $_.groupemail -eq $group.mail } | select samaccountname
            foreach ($member_d in $members_d) {
                Add-O365DistributionGroupMember -Identity $group.mail -Member $member_d.SamAccountName
            }
        }

        catch{
        [System.exception]
        write-host "Error adding members for $group.mail"
        
        }
}