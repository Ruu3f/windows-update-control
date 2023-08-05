Add-Type -AssemblyName System.Windows.Forms

function CreateButton([string]$text, [int]$x, [int]$y, [int]$width, [int]$height) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text, $button.Width, $button.Height, $button.Location = $text, $width, $height, (New-Object System.Drawing.Point($x, $y))
    $button.Font, $button.ForeColor, $button.FlatStyle, $button.FlatAppearance.BorderSize, $button.FlatAppearance.MouseOverBackColor =
        (New-Object System.Drawing.Font('Bahnschrift', 14)), [System.Drawing.Color]::White, [System.Windows.Forms.FlatStyle]::Flat, 0, [System.Drawing.Color]::Gray
    $button
}

function SetService([string]$serviceName, [string]$startupType) {
    Set-Service -Name $serviceName -StartupType $startupType -ErrorAction SilentlyContinue | Out-Null
    if ($startupType -eq "Disabled") {
        Stop-Service -Name $serviceName -ErrorAction SilentlyContinue | Out-Null
    } else {
        Start-Service -Name $serviceName -ErrorAction SilentlyContinue | Out-Null
    }
}

function Log([string]$message, [string]$type) {
    switch ($type) {
        "Success" { Write-Host $message -ForegroundColor Green }
        "Info"    { Write-Host "$message..." -ForegroundColor Blue }
        default   { Write-Host $message }
    }
}

$disableWindowsUpdate = CreateButton "Disable Windows Update" 50 56 250 60
$disableWindowsUpdate.Add_Click({
    Log "Disabling Windows Update" "Info"
    
    @("wuauserv", "WaaSMedicSvc", "UsoSvc") | ForEach-Object {
        SetService $_ "Disabled"
    }
    Disable-ScheduledTask -TaskName "\Microsoft\Windows\WindowsUpdate\Scheduled Start" | Out-Null
    if (!(Test-Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings")) {
        New-Item -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Type DWord -Value 1
    Stop-Process -Name "MoUsoCoreWorker", "TiWorker" -Force -PassThru -ErrorAction SilentlyContinue | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Services\WaaSMedicSvc" -Name Start -Value 4
    
    Log "Windows Update disabled successfully" "Success"
})

$enableWindowsUpdate = CreateButton "Enable Windows Update" 50 126 250 60
$enableWindowsUpdate.Add_Click({
    Log "Enabling Windows Update" "Info"
    
    @("wuauserv", "WaaSMedicSvc", "UsoSvc") | ForEach-Object {
        SetService $_ "Automatic"
    }
    Enable-ScheduledTask -TaskName "\Microsoft\Windows\WindowsUpdate\Scheduled Start" | Out-Null
    if (!(Test-Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings")) {
        New-Item -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Services\WaaSMedicSvc" -Name Start -Value 2
    
    Log "Windows Update enabled successfully" "Success"
})

$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Update Control"
$form.MinimumSize, $form.MaximizeBox, $form.FormBorderStyle, $form.BackColor, $form.Font, $form.ForeColor =
    (New-Object System.Drawing.Size(360, 250)), $false, [System.Windows.Forms.FormBorderStyle]::FixedDialog,
    [System.Drawing.Color]::DimGray, (New-Object System.Drawing.Font('Bahnschrift', 10)), [System.Drawing.Color]::White
$form.Controls.Add($disableWindowsUpdate)
$form.Controls.Add($enableWindowsUpdate)
$form.Add_Shown({$form.Activate()})
$form.ShowDialog()
