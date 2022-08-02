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
############################################################################################################################################################
######  Export them Distribution groups to a CSV  ##########################################################################################################
############################################################################################################################################################

#Export DL's from diven OU
$DLCSVfile = 'DLExport.csv'
$OU = 'Construction Labour Relations - External Distribution Groups'
$Groups_Path = 'Z:\Evan\Groups For Holly'
Get-HostedDistributionGroup -OrganizationalUnit $OU -resultsize unlimited | select name,alias,type,EmailAddresses |Export-Csv $DLCSVfile

#Create a CSV for each group and export members of that group to the CSV
$output = @()
$CSVfile = 'DLMembersExport'
$DGs = Get-HostedDistributionGroup -OrganizationalUnit $OU -resultsize unlimited

Foreach($dg in $Dgs)
{
$Members = Get-HostedDistributionGroupMember $Dg.name -resultsize unlimited
 
if($members.count -eq 0)
    {#Check if there are no members and dump an emtpy line for the group if there are none
    $managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}
    $userObj = New-Object PSObject
    $userObj | Add-Member NoteProperty -Name "DisplayName" -Value EmptyGroup
    $userObj | Add-Member NoteProperty -Name "Alias" -Value EmptyGroup
    $userObj | Add-Member NoteProperty -Name "Primary SMTP address" -Value EmptyGroup
    $userObj | Add-Member NoteProperty -Name "Distribution Group" -Value $DG.Name
    $userObj | Add-Member NoteProperty -Name "Distribution Group Primary SMTP address" -Value $DG.PrimarySmtpAddress
     
    $output += $UserObj
    }

else
    {#List all members for the group if there are more than zero
    Foreach($Member in $members)
     {
        $managers = $Dg | Select @{Name='DistributionGroupManagers';Expression={[string]::join(";", ($_.Managedby))}}
        $userObj = New-Object PSObject
        $userObj | Add-Member NoteProperty -Name "First Name" -Value $Member.FirstName
        $userObj | Add-Member NoteProperty -Name "Last Name" -Value $Member.LastName
        $userObj | Add-Member NoteProperty -Name "DisplayName" -Value $Member.Name
        $userObj | Add-Member NoteProperty -Name "Contact Email address" -Value $Member.PrimarySmtpAddress
        $userObj | Add-Member NoteProperty -Name "Group Name" -Value $DG.Name
         
        $output += $UserObj
     }
    }
#Write out membership for this group
$Export_pattern = '[/\\]'
$dg_name = $dg.DisplayName -replace $Export_pattern, '~'
$csv_to_Write = $dg_name + '.csv'
$output | Export-csv -Path $groups_path\$csv_to_Write -NoTypeInformation
$output = @()
}
 
############################################################################################################################################################
######   Import them Distribution groups to 365   ##########################################################################################################
############################################################################################################################################################

#Create the groups in 365 based on what was exported earlier
#NOTE: This doesn't use a CSV Import. Review what was exported to the CSV but know that changes to the CSV won't be reflected.
#NOTE: GroutType will show as "Universal" in PS. It creates with the secificed type fine.
$import_pattern = '~'
Foreach($DG in $DGs)
{
New-o365distributionGroup -name $dg.name -alias $dg.alias -type distribution
}


#Import group members into groups
#Grabs members list from each CSV and adds each alias as a member of the group
$File_list = Get-ChildItem -path $Groups_Path -Filter '*.csv'
foreach ($file in $File_list)
{
   $DLMembers = Import-Csv $File.FullName | select alias
   foreach ($DLMember in $DLMembers)
    {
        $RealGroupName = $file.basename -replace $import_pattern, '\'
        Add-O365DistributionGroupMember -identity $RealGroupName -Member $DLMember.alias
       
    }
   #start-sleep 3
}







#This is garbage copy pasted to keep my mind sane - EA
Import-CSV "C:\Users\Administrator\Desktop\parents.csv" | Foreach-Object 
{ 
Add-DistributionGroupMember -Identity "TestDL2" -Member $_.Member 
}

Get-O365DistributionGroup | Remove-O365DistributionGroup
(Get-HostedDistributionGroup -OrganizationalUnit $OU -resultsize unlimited).count
(Get-o365DistributionGroup -resultsize unlimited).count

$pattern = '~'
$String = 'con~pro list'
$String = $string -replace $pattern, '\'
$string
#^Replace twice, clean up on the way out, put back on the way in for slashes in file paths


