Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$EditDialog                      = New-Object system.Windows.Forms.Form
$EditDialog.ClientSize           = New-Object System.Drawing.Point(552,792)
$EditDialog.text                 = "Edit ServiceSet"
$EditDialog.TopMost              = $false

$NameLabel                       = New-Object system.Windows.Forms.Label
$NameLabel.text                  = "Name"
$NameLabel.AutoSize              = $true
$NameLabel.width                 = 25
$NameLabel.height                = 10
$NameLabel.location              = New-Object System.Drawing.Point(14,14)
$NameLabel.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TargetsLabel                    = New-Object system.Windows.Forms.Label
$TargetsLabel.text               = "Targets"
$TargetsLabel.AutoSize           = $true
$TargetsLabel.width              = 25
$TargetsLabel.height             = 10
$TargetsLabel.location           = New-Object System.Drawing.Point(14,36)
$TargetsLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ServiceNamesLabel               = New-Object system.Windows.Forms.Label
$ServiceNamesLabel.text          = "Service Names"
$ServiceNamesLabel.AutoSize      = $true
$ServiceNamesLabel.width         = 25
$ServiceNamesLabel.height        = 10
$ServiceNamesLabel.location      = New-Object System.Drawing.Point(14,214)
$ServiceNamesLabel.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SubjectLabel                    = New-Object system.Windows.Forms.Label
$SubjectLabel.text               = "Subject"
$SubjectLabel.AutoSize           = $true
$SubjectLabel.width              = 25
$SubjectLabel.height             = 10
$SubjectLabel.location           = New-Object System.Drawing.Point(44,400)
$SubjectLabel.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$FromAddressLabel                = New-Object system.Windows.Forms.Label
$FromAddressLabel.text           = "From Address"
$FromAddressLabel.AutoSize       = $true
$FromAddressLabel.width          = 25
$FromAddressLabel.height         = 10
$FromAddressLabel.location       = New-Object System.Drawing.Point(44,426)
$FromAddressLabel.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailListLabel                   = New-Object system.Windows.Forms.Label
$MailListLabel.text              = "Mail List"
$MailListLabel.AutoSize          = $true
$MailListLabel.width             = 25
$MailListLabel.height            = 10
$MailListLabel.location          = New-Object System.Drawing.Point(44,454)
$MailListLabel.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$NameTextBox                     = New-Object system.Windows.Forms.TextBox
$NameTextBox.multiline           = $false
$NameTextBox.width               = 228
$NameTextBox.height              = 20
$NameTextBox.location            = New-Object System.Drawing.Point(136,12)
$NameTextBox.Font                = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SubjectTextBox                  = New-Object system.Windows.Forms.TextBox
$SubjectTextBox.multiline        = $false
$SubjectTextBox.width            = 370
$SubjectTextBox.height           = 20
$SubjectTextBox.location         = New-Object System.Drawing.Point(150,400)
$SubjectTextBox.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$FromAddressTextBox              = New-Object system.Windows.Forms.TextBox
$FromAddressTextBox.multiline    = $false
$FromAddressTextBox.width        = 370
$FromAddressTextBox.height       = 20
$FromAddressTextBox.location     = New-Object System.Drawing.Point(150,426)
$FromAddressTextBox.Font         = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AstLabel1                       = New-Object system.Windows.Forms.Label
$AstLabel1.text                  = "*"
$AstLabel1.AutoSize              = $true
$AstLabel1.width                 = 25
$AstLabel1.height                = 10
$AstLabel1.location              = New-Object System.Drawing.Point(66,14)
$AstLabel1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$AstLabel1.ForeColor             = [System.Drawing.ColorTranslator]::FromHtml("#f60000")

