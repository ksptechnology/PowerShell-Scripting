#=============================#
#==  Variable Declarations  ==#
#==    Don't touch these    ==#
#=============================#
# The *FULL* path to the documentation folder
# Currently located at G:\KSP Technical Documentation
# The UNC path is needed if a scheduled job will run in the background
$doc_dir            = "(Path to documentation folder)"

# The email address string from which emails will be sent
$mail_sender        = "(Mail Name) <(user@domain.com)>"
# The array of email address strings to which emails will be sent
$mail_recipients    = "<(user1@domain.com)>", "<(user2@domain.com)>", "..."
# The subject of the email
$mail_subject       = "(your subject here)"
# The body of the email
# This will be updated dynamically later and should be left as a blank string
$mail_body          = "" # <-- Leave this blank
# The server through which mail will be sent
$mail_server        = "(your server here)"

#===================#
#== Configuration ==#
#==  Touch These  ==#
#===================#
$doc_dir            = "\\kspfs03\scripting$\PowerShell-Scripting"

$mail_sender = "Matt Gordon <mgordon@ksp.ca>"
$mail_recipients = "mgordon@ksp.ca"
$date = [string](Get-Date)
$mail_subject = "PowerShell-Scripting Updates for $date"
$mail_server = "kspemail04.internal.ksphosting.com"

#========================#
#==  Meat 'n Potatoes  ==#
#========================#
# pushd
Push-Location -LiteralPath $doc_dir

# Get repository status
$status = $(git status)

# Check for repo changes and update body as necessary
$changed = Compare-Object $status @("On branch master", "nothing to commit, working tree clean")
if(-not $changed) {
    $mail_body = "No changes to scripts today"
} else {
    foreach($s in $status) {
        $mail_body += "$s`n"
    }
}

# Send report
Send-MailMessage -From $mail_sender -To $mail_recipients -Subject $mail_subject -Body $mail_body -SmtpServer $mail_server

# popd
Pop-Location
