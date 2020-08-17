param(
    [Parameter(Mandatory = $False)]
    [switch]$Test
)

Function Die([string]$Message)
{
    Write-Error "[ERROR]: $Message"
    Exit(-1)
}

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

Function Parse-Props()
{
    $PropsFileName = "$PSScriptRoot\props.json"
    If(-Not (Test-Path $PropsFileName)) { Die "Failed to locate '$PropsFileName'" }
    $PropsFile = (Get-Content -Raw $PropsFileName | ConvertFrom-Json)
    $ParseErrors = ""

    If(-Not $PropsFile.ProcessNames) { $ParseErrors += "[ERROR]: Invalid 'ProcessNames' property in '$PropsFileName'`n" }
    If(-Not $PropsFile.FileServer)   { $ParseErrors += "[ERROR]: Invalid 'FileServer'   property in '$PropsFileName'`n" }
    If(-Not $PropsFile.FolderPath)   { $ParseErrors += "[ERROR]: Invalid 'FolderPath'   property in '$PropsFileName'`n" }

    $FolderExists = $False
    If($Creds)
    {
        $FolderExists = Invoke-Command -ComputerName $PropsFile.FileServer -Credential $Creds { Test-Path $using:Propsfile.FolderPath }
    }
    else {
        $FolderExists = Invoke-Command -ComputerName $PropsFile.FileServer { Test-Path $using:Propsfile.FolderPath }
    }
    If(-Not $FolderExists) { $ParseErrors += "Folder '$($PropsFile.FolderPath)' does not exist on '$($PropsFile.FileServer)'" }

    If($ParseErrors) { Die $ParseErrors }

    Write-Host "Checking server for '$($PropsFile.ProcessNames)' processes"
    Write-Host "Looking for open files in '$($PropsFile.FolderPath)' on '$($PropsFile.FileServer)'"

    $ret = [PSCustomObject]@{
        ProcessNames = $PropsFile.ProcessNames;
        FileServer   = $PropsFile.FileServer;
        FolderPath   = $PropsFile.FolderPath;
    }

    Return($ret)
}

Function Kill-Processes()
{
    $Processes = @()
    ForEach($ProcessName in $Props.ProcessNames) { $Processes += (Get-Process | ? { $_.ProcessName -eq $ProcessName }) }

    If($Processes)                               { $Processes | Stop-Process -Force -WhatIf:$Test }
    Else                                         { Write-Host "No running processes to kill" }
}

Function Close-OpenFiles()
{
    $Payload = { Get-SmbOpenFile | ? { $_.Path -Like "$($using:Props.FolderPath)\*" } | Close-SmbOpenFile -Confirm:$False -WhatIf:$using:Test }
    If($Creds)
    {
        
        Write-Host "Payload is $Payload"
        Invoke-Command -ComputerName $Props.FileServer -Credential $Creds -ScriptBlock $Payload
    }
    Else {
        Invoke-Command -ComputerName $Props.FileServer -ScriptBlock $Payload
    }
}