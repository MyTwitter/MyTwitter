function InvokeTwitterApiCall {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$HttpEndPoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [hashtable]$ApiParams,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('GET', 'POST')]
        [string]$HttpVerb
    )

    $ErrorActionPreference = 'Stop'

    $AuthorizationString = Get-OAuthAuthorization -ApiParameters $ApiParams -HttpEndPoint $HttpEndPoint -HttpVerb $HttpVerb
		
    $HttpRequestUrl = "$HttpEndPoint`?"
    $ApiParams.GetEnumerator() | Sort-Object -Property name | foreach { $HttpRequestUrl += "{0}={1}&" -f $_.Key, $_.Value }
    $HttpRequestUrl = $HttpRequestUrl.Trim('&')
    Write-Verbose "HTTP request URL is '$HttpRequestUrl'"
    Invoke-RestMethod -URI $HttpRequestUrl -Method $HttpVerb -Headers @{ 'Authorization' = $AuthorizationString } -ContentType 'application/json'
    
}