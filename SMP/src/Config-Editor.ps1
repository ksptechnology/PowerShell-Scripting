Param(
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string]$ConfigDir,
    [string]$Config
)

function Function-TargetsAdd {
    if($TargetsTextBox.Text -eq "") { return }
    elseif($TargetsTextBox.Text -Match " ") { [System.Windows.Forms.MessageBox]::Show("Target name cannot contain spaces"); return }
    foreach($target in $TargetsListBox.Items)
    {
        if($TargetsTextBox.Text -eq $target) { 
            $TargetsTextBox.Text = ""
            return
        }
    }
    $TargetsListBox.Items.Add($TargetsTextBox.Text)
    $TargetsTextBox.Text = ""
}

function Function-TargetsRemove {
    if($TargetsListBox.SelectedItem -eq $null) { return }
    $TargetsListBox.Items.Remove($TargetsListBox.SelectedItem)
}

function Function-ServicesAdd {
    if($ServicesTextBox.Text -eq "") { return }
    foreach($service in $ServicesListBox.Items)
    {
        if($ServicesTextBox.Text -eq $service) { 
            $ServicesTextBox.Text = ""
            return
        }
    }
    $ServicesListBox.Items.Add($ServicesTextBox.Text)
    $ServicesTextBox.Text = ""
}

function Function-ServicesRemove {
    if($ServicesListBox.SelectedItem -eq $null) { return }
    $ServicesListBox.Items.Remove($ServicesListBox.SelectedItem)
}

function Function-MailListAdd {
    if($MailListTextBox.Text -eq "") { return }
    elseif(($MailListTextBox.Text -Match " ") -or
           (-Not ($MailListTextBox.Text -Match "@"))) { [System.Windows.Forms.MessageBox]::Show("Invalid email address"); return }
    foreach($recipient in $MailListListBox.Items)
    {
        if($MailListTextBox.Text -eq $recipient) { 
            $MailListTextBox.Text = ""
            return
        }
    }
    $MailListListBox.Items.Add($MailListTextBox.Text)
    $MailListTextBox.Text = ""
}

function Function-MailListRemove {
    if($MailListListBox.SelectedItem -eq $null) { return }
    $MailListListBox.Items.Remove($MailListListBox.SelectedItem)
}

function Function-EditSubmit {
    # TODO(dallas): If editing an existing set and you change the Name field
    #               (the field that determines the filename), then
    #               the original config remains unchanged, and a new
    #               config is saved. Add logic to remove the old config

    $error_message = ""
    if( ($NameTextBox.Text -eq "") -or
        ($NameTextBox.Text -Match " ")) {
        $error_message += "Invalid 'Name': Cannot contain spaces or be empty`n"
    }

    if($TargetsListBox.Items.Count -eq 0)
    {
        $error_message += "Invalid 'Targets': List cannot be empty`n"
    }

    if($ServicesListBox.Items.Count -eq 0)
    {
        $error_message += "Invalid 'Services': List cannot be empty`n"
    }

    if($MailListListBox.Items.Count -eq 0)
    {
        $error_message += "Invalid 'Mail List': List cannot be empty`n"
    }

    If($SubjectTextBox.Text -eq "") { $error_message += "Invalid 'Subject': Cannot be empty`n"}
    If($FromAddressTextBox.Text -eq "") { $error_message += "Invalid 'From Address': Cannot be empty`n"}

    If($MailServerTextBox.Text -eq "") { $error_message += "Invalid 'Mail Server': Cannot be empty`n"}
    If($TranscriptPathTextBox.Text -eq "") { $error_message += "Invalid 'Transcript Path': Cannot be empty`n"}
    If($TranscriptFileNameTextBox.Text -eq "") { $error_message += "Invalid 'Transcript File Name': Cannot be empty`n"}

    If($error_message)
    {
        [System.Windows.Forms.MessageBox]::Show($error_message)
    }
    else 
    {
        $config = [PSCustomObject]@{
            Name=$NameTextBox.Text;
            Targets=$TargetsListBox.Items;
            ServiceNames=$ServicesListBox.Items;
            Subject=$SubjectTextBox.Text;
            FromAddress=$FromAddressTextBox.Text;
            MailList=$MailListListBox.Items;
            MailServer=$MailServerTextBox.Text;
            TranscriptPath=$TranscriptPathTextBox.Text;
            TranscriptFileName=$TranscriptFileNameTextBox.Text;
        }

        # TODO(dallas): more advanced filepath checking
        If($config.TranscriptPath[$config.TranscriptPath.Length-1] -eq "\") { $config.TranscriptPath = $config.TranscriptPath.SubString(0, ($config.TranscriptPath.Length-1))}

        $filepath = "" + $ConfigDir + "\" + $config.Name + ".json"
        Write-Host "Writing config '$filepath'..."
        $config | ConvertTo-Json > $filepath
        $EditDialog.Close()
    }
}

. $SrcDir\Dialog-ConfigEditor.ps1

If($Config -ne "")
{
    $filepath =  "" + $ConfigDir + "\" + $Config
    Write-Host "Loading config '$filepath'"
    $configfile = (gc -Raw $filepath | ConvertFrom-Json)
    $NameTextBox.Text = $configfile.Name;
    foreach($target in $configfile.Targets)
    {
        $TargetsListBox.Items.Add($target)
    }
    foreach($service in $configfile.ServiceNames)
    {
        $ServicesListBox.Items.Add($service)
    }
    $SubjectTextBox.Text = $configfile.Subject;
    $FromAddressTextBox.Text = $configfile.FromAddress;
    foreach($recipient in $configfile.MailList)
    {
        $MailListListBox.Items.Add($recipient)
    }
    $MailServerTextBox.Text = $configfile.MailServer;
    $TranscriptPathTextBox.Text = $configfile.TranscriptPath;
    $TranscriptFileNameTextBox.Text = $configfile.TranscriptFileName;
}
Else
{
    If ($SubjectTextBox.Text -eq "") { $SubjectTextBox.Text = "Service Error" }
    If ($FromAddressTextBox.Text -eq "") { $FromAddressTextBox.Text = "ServiceChecker@ksp.ca" }
    If ($MailServerTextBox.Text -eq "") { $MailServerTextBox.Text = "kspemail04.internal.ksphosting.com" }
    If ($TranscriptPathTextBox.Text -eq "") { $TranscriptPathTextBox.Text = "C:\temp" }
    If ($TranscriptFileNameTextBox.Text -eq "") { $TranscriptFileNameTextBox.Text = "" }
}

$EditDialog.ShowDialog()