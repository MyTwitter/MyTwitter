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

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Body,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Form
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        $AuthorizationString = Get-OAuthAuthorization -ApiParameters $ApiParams -HttpEndPoint $HttpEndPoint -HttpVerb 'POST'

        $ivrParams = @{
            'Uri'         = $HttpEndPoint
            'Method'      = 'Post'
            'Headers'     = @{ 'Authorization' = $AuthorizationString }
            'ContentType' = 'application/x-www-form-urlencoded'        
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            Write-Verbose "Using POST body '$Body'"
            $ivrParams.Body = $Body
        } elseif ($PSBoundParameters.ContainsKey('Form')) {
            $ivrParams.Form = $Form
        }
        
        Invoke-RestMethod @ivrParams
    }
}