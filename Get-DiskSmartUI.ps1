#requires -version 3
function Main () {
	Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase

	Set-StrictMode -Version 'Latest'
	$ErrorActionPreference = 'Stop'

	$Reader = New-Object System.Xml.XmlNodeReader $( Get-WindowXAML )
	$Window = [Windows.Markup.XamlReader]::Load( $Reader )

	$Computer = $Window.FindName( "Computer" )
	$Connect = $Window.FindName( "Connect" )
	$DiskBox = $Window.FindName( "DiskBox" )
	$View = $Window.FindName( "View" )

	# Prevents shadowing of the variable
	# by explicitly defining the scope
	$script:Report = {}
	$script:Creds = $null

	$Connect.Add_Click({
		if ( $Computer.Text -eq '' ) {
			$Computer.Text = '.'
		}
		$DiskBox.Items.Clear()
		# Getting information about disks
		$script:Report = Get-Smart $Computer.Text
		# Filling the drop-down list with disks ids
		foreach ( $Disk in $script:Report.GetEnumerator() ) {
			$DiskBox.Items.Add( $Disk.Name )
		}
		$DiskBox.SelectedIndex = 0;
	})

	$DiskBox.Add_SelectionChanged({
		$View.Items.Clear()
		if ( $DiskBox.SelectedItem ) {
			foreach ( $Attribute in $script:Report[ $DiskBox.SelectedItem ] ) {
				$View.Items.Add( $Attribute )
			}
		}
	})

	$Window.Add_Closed({
		Stop-Process -Id $PID -Force
	})

	$Window.ShowDialog()
}

function Get-WindowXAML () {
	$XAML  = '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"'
	$XAML += '	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'
	$XAML += '	Title="S.M.A.R.T."'
	$XAML += '	Width="450"'
	$XAML += '	Height="500">'
	$XAML += '	<Grid>'
	$XAML += '	<TextBox x:Name="Computer"'
	$XAML += '		Text="."'
	$XAML += '		Width="325"'
	$XAML += '		Height="23"'
	$XAML += '		Margin="10,10,0,0"'
	$XAML += '		HorizontalAlignment="Left"'
	$XAML += '		VerticalAlignment="Top"'
	$XAML += '		TextWrapping="Wrap" />'
	$XAML += '	<Button x:Name="Connect"'
	$XAML += '		Width="75"'
	$XAML += '		Height="23"'
	$XAML += '		Margin="345,10,0,0"'
	$XAML += '		HorizontalAlignment="Left"'
	$XAML += '		VerticalAlignment="Top"'
	$XAML += '		Content="Connect" />'
	$XAML += '	<ComboBox x:Name="DiskBox"'
	$XAML += '		Width="325"'
	$XAML += '		Margin="10,38,0,0"'
	$XAML += '		HorizontalAlignment="Left"'
	$XAML += '		VerticalAlignment="Top" />'
	$XAML += '	<ListView x:Name="View"'
	$XAML += '		Margin="10,65,10,10">'
	$XAML += '		HorizontalAlignment="Left"'
	$XAML += '		VerticalAlignment="Top">'
	$XAML += '		<ListView.View>'
	$XAML += '			<GridView>'
	$XAML += '				<GridViewColumn'
	$XAML += '					Width="250"'
	$XAML += '					DisplayMemberBinding="{Binding Name}"'
	$XAML += '					Header="Attribute" />'
	$XAML += '				<GridViewColumn'
	$XAML += '					Width="130"'
	$XAML += '					DisplayMemberBinding="{Binding Value}"'
	$XAML += '					Header="Value" />'
	$XAML += '			</GridView>'
	$XAML += '		</ListView.View>'
	$XAML += '	</ListView>'
	$XAML += '	</Grid>'
	$XAML += '</Window>'

	return [xml]$XAML
}

