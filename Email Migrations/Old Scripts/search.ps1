Start-Transcript -Path .\transcript.txt

$cred = (Get-Credential kspadmin)
#connect AD
$computers = (Get-ADComputer -Filter *)

$computers | % {
    Write-Host "Checking computer $($_.Name)"
    $service = Invoke-Command -ComputerName $_.Name -Credential $cred { Get-Service -Name WSearch }
    $_ | Add-Member -Name Service -Value $_service.Status -MemberType NoteProperty
}

$computers | sort Name | select Name, Service | ConvertTo-Csv | Out-File .\services.csv

Stop-Transcript