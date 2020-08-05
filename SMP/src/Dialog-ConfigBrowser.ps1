Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$BrowserDialog                   = New-Object system.Windows.Forms.Form
$BrowserDialog.ClientSize        = New-Object System.Drawing.Point(248,338)
$BrowserDialog.text              = "Config Browser"
$BrowserDialog.TopMost           = $false

$SSLabel                         = New-Object system.Windows.Forms.Label
$SSLabel.text                    = "Configured Service Sets:"
$SSLabel.AutoSize                = $true
$SSLabel.width                   = 25
$SSLabel.height                  = 10
$SSLabel.location                = New-Object System.Drawing.Point(12,12)
$SSLabel.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$AddButton                       = New-Object system.Windows.Forms.Button
$AddButton.text                  = "Add"
$AddButton.width                 = 40
$AddButton.height                = 22
$AddButton.location              = New-Object System.Drawing.Point(10,310)
$AddButton.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$EditButton                      = New-Object system.Windows.Forms.Button
$EditButton.text                 = "Edit"
$EditButton.width                = 40
$EditButton.height               = 22
$EditButton.location             = New-Object System.Drawing.Point(54,310)
$EditButton.Font                 = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RemoveButton                    = New-Object system.Windows.Forms.Button
$RemoveButton.text               = "Remove"
$RemoveButton.width              = 73
$RemoveButton.height             = 22
$RemoveButton.location           = New-Object System.Drawing.Point(98,310)
$RemoveButton.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$RefreshButton                   = New-Object system.Windows.Forms.Button
$RefreshButton.text              = "Refresh"
$RefreshButton.width             = 64
$RefreshButton.height            = 22
$RefreshButton.location          = New-Object System.Drawing.Point(172,310)
$RefreshButton.Font              = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$SetsListBox                     = New-Object system.Windows.Forms.ListBox
$SetsListBox.text                = "listBox"
$SetsListBox.width               = 228
$SetsListBox.height              = 272
$SetsListBox.location            = New-Object System.Drawing.Point(10,32)

$BrowserDialog.controls.AddRange(@($SSLabel,$AddButton,$EditButton,$RemoveButton,$RefreshButton,$SetsListBox))

$RefreshButton.Add_Click({ Function-RefreshConfigs })
$RemoveButton.Add_Click({ Function-RemoveConfig })
$EditButton.Add_Click({ Function-EditConfig })
$AddButton.Add_Click({ Function-AddConfig })

