# NOTE(dallas): This script must be run as an admin account able to connect
#				to the target(s) and start services on it

# TODO list:
#
#  TODO(dallas): Catch asynchronous connection errors from Invoke-Command somehow
#  TODO(dallas): Email reporting for failed service queries

param(
	[Parameter(Mandatory = $false)]
	[string]$Username,

	[Parameter(Mandatory = $false)]
	[switch]$Test
)

$main_transcript = "C:\temp\service_monitor_plus.txt"
Start-Transcript -path $main_transcript

$DefaultScriptDir = $PSScriptRoot
$DefaultConfigDirName = "configs"
$DefaultConfigDir = $DefaultScriptDir + "\" + $DefaultConfigDirName
$DefaultConfigFileName = "\config.json"
$DefaultConfigFilePath = $DefaultScriptDir + "\" + $DefaultConfigFileName
$ConfigDir = $DefaultConfigDir
try 
{
    $configfile = (gc -Raw $DefaultConfigFilePath -ErrorAction Stop | ConvertFrom-Json) 
    if($configfile.ConfigDir) { 
		# NOTE(dallas): this is dirty and ridiculous, but I don't have time to do anything else right now
		if($configfile.ConfigDir -eq "configs")
		{
			# Config location is the default $DefaultConfigDir
		}
		else
		{
			# NOTE(dallas): $configfile.ConfigDir MUST be an absolute filepath by this logic
			$ConfigDir = $configfile.ConfigDir
		}
	}
}
catch [System.Management.Automation.ItemNotFoundException] 
{
	Write-Host "[WARNING]: Default config file '$DefaultConfigFilePath' not found. Using default config folder '$DefaultConfigDir'"
}
Write-Host "=== Using ConfigDir '$ConfigDir'"
If(-Not(Test-Path $ConfigDir)) { Write-Error "[ERROR]: ConfigDir '$ConfigDir' is invalid"; Exit -1 }

