#########################################################
##                                                     ##
##  Customize these                                    ##
##                                                     ##
#########################################################

$maillist = @("fake@email.com")
$fromaddress = "email@fake.com"
$mailserver = "smtp.emailfake.com"
$subject = "Service error"
# todo(dallas): think of a better way to handle configuring the email body
$message = "<message here>" # don't change this

$transcriptpath = "C:\"
$transcriptfilename = "transcript.txt"
$transcript = $transcriptpath + $transcriptfilename
$temptranscriptname = "temp.txt"
$temptranscript = $transcriptpath + $temptranscriptname

$servicename = "MyAwesomeService"
$was_running = $null
$old_status = $null
$is_running = $null
$new_status = $null

#########################################################
##                                                     ##
##  Don't touch these                                  ##
##                                                     ##
#########################################################

Start-Transcript -path $temptranscript

$service = (Get-Service $servicename)
$was_running = If($service.Status -eq "Running") { $true } else { $false }
$old_status = $service.Status
Write-Host "Service '$servicename' was running: $was_running ($old_status)`r"

If(-Not $was_running) {
	$service | Stop-Service
	$service | Start-Service
	$service = (Get-Service $servicename)

	If($service.Status -eq "Running") {
		$is_running = "yes"
	}
	Else
	{
		$is_running = "no"
	}
	$new_status = $service.Status
	
	Write-Host "Service '$servicename' is running: $is_running ($new_status)`r"
}

Stop-Transcript

# Has to come after Stop-Transcript, otherwise mail won't send because log file is locked
if(-Not $was_running) {

#########################################################
##                                                     ##
##  This is the line that configures the email         ##
##  message. Modify this line only                     ##
##                                                     ##
#########################################################
	$message = "Service '$servicename' was not running ($old_status)`nRestarted successfully: $is_running ($new_status)"

#########################################################
##                                                     ##
##  Don't touch these                                  ##
##                                                     ##
#########################################################
	Send-MailMessage -To $maillist -From $fromaddress -SmtpServer $mailserver -Subject $subject -Body $message -Attachment $temptranscript
}

cat $temptranscript >> $transcript
