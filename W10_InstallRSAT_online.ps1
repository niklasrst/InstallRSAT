<#
    .SYNOPSIS 
    Windows 10 install RSAT feature on demand

    .DESCRIPTION
    Install:   PowerShell.exe -ExecutionPolicy Bypass -Command .\W10_InstallRSAT_online.ps1 -install
    Uninstall:   PowerShell.exe -ExecutionPolicy Bypass -Command .\W10_InstallRSAT_online.ps1 -uninstall

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

$ErrorActionPreference = 'Stop'


if ($install)
{
	try
	{          
        $InstallRSAT = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"}
        if ($InstallRSAT -ne $null) {
            foreach ($Item in $InstallRSAT) {
                $RsatItem = $Item.Name
                Write-Verbose -Verbose "Adding $RsatItem to Windows"
                try {
                    Add-WindowsCapability -Online -Name $RsatItem
                    }
                catch [System.Exception]
                    {
                    Write-Verbose -Verbose "Failed to add $RsatItem to Windows"
                    Write-Warning -Message $_.Exception.Message
                    }
            }
        }
        else {
            Write-Verbose -Verbose "All RSAT features seems to be installed already"
        }
    }
	catch
	{
		$PSCmdlet.WriteError($_)
	}
}

if ($uninstall)
{
	try
	{
          
        $Uninstalled = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "Installed" -AND $_.Name -notlike "Rsat.ServerManager*" -AND $_.Name -notlike "Rsat.GroupPolicy*" -AND $_.Name -notlike "Rsat.ActiveDirectory*"} 
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
	}
	catch
	{
		$PSCmdlet.WriteError($_)
	}
}