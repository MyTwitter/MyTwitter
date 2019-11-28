function Send-Tweet {
    <#
	.SYNOPSIS
		This sends a tweet under a username.
	.EXAMPLE
		Send-Tweet -Message 'hello, world'
	
		This example will send a tweet with the text 'hello, world'.
	.PARAMETER Message
		The text of the tweet.
	#>
    [CmdletBinding()]
    [OutputType('System.Management.Automation.PSCustomObject')]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateLength(1, 140)]
        [string]$Message
    )
	
    process {
        $HttpEndPoint = 'https://api.twitter.com/1.1/statuses/update.json'
		
        ####Added following line/function to properly escape !,*,(,) special characters
        $Message = $(Add-SpecialCharacters -Message $Message)
        $AuthorizationString = Get-OAuthAuthorization -ApiParameters @{'status' = $Message } -HttpEndPoint $HttpEndPoint -HttpVerb 'POST'
		
        $Body = "status=$Message"
        Write-Verbose "Using POST body '$Body'"
        Invoke-RestMethod -URI $HttpEndPoint -Method Post -Body $Body -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/x-www-form-urlencoded"
    }
}