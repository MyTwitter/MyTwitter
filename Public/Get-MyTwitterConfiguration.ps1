Function Get-MyTwitterConfiguration {
    <#
	.SYNOPSIS
		This Function retrieves the Twitter API Application settings from the registry.
	.EXAMPLE
		PS> Get-Configuration
	
		This example will retrieve all (if any) MyTwitter configuration values
		from the registry.
	#>
	
    [CmdletBinding()]
    param ()
    process {
        $RegKey = 'HKCU:\Software\MyTwitter'
        if (!(Test-Path -Path $RegKey)) {
            Write-Verbose "No MyTwitter configuration found in registry"
        } else {
            $Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
            $Output = @{ }
            foreach ($Value in $Values) {
                if ((Get-Item $RegKey).GetValue($Value)) {
                    $Output.$Value = (Get-Item $RegKey).GetValue($Value)
                } else {
                    $Output.$Value = ''
                }
            }
            [pscustomobject]$Output
        }
    }
}