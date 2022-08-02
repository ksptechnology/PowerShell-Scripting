function Initialize-Props {
    Begin {
        # NOTE(dallas): 'return'ing from Advanced PowerShell Functions sucks. This will exit the 'Begin' block only and 
        #               continue onto the 'Process' block
        if ($props_initialized) { return; }
        Write-Host "==== Loading 'props.json'"
        $prop_file = "props.json"
        try {
            # NOTE(dallas): Without the '-ErrorAction' parameter, Get-Content doesn't throw a terminating error, and it won't be caught by Try/Catch
            $script:props = (Get-Content -Raw $prop_file -ErrorAction Stop | ConvertFrom-Json)
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            Write-Error "Failed to load props file! ($($_.TargetObject))"
            Exit -1
        }
        catch {
            Write-Error "Unexpected error when parsing company props.json: $_"
            Exit -1
        }
        if ($props.company_name -eq $null) { Write-Error "Failed to parse properties: 'company_name' missing!"; exit -1 }
        if ($props.domain_controller -eq $null) { Write-Error "Failed to parse properties: 'domain_controller' missing!"; exit -1 }
        if ($props.domain_account -eq $null) { Write-Error "Failed to parse properties: 'domain_account' missing!"; exit -1 }
        if ($props.mail_server -eq $null) { Write-Error "Failed to parse properties: 'mail_server' missing!"; exit -1 }
        if ($props.tenant_name -eq $null) { Write-Error "Failed to parse properties: 'tenant_name' missing!"; exit -1 }
        if ($props.tenant_account -eq $null) { Write-Error "Failed to parse properties: 'tenant_account' missing!"; exit -1 }
        if ($props.company_domain -eq $null) { Write-Error "Failed to parse properties: 'company_domain' missing!"; exit -1 }
        # It's stupid that I have to specify this just because someone was too incompetent to name the public folder the same as the company name
        if ($props.public_folder_name -eq $null) { Write-Error "Failed to parse properties: 'public_folder_name' missing!"; exit -1 }

    }

    Process {
        if ($props_initialized) { return; }
        Write-Host "Initializing Properties..."

        $script:company_name = $props.company_name
        $script:company_ou = "OU=$company_name,OU=Customers,DC=internal,DC=ksphosting,DC=com"
        $script:users_ou = "OU=$company_name - Users,$company_ou"
        $script:distro_ou = "OU=$company_name - Distribution Groups,$company_ou"
        $script:security_ou = "OU=$company_name - Security Groups,$company_ou"
        $script:shared_ou = "OU=$company_name - Shared Mailboxes,$company_ou" 
        $script:email_ou = "OU=$company_name - Email Only Users,$company_ou"
        $script:mailbox_ous = $users_ou, $distro_ou, $security_ou, $shared_ou, $email_ou

        $script:domain_controller = $props.domain_controller
        $script:domain_account = "KSP_CORPORATE\$($props.domain_account)"
        $script:mail_server = $props.mail_server
        $script:mail_server_uri = "http://$mail_server/Powershell/"
        $script:public_folder_name = $props.public_folder_name
        $script:public_folders = "\Customer Folders\$public_folder_name"

        $script:tenant_name = $props.tenant_name
        $script:company_domain = $props.company_domain
        $script:tenant_account = "$($props.tenant_account)@$($props.company_domain)"

        Write-Host "...done"
    }

    End {
        $script:props_initialized = $true
    }
}
function ReInitialize-Props {
    Begin {
        $script:props_initialized = $false
    } 

    Process {
        Initialize-Props
    }
}

function Initialize-Creds {
    Begin {
        Initialize-Props
    } 

    Process {
        if ($creds_initialized) { return; }
        Write-Host "Initializing Credentials..."

        $script:ksp_cred = (Get-Credential $domain_account)
        $script:ksp365admin_cred = (Get-Credential $tenant_account)

        Write-Host "...done"
    }

    End {
        $script:creds_initialized = $true
    }
}
function ReInitialize-Creds {
    Begin {
        $script:creds_initialized = $false
    } 

    Process {
        Initialize-Creds
    }
}
 
function Initialize-Cons {
    Begin {
        Initialize-Creds
    } 

    Process {
        if ($cons_initialized) { return; }
        Write-Host "Initializing Connections..."
        # AD session to $domaincontroller
        if ($ad_session -ne $null) {
            Write-Host "==== Disconnecting old session to $($ad_session.ComputerName)"
            Remove-PSSession $ad_session
        }
        $script:ad_session = New-PSSession -Computername $domain_controller -Credential $ksp_cred
        Invoke-Command -Session $ad_session { Import-Module ActiveDirectory }
        Import-PSSession -Session $ad_session -Module ActiveDirectory

        # Exchange session to $mail_server
        if ($exchange_session -ne $null) {
            Write-Host "==== Disconnecting old session to $($exchange_session.ComputerName)"
            Remove-PSSession $exchange_session
        }
        $script:exchange_session = New-PSSession -ConfigurationName Microsoft.Exchange -Authentication Kerberos -ConnectionUri $mail_server_uri -Credential $ksp_cred 
        Import-PSSession -Prefix Hosted -Session $exchange_session -DisableNameChecking

        # Azure AD session to O365
        # NOTE(dallas): The Azure module doesn't work by importing modules/commands and therefore can't be tracked with session variables
        #               It can be connected to multiple times regardless of the current state, and a single 'Disconnect-AzureAD' command
        #               will disconnect everything
        #               Also, without prompting for credentials, it actually runs pretty quickly, so it should be fine to just run this
        #               every time
        $azure_connected = $true
        $azure_info = $null
        try {
            $azure_info = Get-AzureADCurrentSessionInfo -ErrorAction Stop
        }
        catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] {
            $azure_connected = $false
        }
        if ($azure_connected) {
            Write-Host "==== Disconnecting old Azure connection for $($azure_info.Account)"
            Disconnect-AzureAD
        }
        Connect-AzureAD -Credential $ksp365admin_cred

        # Exchange Online session to O365
        # TODO(dallas): Basic auth is going bye-bye, rewrite with EXO
        if ($o365_session -ne $null) {
            Write-Host "==== Disconnecting old session to $($o365_session.ComputerName)"
            Remove-PSSession $o365_session
        }
        $script:o365_session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $ksp365admin_cred -Authentication Basic -AllowRedirection
        Import-PSSession -Prefix O365 -Session $o365_session -DisableNameChecking
        Write-Host "...done"
    }

    End {
        $script:cons_initialized = $true
    }
}

function ReInitialize-Cons {
    Begin {
        $script:cons_initialized = $false
    } 

    Process {
        Initialize-Cons
    }
}

function Invalidate-All {
    $script:props_initialized = $false
    $script:creds_initialized = $false
    $script:cons_initialized = $false
}