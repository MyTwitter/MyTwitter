Function Get-TweetTimeline {
    <#
  	.SYNOPSIS
		This Function retrieves the Timeline of a Twitter user.
	.DESCRIPTION
		This Function retrieves the Timeline of a Twitter user.
	.EXAMPLE
		$TimeLine = Get-TweetTimeline -UserName "sstranger" -MaximumTweets 10
		$TimeLine | Out-Gridview -PassThru
		
		This example stores the retrieved Twitter timeline for user sstranger with a maximum of 10 tweets and pipes the result
		to the Out-GridView cmdlet.
	.EXAMPLE
		$TimeLine = Get-TweetTimeline -UserName "sstranger" -MaximumTweets 100
		$TimeLine | Sort-Object -Descending | Out-Gridview -PassThru
		
		This example stores the retrieved Twitter timeline for user sstranger with a maximum of 100 tweets,
		sorts the result descending on retweet counts and pipes the result to the Out-GridView cmdlet.

	.EXAMPLE
		$TimeLine = Get-TweetTimeline -UserName "sstranger" -MaximumTweets 200
		$TimeLine += Get-TweetTimeline -UserName "sstranger" -FromId ($TimeLine[-1].id -MaximumTweets) -MaximumTweets 100
		
		This example stores the retrieved Twitter timeline for user sstranger with the maximum allowed 200 tweets
		per single request, then makes a second query for the next 100 tweets starting from the last retrieved tweet Id.

	.EXAMPLE
		$TimeLine = Get-TweetTimeline -UserName "sstranger" -MaximumTweets 200
		$TimeLine += Get-TweetTimeline -UserName "sstranger" -SinceId ($TimeLine[0].id -MaximumTweets) -MaximumTweets 100
		
		This example stores the retrieved Twitter timeline for user sstranger with the maximum allowed 200 tweets
		per single request, then makes a second query for the newest tweets since the last tweet.
	#>
    [CmdletBinding()]
    [OutputType('System.Management.Automation.PSCustomObject')]
    param (
        [Parameter(Mandatory)]
        [string]$Username,
        [Parameter()]
        [switch]$IncludeRetweets = $true,
        [Parameter()]
        [switch]$IncludeReplies = $true,
        [Parameter()]
        [ValidateRange(1, 200)]
        [int]$MaximumTweets = 200,
        [Parameter()]
        [uint64]$FromId = $null,
        [Parameter()]
        [uint64]$SinceId = $null
    )
    process {
        $ApiParams = @{
            'include_rts'     = @{ $true = 'true'; $false = 'false' }[$IncludeRetweets -eq $true]
            'exclude_replies' = @{ $true = 'false'; $false = 'true' }[$IncludeReplies -eq $true]
            'count'           = $MaximumTweets
            'screen_name'     = $Username
            'tweet_mode'      = 'extended'
        }
        
        if ($FromId) {
            $ApiParams.Add('max_id', ($FromId -1)) # Per doc subtract 1 to avoid duplicating the last tweet
        }
        
        if ($SinceId) {
            $ApiParams.Add('since_id', $SinceId)
        }

        InvokeTwitterGetApiCall -HttpEndpoint 'https://api.twitter.com/1.1/statuses/user_timeline.json' -ApiParams $ApiParams
    }
}