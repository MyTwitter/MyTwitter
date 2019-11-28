function GetUserFollowerId {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
    )

    $ErrorActionPreference = 'Stop'

    $ApiParams = @{
        'screen_name' = $UserName
    }

    $response = InvokeTwitterGetApiCall -HttpEndpoint 'https://api.twitter.com/1.1/followers/ids.json' -ApiParams $ApiParams
    $response.ids
}