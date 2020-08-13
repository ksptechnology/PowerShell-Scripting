param(
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    $UserName
)

Function Check-Creds()
{
    If($UserName)
    {
        If (-Not $global:Temp_Creds) {
            $global:Temp_Creds = (Get-Credential $UserName)
        }
        Return($global:Temp_Creds)
    }
    Else {
        Return($null)
    }
}

Function Clear-Creds()
{
    $global:Temp_Creds = $null
    $global:Creds      = $null
}

$Creds = Check-Creds