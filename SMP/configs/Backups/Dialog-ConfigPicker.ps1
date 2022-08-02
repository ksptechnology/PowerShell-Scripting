<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Config Picker
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$PickerDialog                    = New-Object system.Windows.Forms.Form
$PickerDialog.ClientSize         = New-Object System.Drawing.Point(400,400)
$PickerDialog.text               = "Config Browser"
$PickerDialog.TopMost            = $false

$SSLabel                         = New-Object system.Windows.Forms.Label
$SSLabel.text                    = "Configured Service Sets:"
$SSLabel.AutoSize                = $true
$SSLabel.width                   = 25
$SSLabel.height                  = 10
$SSLabel.location                = New-Object System.Drawing.Point(12,12)
$SSLabel.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AddButton                       = New-Object system.Windows.Forms.Button
$AddButton.text                  = "Add"
$AddButton.width                 = 60
$AddButton.height                = 30
$AddButton.location              = New-Object System.Drawing.Point(10,332)
$AddButton.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$EditButton                      = New-Object system.Windows.Forms.Button
$EditButton.text                 = "Edit"
$EditButton.width                = 60
$EditButton.height               = 30
$EditButton.location             = New-Object System.Drawing.Point(94,332)
$EditButton.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RemoveButton                    = New-Object system.Windows.Forms.Button
$RemoveButton.text               = "Remove"
$RemoveButton.width              = 60
$RemoveButton.height             = 30
$RemoveButton.location           = New-Object System.Drawing.Point(176,332)
$RemoveButton.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SetsListBox                     = New-Object system.Windows.Forms.ListBox
$SetsListBox.text                = "listBox"
$SetsListBox.width               = 372
$SetsListBox.height              = 288
$SetsListBox.location            = New-Object System.Drawing.Point(8,30)

$RefreshButton                   = New-Object system.Windows.Forms.Button
$RefreshButton.text              = "Refresh"
$RefreshButton.width             = 60
$RefreshButton.height            = 30
$RefreshButton.location          = New-Object System.Drawing.Point(288,328)
$RefreshButton.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$PickerDialog.controls.AddRange(@($SSLabel,$AddButton,$EditButton,$RemoveButton,$SetsListBox,$RefreshButton))

$AddButton.Add_Click({ Function-AddConfig })
$EditButton.Add_Click({ Function-EditConfig })
$RemoveButton.Add_Click({ Function-RemoveConfig })
$RefreshButton.Add_Click({ Function-RefreshConfigs })

