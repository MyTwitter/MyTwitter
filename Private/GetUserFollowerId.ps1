function GetUserFollowerId {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScreenName
    )

    $ErrorActionPreference = 'Stop'

    $ApiParams = @{
        'screen_name' = $ScreenName
    }

    InvokeTwitterGetApiCall -HttpEndpoint 'https://api.twitter.com/1.1/followers/ids.json' -ApiParams $ApiParams
}