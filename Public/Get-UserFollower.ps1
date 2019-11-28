function Get-UserFollower {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScreenName
    )

    $ErrorActionPreference = 'Stop'

    $HttpEndPoint = 'https://api.twitter.com/1.1/users/lookup.json'
    $ApiParams = @{
        'screen_name' = $ScreenName
    }

    $AuthorizationString = Get-OAuthAuthorization -ApiParameters $ApiParams -HttpEndPoint $HttpEndPoint -HttpVerb GET
		
    $HttpRequestUrl = "$HttpEndPoint?"
    $ApiParams.GetEnumerator() | Sort-Object -Property name | foreach { $HttpRequestUrl += "{0}={1}&" -f $_.Key, $_.Value }
    $HttpRequestUrl = $HttpRequestUrl.Trim('&')
    Write-Verbose "HTTP request URL is '$HttpRequestUrl'"
    Invoke-RestMethod -URI $HttpRequestUrl -Method Get -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/json"   
}