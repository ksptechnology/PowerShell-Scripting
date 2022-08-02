#Connect to 365 and AD

#Get domain and determine which username to use for 365 connections
$company_domain     = Read-Host -Prompt 'Tenant Domain'
if ($company_domain -like "*onmicrosoft.com" )
{
    $tenant_account     = "admin@${company_domain}"
}else
{
    $tenant_account     = "kspadmin365@${company_domain}"
}

#DC and on-prem exchange servers
$domain_controller  = "kspad04.internal.ksphosting.com"
$domain_account     = "KSP_CORPORATE\kspadmin"

$mail_server        = "kspemail04.internal.ksphosting.com"
$mail_server_uri    = "http://$mail_server/Powershell/"

#Get credentials based on above
if($ksp_cred         -eq $null) { $ksp_cred =         (Get-Credential $domain_account) }
if($ksp365admin_cred -eq $null) { $ksp365admin_cred = (Get-Credential $tenant_account) }


# AD session to $domaincontroller
if($ad_session -eq $null -or $ad_session.State -ne "Opened")
{
    $ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
    Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
    Import-PSSession -Session $ad_session -Module ActiveDirectory
}

# Exchange Online and MS Online session to O365
if($o365_session.State -ne "Opened")
{
    if($o365_session -ne $null) { Remove-PSSession $o365_session; $o365_session = $null }
    $o365_session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $ksp365admin_cred -Authentication Basic -AllowRedirection
    Import-PSSession -Prefix O365 -Session $o365_session -DisableNameChecking 
}

# Exchange session to $mail_server
if($exchange_session -eq $null -or $exchange_session.State -ne "Opened")
{
    $exchange_session = New-PSSession -ConfigurationName Microsoft.Exchange -Authentication Kerberos -ConnectionUri $mail_server_uri -Credential $ksp_cred 
    Import-PSSession -Prefix Hosted -Session $exchange_session -DisableNameChecking 
}

#Export Contacts to one large CSV file
#Any errors from this portion are likey due to the user not existing as an actual mail enabled contact
$csvfilename="CLR_Contacts_Export.csv"
New-Item $csvfilename -type file -force
Add-Content $csvfilename "Name,DisplayName,FirstName,LastName,Alias,Email"
$contacts = Get-HostedContact -OrganizationalUnit "Construction Labour Relations - Contacts" -ResultSize unlimited
foreach($contact in $contacts)
{
    $Name =$Contact.name	
	$FirstName =$Contact.FirstName
	$LastName=$Contact.LastName
	$Company =$Contact.Company
	$DisplayName=$Contact.DisplayName

	$MailContact=Get-hostedMailContact -Identity $Name
	$ExternalEmailAddress =$MailContact.ExternalEmailAddress
    $alias = $MailContact.alias

    Add-Content $csvfilename "$name,$displayname,$firstname,$lastname,$alias,$externalemailaddress" 
}

#NOTE: If any contacts have multiple SMTP addresses or Aliases, they won't be created. 
#This occurs when there's multiple contacts with the same display name to them. 
#Tried but wasn't able to get anything other than the display name as the input.
#Try/Catch should be able to at least document the failures when importing.
#Really, go through and fix any you know are issues first.
#!!!!! GO THROUGH THE CSV AND DO A FIND REPLACE TO REMOVE ALL SMTP: ENTRIES FROM THE CSV !!!!!

#Import the CSV once it's cleaned up and import into 365
$new_contacts = Import-Csv $csvfilename
$Error_csv = "Error_Contacts.csv"
new-item $Error_csv -type file -force

foreach($new_contact in $new_contacts)
{
#NOTE: Try catch will catch any duplicated aliases you missed fixing from the export
    # NO IT WONT! No idea why this failed in real use but it did. None of the errors dumped to the CSV...
    Try 
    
    {
        New-O365MailContact -name $new_contact.name -DisplayName $new_contact.displayname -ExternalEmailAddress $new_contact.email -FirstName $New_Contact.FirstName -LastName $New_contact.LastName -alias $new_contact.alias
    }
    catch 
    {
        Add-Content $Error_csv "$_"
    }
}


#Check to compare CSV's for errors... Try/Catch didn't work. Compare the CSV's with Excel

$365csvfilename="CLR_365_Contacts_Export.csv"
New-Item $365csvfilename -type file -force
Add-Content $365csvfilename "Name,DisplayName,FirstName,LastName,Alias,Email"
$365contacts = Get-o365Contact -ResultSize unlimited
foreach($365contact in $365contacts)
{
    $Name =$365Contact.name	
	$FirstName =$365Contact.FirstName
	$LastName=$365Contact.LastName
	$Company =$365Contact.Company
	$DisplayName=$365Contact.DisplayName

	$365MailContact=Get-o365MailContact -Identity $Name
	$ExternalEmailAddress =$365MailContact.ExternalEmailAddress
    $alias = $365MailContact.alias

    Add-Content $365csvfilename "$name,$displayname,$firstname,$lastname,$alias,$externalemailaddress" 
}

#Keeping this around. This section will split the CSV's for GUI imports.
<#
#NOTE(Evan): Do we really need this? Why not just import the big CSV into new contacts with PS???
#Split that CSV down to multiple smaller ones. EXO will only support files at a max of 40 lines including headers.

$Max_lines = 40 #Non-inclusive (if set to 40, the generated CSVs will only have 39 lines plus headers = 40)

$counter = 1
$num_csv_files = 1
$csv_to_write = 'Z:\Evan\Contacts' + 'Split' + $num_csv_files + '.csv'

Import-Csv $csvfilename | ForEach-Object {


    if ($counter -lt $Max_lines) {
        $_ | Export-Csv -Path $csv_to_write -Append -NoTypeInformation
        $counter++
    } else {
        $num_csv_files++
        $csv_to_write = $Root_folder + 'Split' + $num_csv_files + '.csv'
        $_ | Export-Csv -Path $csv_to_write -Append -NoTypeInformation
        $counter = 2
    }

}


#>
# (Get-HostedContact -OrganizationalUnit "Construction Labour Relations - Contacts" -ResultSize unlimited).count