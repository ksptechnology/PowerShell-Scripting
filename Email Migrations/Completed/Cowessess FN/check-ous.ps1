$company_name               = "Bowline Logistics"

$domain_controller          = "kspad04.internal.ksphosting.com"
$domain_account             = "KSP_CORPORATE\kspadmin"

$customer_ou                = "OU=Boyd_Bowline,OU=Customers,DC=internal,DC=ksphosting,DC=com"
$company_ou                 = "OU=$company_name,$customer_ou"
$users_ou_name              = "$company_name - Users"
$distro_ou_name             = "$company_name - Distribution Groups"
$service_ou_name            = "$company_name - Service Accounts"
$security_ou_name           = "$company_name - Security Groups"
$shared_ou_name             = "$company_name - Shared Mailboxes" 
$email_ou_name              = "$company_name - Email Only Users"
$no_sync_ou_name            = "$company_name - No AD Sync" 

$server_ou_name             = "$company_name - Servers"
$server_ou                  = "OU=$server_ou_name,$company_ou"
$terminal_server_ou_name    = "$company_name - Terminal Servers"
$file_server_ou_name        = "$company_name - File Servers"
$other_server_ou_name       = "$company_name - Other Servers"


if($ksp_cred -eq $null) { $ksp_cred = (Get-Credential $domain_account) }

# AD session to $domaincontroller
if($ad_session -eq $null -or $ad_session.State -ne "Opened")
{
    $ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
    Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
    Import-PSSession -Session $ad_session -Module ActiveDirectory
}

New-ADOrganizationalUnit -name $company_name            -path $customer_ou
New-ADOrganizationalUnit -name $users_ou_name           -path $company_ou
New-ADOrganizationalUnit -name $distro_ou_name          -path $company_ou
New-ADOrganizationalUnit -name $service_ou_name         -path $company_ou
New-ADOrganizationalUnit -name $security_ou_name        -path $company_ou
New-ADOrganizationalUnit -name $shared_ou_name          -path $company_ou
New-ADOrganizationalUnit -name $email_ou_name           -path $company_ou
New-ADOrganizationalUnit -name $no_sync_ou_name         -path $company_ou
New-ADOrganizationalUnit -name $server_ou_name          -path $company_ou
New-ADOrganizationalUnit -name $terminal_server_ou_name -path $server_ou
New-ADOrganizationalUnit -name $file_server_ou_name     -path $server_ou
New-ADOrganizationalUnit -name $other_server_ou_name    -path $server_ou

# TODO(dallas): Close Powershell session