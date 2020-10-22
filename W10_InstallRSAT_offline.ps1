<#
    .SYNOPSIS 
    Windows 10 install RSAT feature on demand

    .REQUIREMENTS
    FoD Content extracted to ${PSScriptRoot}\FeaturesOnDemand Folder

    .DESCRIPTION
    Install:   PowerShell.exe -ExecutionPolicy Bypass -Command .\W10_InstallRSAT_offline.ps1 -install
    Uninstall:   PowerShell.exe -ExecutionPolicy Bypass -Command .\W10_InstallRSAT_offline.ps1 -uninstall

    .ENVIRONMENT
    PowerShell 5.0

    .AUTHOR
    Niklas Rast
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, ParameterSetName = 'install')]
	[switch]$install,
	[Parameter(Mandatory = $true, ParameterSetName = 'uninstall')]
	[switch]$uninstall
)

$ErrorActionPreference="SilentlyContinue"
$logFile = ('{0}\{1}.log' -f "C:\Windows\Logs", [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))


if ($install)
{
    Start-Transcript -path $logFile
        try
        {         
            Write-Host "Installing from $PSScriptRoot" -ForegroundColor Yellow
            $RSAT_FoD = Get-WindowsCapability –Online | Where-Object Name -like 'RSAT*'
            if ($RSAT_FoD -ne $null) {
                foreach ($Item in $RSAT_FoD) {
                    Write-Verbose -Verbose "Adding $Item to Windows"
                    try {
                        Add-WindowsCapability -Online -Name $Item.name -Source "${PSScriptRoot}\FeaturesOnDemand" -LimitAccess
                        }
                    catch [System.Exception]
                        {
                        Write-Verbose -Verbose "Failed to add $Item to Windows"
                        Write-Warning -Message $_.Exception.Message
                        }
                }
            }
            else {
                Write-Verbose -Verbose "All RSAT features seems to be installed already"
            }
            
            $null = New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Name "W10_InstallRSAT_offline" -Force
            $null = New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\W10_InstallRSAT_offline" -Name "Version" -PropertyType "String" -Value "1.0" -Force
            $null = New-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\W10_InstallRSAT_offline" -Name "Revision" -PropertyType "String" -Value "001" -Force
        } 
        catch
        {
            $PSCmdlet.WriteError($_)
        }
    Stop-Transcript
}

if ($uninstall)
{
    Start-Transcript -path $logFile
        try
        {
            $Uninstalled = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "Installed" }# -AND $_.Name -notlike "Rsat.ServerManager*" -AND $_.Name -notlike "Rsat.GroupPolicy*" -AND $_.Name -notlike "Rsat.ActiveDirectory*"} 
            if ($Uninstalled -ne $null) 
            {
                foreach ($Item in $Uninstalled) 
                {
                    $RsatItem = $Item.Name
                    Write-Verbose -Verbose "Uninstalling $RsatItem from Windows"
                    try 
                    {
                        Remove-WindowsCapability -Name $RsatItem -Online
                    }
                    catch [System.Exception]
                    {
                        Write-Verbose -Verbose "Failed to uninstall $RsatItem from Windows"
                        Write-Warning -Message $_.Exception.Message
                    }
                }
            }
            
            Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\W10_InstallRSAT_offline" -Force -Recurse
        }
        catch
        {
            $PSCmdlet.WriteError($_)
        }
    Stop-Transcript
}
