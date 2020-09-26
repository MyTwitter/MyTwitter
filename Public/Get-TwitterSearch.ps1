function Get-TwitterSearch {
    [CmdletBinding()]
    param
    (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$searchString,
    [Parameter()]
    [string]$geocode,
    [Parameter()]
    [string]$lang,
    [Parameter()]
    [string]$locale,
    [Parameter()]
    [ValidateSet('mixed','recent','popular')]
    [string]$result_type,
    [Parameter()]
    [int]$count = 1500,
    [Parameter()]
    [datetime]$until,
    [Parameter()]
    [string]$since_id,
    [Parameter()]
    [string]$max_id,
    [Parameter()]
    [string]$include_entities
    )
    
    $apiLimit = 1500 #the free api limit AFAIK
    if ($count -gt  $apiLimit){$count = $apiLimit} #whoah boi
    $resultsperPage = 100 #max results per page AFAIK
    $ApiParams = @{
        'q' = $searchString;
        'count' = $resultsperPage;
    }
    #go through the params and see if they've been set
    #these are from the standard search api
    #ref https://developer.twitter.com/en/docs/twitter-api/v1/tweets/search/api-reference/get-search-tweets
    ('geocode',
        'lang',
        'locale',
        'result_type',
        'count',
        'since_id',
        'max_id',
        'include_entities') |ForEach-Object{
        if ($PSBoundParameters.ContainsKey($_)){
            $ApiParams[$_] = $PSBoundParameters[$_]
        }
        if ($PSBoundParameters.ContainsKey('until')){
            $ApiParams['until']  = (Get-Date -date $until -Format 'yyyy-MM-dd') #format dates for the API
        }
    }

    $responses = @()

    for ($i = 0; $i -lt $count; $i += $resultsPerPage){
        $response = InvokeTwitterGetApiCall -HttpEndpoint 'https://api.twitter.com/1.1/search/tweets.json' -ApiParams $ApiParams
        if ($response.statuses.length -gt 0){
            $lastTweet = $response.statuses[($response.statuses.length - 1 )].id_str
            $ApiParams.max_id = $lastTweet
        }
        $responses += $response
    }
    $responses
}