$MailServerLabel                 = New-Object system.Windows.Forms.Label
$MailServerLabel.text            = "Mail Server"
$MailServerLabel.AutoSize        = $true
$MailServerLabel.width           = 5
$MailServerLabel.height          = 5
$MailServerLabel.location        = New-Object System.Drawing.Point(44,626)
$MailServerLabel.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailServerTextBox               = New-Object system.Windows.Forms.TextBox
$MailServerTextBox.multiline     = $false
$MailServerTextBox.width         = 373
$MailServerTextBox.height        = 5
$MailServerTextBox.location      = New-Object System.Drawing.Point(148,622)
$MailServerTextBox.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TranscriptPathLabel             = New-Object system.Windows.Forms.Label
$TranscriptPathLabel.text        = "Transcript Path"
$TranscriptPathLabel.AutoSize    = $true
$TranscriptPathLabel.width       = 25
$TranscriptPathLabel.height      = 10
$TranscriptPathLabel.location    = New-Object System.Drawing.Point(132,678)
$TranscriptPathLabel.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TranscriptFileNameLabel         = New-Object system.Windows.Forms.Label
$TranscriptFileNameLabel.text    = "Transcript File Name"
$TranscriptFileNameLabel.AutoSize  = $true
$TranscriptFileNameLabel.width   = 25
$TranscriptFileNameLabel.height  = 10
$TranscriptFileNameLabel.location  = New-Object System.Drawing.Point(132,704)
$TranscriptFileNameLabel.Font    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AstLabel2                       = New-Object system.Windows.Forms.Label
$AstLabel2.text                  = "*"
$AstLabel2.AutoSize              = $true
$AstLabel2.width                 = 25
$AstLabel2.height                = 10
$AstLabel2.location              = New-Object System.Drawing.Point(68,38)
$AstLabel2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$AstLabel2.ForeColor             = [System.Drawing.ColorTranslator]::FromHtml("#ff0000")

$AstLabel3                       = New-Object system.Windows.Forms.Label
$AstLabel3.text                  = "*"
$AstLabel3.AutoSize              = $true
$AstLabel3.width                 = 25
$AstLabel3.height                = 10
$AstLabel3.location              = New-Object System.Drawing.Point(114,214)
$AstLabel3.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$AstLabel3.ForeColor             = [System.Drawing.ColorTranslator]::FromHtml("#ff0000")

$TranscriptPathTextBox           = New-Object system.Windows.Forms.TextBox
$TranscriptPathTextBox.multiline  = $false
$TranscriptPathTextBox.width     = 170
$TranscriptPathTextBox.height    = 20
$TranscriptPathTextBox.location  = New-Object System.Drawing.Point(286,674)
$TranscriptPathTextBox.Font      = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TranscriptFileNameTextBox       = New-Object system.Windows.Forms.TextBox
$TranscriptFileNameTextBox.multiline  = $false
$TranscriptFileNameTextBox.width  = 170
$TranscriptFileNameTextBox.height  = 20
$TranscriptFileNameTextBox.location  = New-Object System.Drawing.Point(286,700)
$TranscriptFileNameTextBox.Font  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AstLabel4                       = New-Object system.Windows.Forms.Label
$AstLabel4.text                  = "*"
$AstLabel4.AutoSize              = $true
$AstLabel4.width                 = 25
$AstLabel4.height                = 10
$AstLabel4.location              = New-Object System.Drawing.Point(106,454)
$AstLabel4.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$AstLabel4.ForeColor             = [System.Drawing.ColorTranslator]::FromHtml("#ff0000")

$EditSubmitButton                = New-Object system.Windows.Forms.Button
$EditSubmitButton.text           = "Submit"
$EditSubmitButton.width          = 96
$EditSubmitButton.height         = 30
$EditSubmitButton.location       = New-Object System.Drawing.Point(236,748)
$EditSubmitButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TargetsAddButton                = New-Object system.Windows.Forms.Button
$TargetsAddButton.text           = "Add"
$TargetsAddButton.width          = 65
$TargetsAddButton.height         = 20
$TargetsAddButton.location       = New-Object System.Drawing.Point(136,42)
$TargetsAddButton.Font           = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TargetsRemoveButton             = New-Object system.Windows.Forms.Button
$TargetsRemoveButton.text        = "Remove"
$TargetsRemoveButton.width       = 65
$TargetsRemoveButton.height      = 20
$TargetsRemoveButton.location    = New-Object System.Drawing.Point(136,70)
$TargetsRemoveButton.Font        = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$TargetsListBox                  = New-Object system.Windows.Forms.ListBox
$TargetsListBox.text             = "listBox"
$TargetsListBox.width            = 304
$TargetsListBox.height           = 130
$TargetsListBox.location         = New-Object System.Drawing.Point(214,70)

