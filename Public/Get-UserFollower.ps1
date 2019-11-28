function Get-UserFollower {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
    )

    $ErrorActionPreference = 'Stop'

    $followerIds = GetUserFollowerId -UserName $UserName
    Write-Verbose -Message "Found $($followerIds.Count) followers..."

    $maxApiCallUserCount = 100
    if ($followerIds.Count -gt $maxApiCallUserCount) {
        $groupCount = [math]::Floor($followerIds.Count / $maxApiCallUserCount)
        $remainder = $followerIds.Count % $maxApiCallUserCount
    } else {
        $groupCount = 1
        $remainder = 0
    }

    $responses = @()
    for ($i = 1; $i -lt $groupCount; $i++) {
        $groupIdCeiling = ($i * $maxApiCallUserCount) - 1
        $groupIdFloor = ($groupIdCeiling - $maxApiCallUserCount) + 1
        
        $ApiParams = @{
            'user_id' = $followerIds[$groupIdFloor..$groupIdCeiling] -join ','
            # 'user_id' = '19891458'
        }
        Write-Verbose -Message "Querying user IDs $groupIdFloor to $groupIdCeiling..."
        $responses += InvokeTwitterGetApiCall -HttpEndpoint 'https://api.twitter.com/1.1/users/lookup.json' -ApiParams $ApiParams
    }
    if ($remainder -gt 0) {
        $groupIdCeiling = $followerIds.Count
        $groupIdFloor = $followerIds.Count - $remainder
        
        $ApiParams = @{
            'user_id' = $followerIds[$groupIdFloor..$groupIdCeiling] -join ','
        }
        Write-Verbose -Message "Querying user IDs $groupIdFloor to $groupIdCeiling..."
        $responses += InvokeTwitterPostApiCall -HttpEndpoint 'https://api.twitter.com/1.1/users/lookup.json' -ApiParams $ApiParams
    }
    $responses
}