## Connect_Me TK REMIX
param(
	[Parameter(Mandatory = $false)]
	[switch]$Reset
)

Start-Transcript


#Define servers
$domain_controller  = "kspad04.internal.ksphosting.com"
$domain_account     = "KSP_CORPORATE\kspadmin"

$mail_server        = "204.11.51.89"
$mail_server_uri    = "http://$mail_server/Powershell/"

$fake_pass = ConvertTo-SecureString "This is not a real password" -AsPlainText -Force
$fake_creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "NT AUTHORITY\ANONYMOUS LOGON", $fake_pass

$myScript = Write-Host $MyInvocation.MyCommand
#Send-MailMessage -Credential $fake_creds -To $destination -From $origin -SmtpServer 204.11.51.89 -Subject $subject

#################
### FUNCTIONS ###
#################

function Connect-Help {
    Show-Header -Title "Connect Me Cheat Sheet!"
    Write-Host
    Write-Host 
    Write-Host
    Write-Host
    Write-Host "This is where something useful will live"
    Write-Host
    Write-Host
    Write-Host
    Write-Host
    "========================================"
}

function Connect-OnPremAD {
    # AD session to $domaincontroller
    if($ksp_cred         -eq $null) { 
        $ksp_cred =         (Get-Credential $domain_account) 
    }
    if($ad_session -eq $null -or $ad_session.State -ne "Opened") {
        $ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
        Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
        Import-PSSession -Session $ad_session -Module ActiveDirectory
    }
    Clear-Host

    Write-Host "You're now connected to on-prem AD!"
    Write-Host "There are no prefixes for on-prem AD"
}

function Connect-OnPremExchange {
    # Exchange session to $mail_server
    if($ksp_cred         -eq $null) { 
        $ksp_cred =         (Get-Credential $domain_account) 
    }
    if($exchange_session -eq $null -or $exchange_session.State -ne "Opened") {
        $exchange_session = New-PSSession -ConfigurationName Microsoft.Exchange -Authentication Kerberos -ConnectionUri $mail_server_uri -Credential $ksp_cred 
        Import-PSSession -Prefix Hosted -Session $exchange_session -DisableNameChecking 
    }
    Clear-Host
    Write-Host "You're now connected to on-prem Exchange!"
    Write-Host "Please use the prexix 'hosted' for any on-prem Exchange commands"
}

function Connect-toExchangeOnline{
    # Exchange Online and MSOL session to O365
    #Get domain and determine which username to use for 365 connections

    ### GET EXCHANGE MODULE ###
    #This is to make sure that the machine running it has the right modules installed.
    #Should be redundant on the server, but it'll 
    try {
        Import-Module –Name ExchangeOnlineManagement –RequiredVersion 2.0.5
        Write-Host "Module exists"
        Import-Module ExchangeOnlineManagement 
    } 
    catch {
        Write-Host "Module does not exist"
        Write-Host "Continue to install, or exit now"
        Pause
        Write-Host "...Installing Now"
        Install-Module –Name ExchangeOnlineManagement –RequiredVersion 2.0.5 
        Import-Module –Name ExchangeOnlineManagement –RequiredVersion 2.0.5
    }

    #Get domain and determine which username to use for 365 connections
    
    Clear-Host
    Show-Header -Title "Connect to Exchange Online!"
    Write-Host "Enter A Domain: MyDomain.Ca"
    Write-Host "       Or"
    Write-Host "Enter the Admin Email: KSPAdmin365@MyDomain.ca"
    Write-Host 
    $company_domain = Read-Host -Prompt 'Please Enter Tenant Domain: '
    
    if ( $company_domain -eq "") {
        Complete-ExchangeOnline
    } 
    elseif ( $company_domain -Match "@"){
        Complete-ExchangeOnline -Tenant $company_domain     
    }    
    else {    
        if ($company_domain -like "*onmicrosoft.com" ) { $tenant_account = "admin@${company_domain}"
        } else {$tenant_account = "kspadmin365@${company_domain}"}

        if($ksp365admin_cred -eq $null) { $ksp365admin_cred = (Get-Credential $tenant_account) }

        Complete-ExchangeOnline -Tenant $ksp365admin_cred
    }
     Write-Host "Shouldn't get here"
     Pause
 }

 function Complete-ExchangeOnline{
    Param (
        $Tenant = $null
    )
   try {
       if ($Tenant -eq $null) {
            Write-Host "null"
            Connect-ExchangeOnline
       } else {
            $Creds = (Get-Credential $Tenant)
            Connect-ExchangeOnline -Credential $Creds
       }
   } catch {
      Write-Host "There was an issue connecting to the Exchange, returning to previous menu"
      Pause
      Connect-toExchangeOnline   
   }
    Show-Outro
    Exit
 }

 function Show-Outro {
     Param (
        $Title = "You Are Now Connected!"
    )
 Clear-Host
 Show-Header -Title $Title
 Write-Host "You can use these commands to interact with the Connect-Me Script"
 Write-Host
 Write-Host "Connect-Me - Return to the script"
 Write-Host
 Write-Host "Disconnect-Me - Clean up all existing connections"
 Write-Host
 Write-Host "Connect-Help - List of KSP'S commonly used commands"
 Write-Host
 Write-Host "========================================"
 Exit
 }