function Get-Smart ( $Computer ) {
	function ConvertTo-Hex ( $DEC ) {
		'{0:x2}' -f [int]$DEC
	}
	function ConvertTo-Dec ( $HEX ) {
		[Convert]::ToInt32( $HEX, 16 )
	}
	function Get-AttributeDescription ( $Value ) {
		switch ($Value) {
			'01' { 'Raw Read Error Rate' }
			'02' { 'Throughput Performance' }
			'03' { 'Spin-Up Time' }
			'04' { 'Number of Spin-Up Times (Start/Stop Count)' }
			'05' { 'Reallocated Sector Count' }
			'07' { 'Seek Error Rate' }
			'08' { 'Seek Time Performance' }
			'09' { 'Power On Hours Count (Power-on Time)' }
			'0b' { 'Calibration Retry Count (Recalibration Retries)' }
			'0c' { 'Power Cycle Count' }
			'0а' { 'Spin Retry Count' }
			'aa' { 'Available Reserved Space' }
			'ab' { 'Program Fail Count' }
			'ac' { 'Erase Fail Count' }
			'ae' { 'Unexpected power loss count' }
			'b7' { 'SATA Downshift Error Count' }
			'b8' { 'End-to-End Error' }
			'bb' { 'Reported Uncorrected Sector Count (UNC Error)' }
			'bc' { 'Command Timeout' }
			'bd' { 'High Fly Writes' }
			'be' { 'Airflow Temperature' }
			'bf' { 'G-Sensor Shock Count (Mechanical Shock)' }
			'cb' { 'Run Out Cancel' }
			'dc' { 'Disk Shift' }
			'e1' { 'Load/Unload Cycle Count' }
			'e2' { 'Load ''In''-time' }
			'e3' { 'Torque Amplification Count' }
			'e4' { 'Power-Off Retract Cycle' }
			'e8' { 'Available Reserved Space' }
			'e9' { 'Media Wearout Indicator' }
			'f0' { 'Head Flying Hours' }
			'f0' { 'Head Flying Hours' }
			'f1' { 'Total LBAs Written' }
			'f2' { 'Total LBAs Read' }
			'f9' { 'NAND Writes (1GiB)' }
			'fe' { 'Free Fall Protection' }
			'с0' { 'Power Off Retract Count (Emergency Retry Count)' }
			'с1' { 'Load/Unload Cycle Count' }
			'с2' { 'Temperature' }
			'с3' { 'Hardware ECC Recovered' }
			'с4' { 'Reallocated Event Count' }
			'с5' { 'Current Pending Sector Count' }
			'с6' { 'Offline Uncorrectable Sector Count (Uncorrectable Sector Count)' }
			'с7' { 'UltraDMA CRC Error Count' }
			'с8' { 'Write Error Rate (MultiZone Error Rate)' }
			'с9' { 'Soft Read Error Rate' }
			'са' { 'Data Address Mark Error' }
			default { $Value }
		}
	}

	$Disks = @()
	$Result = @{}
	while ( $Disks.Count -eq 0 ) {
		if ( $Computer -eq '.' ) { $CredsCache = $null } else { $CredsCache = $script:Creds }
		try {
			foreach ( $item in Get-WmiObject -Class MSStorageDriver_FailurePredictData -Namespace root\WMI -ComputerName $Computer -Credential $CredsCache ) { $Disks += $item }
		} catch [System.UnauthorizedAccessException] {
			$script:Creds = Get-Credential
		}
	}

	foreach ( $Disk in $Disks ) {
		$i = 0
		$Report = @()
		$Report += [PSCustomObject]@{ Name = 'Diks ID'; Value = $Disk.InstanceName }
		$Report += [PSCustomObject]@{ Name = 'Active'; Value = $Disk.Active }
		$PredictFailure = Get-WmiObject –class MSStorageDriver_FailurePredictStatus -Namespace root\WMI -ComputerName $Computer -Credential $CredsCache |
				Where-Object InstanceName -eq $Disk.InstanceName | Select-Object -ExpandProperty PredictFailure
		$Report += [PSCustomObject]@{ Name = 'PredictFailure'; Value = $PredictFailure }

		$pByte = $null
		foreach ( $Byte in $Disk.VendorSpecific ) {
			$i++
			if (( $i - 3 ) % 12 -eq 0 ) {
				if ( $Byte -eq 0) { break }
				$Attribute = ConvertTo-Hex $Byte
			} else {
				$post = ConvertTo-Hex $pByte
				$pref = ConvertTo-Hex $Byte
				$Value = ConvertTo-Dec "$pref$post"
				if (( $i - 3 ) % 12 -eq 6 ) {
					if ( $Attribute -eq '09' ) { [int]$Value = $Value / 24 }
					$Report += [PSCustomObject]@{ Name = $( Get-AttributeDescription $Attribute ); Value = $Value }
				}
			}
			$pByte = $Byte
		}
		$Result[ $Disk.InstanceName ] = $Report
	}
	return $Result
}

# Increasing privileges
$WindowsIdentity   = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$WindowsPrincipal  = New-Object System.Security.Principal.WindowsPrincipal( $WindowsIdentity )
$AdministratorRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if ( -not ( $WindowsPrincipal.IsInRole( $AdministratorRole ))) {
	$PowerShellProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
	$PowerShellProcess.Arguments = $myInvocation.MyCommand.Definition
	$PowerShellProcess.Verb = "runas"

	[System.Diagnostics.Process]::Start( $PowerShellProcess )
	Exit
}

# Hides the console window
$Signature = '[DllImport("user32.dll")] public static extern bool ShowWindow(int handle, int state);'
Add-Type -Name Win -Member $Signature -Namespace Native
[Native.Win]::ShowWindow( [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle, 0 )

. Main