$props = [System.Collections.ArrayList]@()
$items = (gci -File $ConfigDir | ? { $_.FullName -like "*.json" } | select -ExpandProperty FullName)
$errors = $false
If($items.Count -eq 0) {
	Write-Error "[WARNING]: No service sets found at '$ConfigDir'. Exiting..."
	$errors = $true
}
ForEach($i in $items) {
	$p = (Get-Content -Raw $i -ErrorAction Stop | ConvertFrom-Json)

	if(-Not $p) { Write-Error "Failed to load service set from '$i'" }

	If(-Not $p.name) 				{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'name' attribute!";					$errors = $true }
	If(-Not $p.targets) 			{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'target' attribute!";				$errors = $true }
	If(-Not $p.servicenames)		{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'servicesnames' attribute!";		$errors = $true }
	If(-Not $p.subject)				{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'subject' attribute!";				$errors = $true }
	If(-Not $p.fromaddress)			{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'fromaddress' attribute!";			$errors = $true }
	If(-Not $p.maillist)			{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'maillist' attribute!";				$errors = $true }
	If(-Not $p.mailserver)			{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'mailserver' attribute!";			$errors = $true }
	If(-Not $p.transcriptpath)		{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'transcriptpath' attribute!"; 		$errors = $true }
	If(-Not $p.transcriptfilename)	{ Write-Error "[ERROR] (ServiceSet::$($p.name)): Properties missing 'transcriptfilename' attribute!";	$errors = $true }

	$props.Add($p) | Out-Null
}
If($errors) { Exit -1 }

If($Username)
{
	if(-Not $_creds)
	{
		$_creds = (Get-Credential $username)
	}
	$creds = $_creds
}
Else {
	$creds = $null	
}

ForEach($set in $props)
{
	$message = ""
	$report = $false

	$transcript = "$($set.transcriptpath)\$($set.transcriptfilename)"
	Write-Host "Starting transcript at $transcript"
	Start-Transcript -path $transcript

	Write-Host "=== Processing ServiceSet::$($set.name)"

	Write-Host "=== Querying all services..."
	$remote_services = $null
	$timer = Measure-Command {
		try
		{
			If($creds)
			{
				# NOTE(dallas): Invoke-Command is apparently 4 times faster than Get-Service -ComputerName...
				#				w/ Get-Service, 14 servers take ~45 seconds to query, both with & w/o filtering,
				#				so filtering is probably done on the local end
				#				Invoke-Command takes ~11-15 seconds both with and & w/o filters.
				#				It seems way more volatile, but is consistently faster. 
				#
				#				Luckily, though the object's format is a bit different, both commands
				#				return arrays of services, so the code doesn't need to change much
				#				regardless of which approach you take
				# TODO(dallas): How do you catch connection errors from Invoke-Command? they aren't and **can't** be terminating...
				#				Seems like -AsJob might provide some answers
				$remote_services = Invoke-Command -ComputerName $set.targets -Credential $creds { (Get-Service -Name $using:set.servicenames) }
			} Else {
				$remote_services = Invoke-Command -ComputerName $set.targets { (Get-Service -Name $using:set.servicenames) }
			}
		} catch {
			Write-Error "Error connecting to servers!"
			$report = $true
			$message += "ERROR: couldn't connect to servers!`n"
			$message += "`n"
			$message += "$_`n"
		}
	}
	If($test)
	{
		Write-Host "[DEBUG]: Took $($timer.TotalSeconds) seconds to query services"
		$message += "[DEBUG]: Took $($timer.TotalSeconds) seconds to query services`n"
	}

	If(-Not $remote_services) {
		Write-Error "[ERROR]: Failed to query services!"
		$message += "[ERROR]: Failed to query services!`n"
		# TODO(dallas): Jump to email report instead
		Exit -1
	}

	Write-Host "=== Checking all services..."
	$stopped_services = [System.Collections.ArrayList]@()
	ForEach($service in $remote_services)
	{
		If ($service.Status -ne "Running")
		{
			$stopped_services.Add($service) | Out-Null
			Write-Host "[WARNING]: '$($service.Name)' not running on $($service.PSComputerName) ($($service.Status))"
			$message += "[WARNING]: '$($service.Name)' was not running on $($service.PSComputerName) ($($service.Status))`n"
			$report = $true
		}
		Else
		{
			If($test)
			{
				Write-Host "[DEBUG]: '$($service.Name)' is running on $($service.PSComputerName)"
				$message += "[DEBUG]: '$($service.Name)' is running on $($service.PSComputerName)`n"
			}
		}
	}

	If($stopped_services)
	{
		Write-Host "=== $($stopped_services.Count) services not running!"

		$service_map = @{}
		ForEach($service in $stopped_services)
		{
			# NOTE(dallas): Don't have to do all the usual '$found = $false...' iteration crap
			#				As the hashtable '+=' operator seems to take care of this for you
			#
			# $found = $true
			# $service_map.Keys | % {
			#	 If($service.Name -eq $_) { $found = $true; break }
			# }
			# foreach($test in $service_map)
			# {
			#	 If($service.Name -eq $test) { $found = $true; break;}
			# }
			# If(-Not $found)
			# {
			#	 $service_map.Add($service.Name, [System.Collections.ArrayList]@())
			# }
			$service_map[$service.Name] += [System.Collections.ArrayList]@($service.PSComputerName)
		}

		ForEach($key in $service_map.Keys)
		{
			Write-Host "=== Attempting to restart '$key' on $($service_map[$key])"

			# Stupid hack to avoid passing a [System.Collections.ArrayList] to Invoke-Command
			# TODO(dallas): figure out a ~~better~~ good/reasonable/not stupid way to do this
			$services = ""
			$service_map[$key] | % { $services += "$_," }
			$services = $services.Substring(0, $services.Length-1)

			$updated_services = $null

			If($creds)
			{
				$updated_services = Invoke-Command -ComputerName $service_map[$key] -Credential $creds {
					Start-Service -Name $using:key
					Get-Service -Name $using:key
				}
			} Else {
				$updated_services = Invoke-Command -ComputerName $service_map[$key] {
					Start-Service -Name $using:key
					Get-Service -Name $using:key
				}
			}

			ForEach($service in $updated_services)
			{
				If($service.Status -eq "Running")
				{
					Write-Host "Restarted successfully on $($service.PSComputerName)"
				} Else {
					Write-Host "[ERROR]: Failed to restart '$($service.Name)' on $($service.PSComputerName) ($($service.Status))"
					$message += "[ERROR]: Failed to restart '$($service.Name)' on $($service.PSComputerName) ($($service.Status))`n"
					$report = $true
				}
			}
		}
	} Else {
		Write-Host "=== All services were running properly"
	}

	Write-Host "=== Finished processing ServiceSet::$($set.name)"

	Stop-Transcript # <transcriptpath>/<setname>.json

	If(-Not $message) { $message = "DEBUG: All services fine`n" }
	If ($report -or $Test) {
		# NOTE(dallas): Holy christ, thank you mysterious Internet genius
		#				Email will not send as an Admin unless special relaying settings are configured in Exchange without this
		#				https://community.idera.com/database-tools/powershell/ask_the_experts/f/learn_powershell_from_don_jones-24/11843/send-mailmessage-without-authentication
		$fake_pass = ConvertTo-SecureString "This is not a real password" -AsPlainText -Force
		$fake_creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "NT AUTHORITY\ANONYMOUS LOGON", $fake_pass
		Send-MailMessage -Credential $fake_creds -To $set.maillist -From $set.fromaddress -SmtpServer $set.mailserver -Subject $set.subject -Body $message -Attachment $transcript
	}
}

Stop-Transcript # C:\temp\service_monitor_plus.ps1
