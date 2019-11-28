function Set-BitlyAccessToken {
    <#
	.SYNOPSIS
		Set Bitly Generic Access Token
	.DESCRIPTION
		Set Bitly Generic Access Token and store it in your registry
		To set this up: 
		1. You must create an account at Bit.ly, and obtain an Generic Authorization token. 
		2. Verify your Bit.ly account with an eMail that Bitly sends to your account. 
		3. Obtain an authorization token at: https://bitly.com/a/oauth_apps
	.EXAMPLE
		Set-Set-BitlyAuthorizationToken -BitlyAutToken "3d9b120e66badcdfc8f63b752634e9061abf25ce"
	.LINK
		https://bitly.com/a/oauth_apps
	#>
    [CmdletBinding()]
    Param
    (
        # Bitly API Key 
        [Parameter(Mandatory=$true)]
        [string]$BitlyAccessToken,
        [switch]$Force
    )

    begin {
        $RegKey = 'HKCU:\Software\MyTwitter\Bitly'
    }
    process {
        #Bitly Login and API key are provided by Bitly application
        Write-Verbose "Checking registry to see if the Bitly Generic Authorization token is already stored"
        if (!(Test-Path -Path $RegKey)) {
            Write-Verbose "No BitLy configuration found in registry. Creating one."
            New-Item -Path ($RegKey | Split-Path -Parent) -Name ($RegKey | Split-Path -Leaf) | Out-Null
        }
		
        $Values = 'BitlyAccessToken'
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