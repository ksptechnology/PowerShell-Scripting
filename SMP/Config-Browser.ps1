# TODO list:
#
#  TODO(dallas): Fix bug that if Config-Editor.ps1 Name field changes, new config is created, old config not deleted
#  TODO(dallas): Add Form controls order so tabs don't jump all over the place
#  TODO(dallas): Add the ability to bulk add/remove ListBox field data
#  TODO(dallas): Import/Export Backup/Restore functions
#  TODO(dallas): Add the ability to autodeploy the scheduled task
#  TODO(dallas): Add controls to run/monitor the scheduled task

$DefaultScriptDir = $PSScriptRoot
$DefaultConfigDirName = "configs"
$DefaultConfigDir = $DefaultScriptDir  + "\" + $DefaultConfigDirName
$DefaultSrcDirName = "src"
$DefaultSrcDir = $DefaultScriptDir + "\" + $DefaultSrcDirName
$DefaultConfigFileName = "config.json"
$DefaultConfigFilePath = $DefaultScriptDir + "\" + $DefaultConfigFileName

$ConfigDir = $DefaultConfigDir
$SrcDir = $DefaultSrcDir
try 
{
    $configfile = (gc -Raw $DefaultConfigFilePath -ErrorAction Stop | ConvertFrom-Json) 
    if($configfile.ConfigDir)
    {
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
Write-Host "=== Using SrcDir '$SrcDir'"
If(-Not(Test-Path $ConfigDir)) { Write-Error "[ERROR]: ConfigDir '$ConfigDir' is invalid"; Exit -1 }

function Function-RefreshConfigs {
    $SetsListBox.Items.Clear()
    try {
        gci $ConfigDir -ErrorAction Stop | ? { $_.Name -Like "*.json" } | % { $SetsListBox.Items.Add($_.Name) | Out-Null } 
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Error "[ERROR]: Failed to load configs from '$ConfigDir'. Quitting..."
        Exit -1
    }
}

function Function-AddConfig {
    & "$SrcDir\Config-Editor.ps1" -ConfigDir $ConfigDir
    Function-RefreshConfigs
}

function Function-EditConfig {
    & "$SrcDir\Config-Editor.ps1" -ConfigDir $ConfigDir -Config $SetsListBox.SelectedItem
    Function-RefreshConfigs
}

function Function-RemoveConfig {
    If($SetsListBox.SelectedItem -eq $null) { return }
    $filepath = $ConfigDir + "/" + $SetsListBox.SelectedItem
    Remove-Item -Path $filepath
    $SetsListBox.Items.Remove($SetsListBox.SelectedItem)
    Function-RefreshConfigs
}

. $SrcDir\Dialog-ConfigBrowser.ps1

$SetsListBox.SelectionMode = [System.Windows.Forms.SelectionMode]::One

Function-RefreshConfigs

$BrowserDialog.ShowDialog()