function Connect-Me {
    Selection-Menu
}

function Disconnect-Me {
    Quit-Sessions
}

function Quit-Sessions {
    Get-PSSession | Remove-PSSession
    $ksp365admin_cred = $null
    $ksp_cred = $null
    Clear-Host
    Write-Host "You're disconnected from all sessions!"
    Exit
    Break
}

#Create Menu
function Show-Header {
    Param (
        [String]$Title = 'Connect Me!'
    )
    Clear-Host
    Write-Host "========================================"
    Write-Host " $Title "
    Write-Host "========================================"
    Write-Host
}

# Create Menu #
function Show-Menu {
    
    Write-Host "1: Connect to On-Premise AD"
    Write-Host "2: Connect to On-Premise Exchange"
    Write-Host "3: Connect to Exchange Online and MSOL"
    Write-Host "Q: Disconnect all sessions"
    Write-Host

}

function Selection-Menu {

do {
    Show-Menu
    $input = Read-Host “Please make a selection”
    switch ($input) {
        ‘1’ {
            CLS
            ‘You chose option #1’
        }
        ‘2’ {
            CLS
            ‘You chose option #2’
        }
        ‘3’ {
            CLS
            Connect-toExchangeOnline
        }
        ‘q’ {
            Quit-Sessions
        }
    }
    Pause
}
until ($input -eq ‘q’)
}
#>
###############################################################################################################################################
##MAIN

####################
### Self-elevate ###
####################

Show-Header -Title "Welcome to Connect Me!"
if (!$Reset){
    Write-Host "...Checking Permissions And Configuration"
    $MyInvocation.MyCommand.Name
    $CommandLine = "-NoLogo -NoExit -File `"" + $MyInvocation.MyCommand.Name + "`" " + $MyInvocation.UnboundArguments + " -Reset"
  
    if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        #  checks to see if the Windows operating system build number is 6000 (Windows Vista) or greater. Earlier builds did not support Run As elevation.
        if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
            
########### DOES STUFF WHEN IT DOESN'T HAVE PERMISSIONS ###

            if ($Host.Name -NotLike "Windows PowerShell ISE Host") {
                Write-Host "is not like"
                Write-Host "Relaunching Shell With Additional Configurations"
                Write-Host "Located at"$MyInvocation.MyCommand.Path


                #Starts the new session with Elevated User 
                #Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
                Start-Process -FilePath PowerShell.exe -ArgumentList $CommandLine
                Exit   
            } else {
                Write-Host "PowerShell ISE Detected, not relaunching script" 
            }

      
        } else {
            Write-Host This version Of Windows does not support Run As elevation
            Pause
            Exit
        }
    } else {
        Write-Host "Already Has Admin Privilages..."

######## DOES THIS STUFF IF IT DOES HAVE PERMISSIONS
            if ($Host.Name -NotLike "Windows PowerShell ISE Host") {
                Write-Host "is not like"
                Write-Host "Relaunching Shell With Additional Configurations"
                Write-Host "Located at"$MyInvocation.MyCommand.Path


                #Starts the new session with Elevated User 
                #Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
                Start-Process -FilePath PowerShell.exe -ArgumentList $CommandLine
                Exit   
            } else {
                Write-Host "PowerShell ISE Detected, not relaunching script" 
            }
    }
}
############
### MAIN ###
############

Show-Header -Title "Welcome to Connect Me!"
Selection-Menu 
Stop-Transcript