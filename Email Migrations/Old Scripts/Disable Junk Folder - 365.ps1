$UserCredential = Get-Credential -Credential ksp365admin@
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking -Prefix 365
#Any commands in 365 need a "365" prefix. ie: get-365mailboxfolderpermission

#for all users:
#Get-365mailbox | Set-365MailboxJunkEmailConfiguration –Enabled $False

#for one user/shared mailbox:
#Set-365MailboxJunkEmailConfiguration accounting@scsaonline.ca –Enabled $False

#Check Junk folder status once run:
#Get-365MailboxJunkEmailConfiguration rws@kramer.ca

<#When Complete: 
Remove-pssession $session
#>