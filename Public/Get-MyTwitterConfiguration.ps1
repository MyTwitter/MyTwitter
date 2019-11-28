Function Get-MyTwitterConfiguration {
    <#
	.SYNOPSIS
		This Function retrieves the Twitter API Application settings from a file 'MyTwitter.json' in the same directory.
	.EXAMPLE
		PS> Get-MyTwitterConfiguration
	
		This example will retrieve all (if any) MyTwitter configuration values
		from a file 'MyTwitter.json' in the same directory.
	#>
	
    [CmdletBinding()]
    param ()
    process {
        $JSONPath = "$PSScriptRoot\MyTwitter.json"
        if (!(Test-Path -Path $JSONPath)) {
            Write-Verbose "No MyTwitter configuration ('MyTwitter.json') found in current directory"
        } else {
            $Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
            $Output = Get-Content $JSONPath | ConvertFrom-Json
            foreach ($Value in $Values) {
                if (!($Output.$Value)) { Write-Verbose "No Value found for $Value" }
            }
            [pscustomobject]$Output
        }
    }
}