$ServicesAddButton               = New-Object system.Windows.Forms.Button
$ServicesAddButton.text          = "Add"
$ServicesAddButton.width         = 65
$ServicesAddButton.height        = 20
$ServicesAddButton.location      = New-Object System.Drawing.Point(132,214)
$ServicesAddButton.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ServicesRemoveButton            = New-Object system.Windows.Forms.Button
$ServicesRemoveButton.text       = "Remove"
$ServicesRemoveButton.width      = 65
$ServicesRemoveButton.height     = 20
$ServicesRemoveButton.location   = New-Object System.Drawing.Point(132,242)
$ServicesRemoveButton.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ServicesTextBox                 = New-Object system.Windows.Forms.TextBox
$ServicesTextBox.multiline       = $false
$ServicesTextBox.width           = 306
$ServicesTextBox.height          = 20
$ServicesTextBox.location        = New-Object System.Drawing.Point(214,214)
$ServicesTextBox.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ServicesListBox                 = New-Object system.Windows.Forms.ListBox
$ServicesListBox.text            = "listBox"
$ServicesListBox.width           = 306
$ServicesListBox.height          = 130
$ServicesListBox.location        = New-Object System.Drawing.Point(214,242)

$TargetsTextBox                  = New-Object system.Windows.Forms.TextBox
$TargetsTextBox.multiline        = $false
$TargetsTextBox.width            = 302
$TargetsTextBox.height           = 20
$TargetsTextBox.location         = New-Object System.Drawing.Point(216,42)
$TargetsTextBox.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailListAddButton               = New-Object system.Windows.Forms.Button
$MailListAddButton.text          = "Add"
$MailListAddButton.width         = 65
$MailListAddButton.height        = 20
$MailListAddButton.location      = New-Object System.Drawing.Point(132,456)
$MailListAddButton.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailListRemoveButton            = New-Object system.Windows.Forms.Button
$MailListRemoveButton.text       = "Remove"
$MailListRemoveButton.width      = 65
$MailListRemoveButton.height     = 20
$MailListRemoveButton.location   = New-Object System.Drawing.Point(132,484)
$MailListRemoveButton.Font       = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailListTextBox                 = New-Object system.Windows.Forms.TextBox
$MailListTextBox.multiline       = $false
$MailListTextBox.width           = 306
$MailListTextBox.height          = 20
$MailListTextBox.location        = New-Object System.Drawing.Point(214,456)
$MailListTextBox.Font            = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$MailListListBox                 = New-Object system.Windows.Forms.ListBox
$MailListListBox.text            = "listBox"
$MailListListBox.width           = 306
$MailListListBox.height          = 130
$MailListListBox.location        = New-Object System.Drawing.Point(214,484)

$AstLabel5                       = New-Object system.Windows.Forms.Label
$AstLabel5.text                  = "*"
$AstLabel5.AutoSize              = $true
$AstLabel5.width                 = 25
$AstLabel5.height                = 10
$AstLabel5.location              = New-Object System.Drawing.Point(266,704)
$AstLabel5.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$AstLabel5.ForeColor             = [System.Drawing.ColorTranslator]::FromHtml("#ff0000")

$EditDialog.controls.AddRange(@($NameLabel,$TargetsLabel,$ServiceNamesLabel,$SubjectLabel,$FromAddressLabel,$MailListLabel,$NameTextBox,$SubjectTextBox,$FromAddressTextBox,$AstLabel1,$MailServerLabel,$MailServerTextBox,$TranscriptPathLabel,$TranscriptFileNameLabel,$AstLabel2,$AstLabel3,$TranscriptPathTextBox,$TranscriptFileNameTextBox,$AstLabel4,$EditSubmitButton,$TargetsAddButton,$TargetsRemoveButton,$TargetsListBox,$ServicesAddButton,$ServicesRemoveButton,$ServicesTextBox,$ServicesListBox,$TargetsTextBox,$MailListAddButton,$MailListRemoveButton,$MailListTextBox,$MailListListBox,$AstLabel5))

$EditSubmitButton.Add_Click({ Function-EditSubmit })
$ServicesAddButton.Add_Click({ Function-ServicesAdd })
$ServicesRemoveButton.Add_Click({ Function-ServicesRemove })
$TargetsRemoveButton.Add_Click({ Function-TargetsRemove })
$TargetsAddButton.Add_Click({ Function-TargetsAdd })
$MailListAddButton.Add_Click({ Function-MailListAdd })
$MailListRemoveButton.Add_Click({ Function-MailListRemove })

