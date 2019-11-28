Function New-MyTwitterConfiguration {
    <#
	.SYNOPSIS
		This Function stores the Twitter API Application settings in the registry.
	.EXAMPLE
		PS> New-MyTwitterConfiguration -APIKey akey -APISecret asecret -AccessToken sometoken -AccessTokenSecret atokensecret
	
		This example will create 4 registry values (APIKey,APISecret,AccessToken and AccessTokenSecret) in the
		MyTwitter registry key with the observed values.
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
        $RegKey = 'HKCU:\Software\MyTwitter'
    }
    process {
        #API key, the API secret, an Access token and an Access token secret are provided by Twitter application
        Write-Verbose "Checking registry to see if the Twitter application keys are already stored"
        if (!(Test-Path -Path $RegKey)) {
            Write-Verbose "No MyTwitter configuration found in registry. Creating one."
            New-Item -Path ($RegKey | Split-Path -Parent) -Name ($RegKey | Split-Path -Leaf) | Out-Null
        }
		
        $Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
        foreach ($Value in $Values) {
            if ((Get-Item $RegKey).GetValue($Value) -and !$Force.IsPresent) {
                Write-Verbose "'$RegKey\$Value' already exists. Skipping."
            } else {
                Write-Verbose "Creating $RegKey\$Value"
                New-ItemProperty $RegKey -Name $Value -Value ((Get-Variable $Value).Value) -Force | Out-Null
            }
        }
    }
}