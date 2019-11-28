function Get-OAuthAuthorization {
    <#
	.SYNOPSIS
		This function is used to create the signature and authorization headers needed to pass to OAuth
		It has been tested with v1.1 of the API.
	.EXAMPLE
		Get-OAuthAuthorization -ApiParameters @{'status' = 'hello' } -HttpVerb GET -HttpEndPoint 'https://api.twitter.com/1.1/statuses/update.json'
	
		This example gets the authorization string needed in the HTTP GET method to send send a tweet 'hello'
	.PARAMETER Api
		The Twitter API name.  Currently, you can only use Timeline, DirectMessage or Update.
	.PARAMETER HttpEndPoint
		This is the URI that you must use to issue calls to the API.
	.PARAMETER HttpVerb
		The HTTP verb (either GET or POST) that the specific API uses.
	.PARAMETER ApiParameters
		A hashtable of parameters the specific Twitter API you're building the authorization
		string for needs to include in the signature
		
	#>
    [CmdletBinding(DefaultParameterSetName = 'None')]
    [OutputType('System.Management.Automation.PSCustomObject')]
    param (
        [Parameter(Mandatory)]
        [string]$HttpEndPoint,
        [Parameter(Mandatory)]
        [ValidateSet('POST', 'GET')]
        [string]$HttpVerb,
        [Parameter(Mandatory)]
        [hashtable]$ApiParameters
    )
	
    begin {
        $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
        Set-StrictMode -Version Latest
        try {
            [Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
            [Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null
			
            if (!(Get-MyTwitterConfiguration)) {
                throw 'No MyTwitter configuration detected.  Please run New-MyTwitterConfiguration'
            } else {
                $script:MyTwitterConfiguration = Get-MyTwitterConfiguration
            }
        } catch {
            Write-Error $_.Exception.Message
        }
    }
	
    process {
        try {
            ## Generate a random 32-byte string. I'm using the current time (in seconds) and appending 5 chars to the end to get to 32 bytes
            ## Base64 allows for an '=' but Twitter does not.  If this is found, replace it with some alphanumeric character
            $OauthNonce = [System.Convert]::ToBase64String(([System.Text.Encoding]::ASCII.GetBytes("$([System.DateTime]::Now.Ticks.ToString())12345"))).Replace('=', 'g')
            Write-Verbose "Generated Oauth none string '$OauthNonce'"
			
            ## Find the total seconds since 1/1/1970 (epoch time)
            $EpochTimeNow = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
            Write-Verbose "Generated epoch time '$EpochTimeNow'"
            $OauthTimestamp = [System.Convert]::ToInt64($EpochTimeNow.TotalSeconds).ToString();
            Write-Verbose "Generated Oauth timestamp '$OauthTimestamp'"
			
            ## Build the signature
            $SignatureBase = "$([System.Uri]::EscapeDataString($HttpEndPoint))&"
            $SignatureParams = @{
                'oauth_consumer_key'     = $MyTwitterConfiguration.ApiKey;
                'oauth_nonce'            = $OauthNonce;
                'oauth_signature_method' = 'HMAC-SHA1';
                'oauth_timestamp'        = $OauthTimestamp;
                'oauth_token'            = $MyTwitterConfiguration.AccessToken;
                'oauth_version'          = '1.0';
            }
			
            $AuthorizationParams = $SignatureParams.Clone()
			
            ## Add API-specific params to the signature
            foreach ($Param in $ApiParameters.GetEnumerator()) {
                $SignatureParams[$Param.Key] = $Param.Value
            }
			
            ## Create a string called $SignatureBase that joins all URL encoded 'Key=Value' elements with a &
            ## Remove the URL encoded & at the end and prepend the necessary 'POST&' verb to the front
            $SignatureParams.GetEnumerator() | Sort-Object -Property Name | foreach { $SignatureBase += [System.Uri]::EscapeDataString("$($_.Key)=$($_.Value)&") }
            $SignatureBase = $SignatureBase.TrimEnd('%26')
            $SignatureBase = "$HttpVerb&" + $SignatureBase
            Write-Verbose "Base signature generated '$SignatureBase'"
			
            ## Create the hashed string from the base signature
            $SignatureKey = [System.Uri]::EscapeDataString($MyTwitterConfiguration.ApiSecret) + "&" + [System.Uri]::EscapeDataString($MyTwitterConfiguration.AccessTokenSecret);
			
            $hmacsha1 = new-object System.Security.Cryptography.HMACSHA1;
            $hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($SignatureKey);
            $OauthSignature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($SignatureBase)));
            Write-Verbose "Using signature '$OauthSignature'"
			
            ## Build the authorization headers.  This is joining all of the 'Key=Value' elements again
            ## and only URL encoding the Values this time while including non-URL encoded double quotes around each value
            $AuthorizationParams.Add('oauth_signature', $OauthSignature)	
            $AuthorizationString = 'OAuth '
            $AuthorizationParams.GetEnumerator() | Sort-Object -Property name | foreach { $AuthorizationString += $_.Key + '="' + [System.Uri]::EscapeDataString($_.Value) + '", ' }
            $AuthorizationString = $AuthorizationString.TrimEnd(', ')
            Write-Verbose "Using authorization string '$AuthorizationString'"
			
            $AuthorizationString
			
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}