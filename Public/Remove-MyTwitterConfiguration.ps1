Function Remove-MyTwitterConfiguration {
    <#
	.SYNOPSIS
		This function removes the Twitter API Application settings from the registry.
	.EXAMPLE
		PS> Remove-MyTwitterConfiguration
	
		This example will remove all (if any) MyTwitter configuration values
		from the registry.
	#>
	
    [CmdletBinding()]
    param ()
    process {
        $RegKey = 'HKCU:\Software\MyTwitter'
        if (!(Test-Path -Path $RegKey)) {
            Write-Verbose "No MyTwitter configuration found in registry"
        } else {
            Remove-Item $RegKey -Force
        }
    }
}