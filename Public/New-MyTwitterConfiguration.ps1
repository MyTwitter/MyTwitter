Function New-MyTwitterConfiguration {
    <#
	.SYNOPSIS
		This Function stores the Twitter API Application settings in a file 'MyTwitter.json' in the same directory.
	.EXAMPLE
		PS> New-MyTwitterConfiguration -APIKey akey -APISecret asecret -AccessToken sometoken -AccessTokenSecret atokensecret
	
		This example will store the 4 Values (APIKey,APISecret,AccessToken and AccessTokenSecret) in the
		MyTwitter file.
	.PARAMETER Force
		Overwrites the existing Values in the 'MyTwitter.json' file.
	#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            HelpMessage='What is the Twitter Client API Key?')]
        [string]$APIKey,
        [Parameter(Mandatory,
            HelpMessage='What is the Twitter Client API Secret?')]
        [string]$APISecret,
        [Parameter(Mandatory,
            HelpMessage='What is the Twitter Client Access Token?')]
        [string]$AccessToken,
        [Parameter(Mandatory,
            HelpMessage='What is the Twitter Client Access Token Secret?')]
        [string]$AccessTokenSecret,
        [switch]$Force
    )
    begin {
        $JSONPath = "$PSScriptRoot/MyTwitter.json"
    }
    process {
        #API key, the API secret, an Access token and an Access token secret are provided by Twitter application
        $Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
        Write-Verbose "Checking to see if the Twitter application keys are already stored in this directory"
        if (!(Test-Path -Path $JSONPath)) {
            Write-Verbose "No MyTwitter configuration file found. Creating one."
            $JSONData = @{ }
            foreach ($Value in $Values) {
                $JSONData.Add($Value, ((Get-Variable $Value).Value))
            }
            $null = New-Item -Path $JSONPath -ItemType 'File'
        } else {
            $JSONData = Get-Content $JSONPath | ConvertFrom-Json
            foreach ($Value in $Values) {
                if (($JSONData.$Value) -and !$Force.IsPresent) {
                    Write-Verbose "'$Value' already exists. Skipping."
                } else {
                    Write-Verbose "Creating $Value"
                    $JSONData.$Value = ((Get-Variable $Value).Value)
                }
            }
        }
        $JSONData | ConvertTo-Json | Out-File $JSONPath
    }
}