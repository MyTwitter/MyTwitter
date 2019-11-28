function InvokeTwitterPostApiCall {
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
        [string]$Body
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        $AuthorizationString = Get-OAuthAuthorization -ApiParameters $ApiParams -HttpEndPoint $HttpEndPoint -HttpVerb 'POST'
		
        Write-Verbose "Using POST body '$Body'"
        Invoke-RestMethod -URI $HttpEndPoint -Method Post -Body $Body -Headers @{ 'Authorization' = $AuthorizationString } -ContentType 'application/x-www-form-urlencoded'        
    }
}