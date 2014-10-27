<#	
	===========================================================================
	 Created on:   	8/31/2014 3:11 PM
	 Created by:   	Adam Bertram
	 Filename:     	MyTwitter.psm1
	-------------------------------------------------------------------------
	 Module Name: MyTwitter
	 Description: This Twitter module was built to give a Twitter user the ability
		to interact with Twitter via Powershell.

		Before importing this module, you must create your own Twitter application
		on apps.twitter.com and generate an access token under the API keys section
		of the application.  Once you do so, I recommend copying/pasting your
		API key, API secret, access token and access token secret as default
		parameters under the Get-OAuthAuthorization function.
	===========================================================================
#>

function Get-OAuthAuthorization {
	<#
	.SYNOPSIS
		This function is used to setup all the appropriate security stuff needed to issue
		API calls against Twitter's API.  It has been tested with v1.1 of the API.  It currently
		includes support only for sending tweets from a single user account and to send DMs from
		a single user account.
	.EXAMPLE
		Get-OAuthAuthorization -DmMessage 'hello' -HttpEndPoint 'https://api.twitter.com/1.1/direct_messages/new.json' -Username adam
	
		This example gets the authorization string needed in the HTTP POST method to send a direct
		message with the text 'hello' to the user 'adam'.
	.EXAMPLE
		Get-OAuthAuthorization -TweetMessage 'hello' -HttpEndPoint 'https://api.twitter.com/1.1/statuses/update.json'
	
		This example gets the authorization string needed in the HTTP POST method to send out a tweet.
	.PARAMETER HttpEndPoint
		This is the URI that you must use to issue calls to the API.
	.PARAMETER TweetMessage
		Use this parameter if you're sending a tweet.  This is the tweet's text.
	.PARAMETER DmMessage
		If you're sending a DM to someone, this is the DM's text.
	.PARAMETER Username
		If you're sending a DM to someone, this is the username you'll be sending to.
	#>
	[CmdletBinding(DefaultParameterSetName = 'None')]
	[OutputType('System.Management.Automation.PSCustomObject')]
	param (
		[Parameter(Mandatory)]
		[ValidateSet('Timeline','DirectMessage','Update')]
		[string]$Api,
		[Parameter(Mandatory)]
		[string]$HttpEndPoint,
		[Parameter(Mandatory)]
		[hashtable]$ApiParameters
	)
	
	begin {
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
		Set-StrictMode -Version Latest
		try {
			[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
			[Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null
			
			if (!(Get-MyTwitterConfiguration)) {
				throw 'No MyTwitter configuration detected.  Please run New-MyTwitterConfiguration'
			} else {
				$script:MyTwitterConfiguration = Get-MyTwitterConfiguration
			}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
	
	process {
		try {
			## Generate a random 32-byte string. I'm using the current time (in seconds) and appending 5 chars to the end to get to 32 bytes
			## Base64 allows for an '=' but Twitter does not.  If this is found, replace it with some alphanumeric character
			$OauthNonce = [System.Convert]::ToBase64String(([System.Text.Encoding]::ASCII.GetBytes("$([System.DateTime]::Now.Ticks.ToString())12345"))).Replace('=', 'g')
			Write-Verbose "Generated Oauth none string '$OauthNonce'"
			
			## Find the total seconds since 1/1/1970 (epoch time)
			$EpochTimeNow = [System.DateTime]::UtcNow - [System.DateTime]::ParseExact("01/01/1970", "dd/MM/yyyy", $null)
			Write-Verbose "Generated epoch time '$EpochTimeNow'"
			$OauthTimestamp = [System.Convert]::ToInt64($EpochTimeNow.TotalSeconds).ToString();
			Write-Verbose "Generated Oauth timestamp '$OauthTimestamp'"
			
			## Build the signature
			$SignatureBase = "$([System.Uri]::EscapeDataString($HttpEndPoint))&"
			$SignatureParams = @{
				'oauth_consumer_key' = $MyTwitterConfiguration.ApiKey;
				'oauth_nonce' = $OauthNonce;
				'oauth_signature_method' = 'HMAC-SHA1';
				'oauth_timestamp' = $OauthTimestamp;
				'oauth_token' = $MyTwitterConfiguration.AccessToken;
				'oauth_version' = '1.0';
			}
			
			## Add API-specific params to the signature
			foreach ($Param in $ApiParameters.GetEnumerator()) {
				$SignatureParams[$Param.Key] = $Param.Value
			}
			
			$AuthorizationParams = $SignatureParams.Clone()
			
			## Create a string called $SignatureBase that joins all URL encoded 'Key=Value' elements with a &
			## Remove the URL encoded & at the end and prepend the necessary 'POST&' verb to the front
			$SignatureParams.GetEnumerator() | sort name | foreach { $SignatureBase += [System.Uri]::EscapeDataString("$($_.Key)=$($_.Value)&") }
			$SignatureBase = $SignatureBase.TrimEnd('%26')
			$SignatureBase = 'POST&' + $SignatureBase
			Write-Verbose "Base signature generated '$SignatureBase'"
			
			## Create the hashed string from the base signature
			$SignatureKey = [System.Uri]::EscapeDataString($MyTwitterConfiguration.ApiSecret) + "&" + [System.Uri]::EscapeDataString($MyTwitterConfiguration.AccessTokenSecret);
			
			$hmacsha1 = new-object System.Security.Cryptography.HMACSHA1;
			$hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($SignatureKey);
			$OauthSignature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($SignatureBase)));
			Write-Verbose "Using signature '$OauthSignature'"
			
			## Build the authorization headers.  This is joining all of the 'Key=Value' elements again
			## and only URL encoding the Values this time while including non-URL encoded double quotes around each value
			$AuthorizationParams.Add('oauth_signature', $OauthSignature)	
			$AuthorizationString = 'OAuth '
			$AuthorizationParams.GetEnumerator() | sort name | foreach { $AuthorizationString += $_.Key + '="' + [System.Uri]::EscapeDataString($_.Value) + '", ' }
			$AuthorizationString = $AuthorizationString.TrimEnd(', ')
			Write-Verbose "Using authorization string '$AuthorizationString'"
			
			$AuthorizationString
			
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}

Function New-MyTwitterConfiguration {
	<#
	.SYNOPSIS
		This Function stores the Twitter API Application settings in the registry.
	.EXAMPLE
		PS> New-MyTwitterConfiguration -APIKey akey -APISecret asecret -AccessToken sometoken -AccessTokenSecret atokensecret
	
		This example will create 4 registry values (APIKey,APISecret,AccessToken and AccessTokenSecret) in the
		MyTwitter registry key with the observed values.
	#>
    [CmdletBinding()]
      param (
        [Parameter(Mandatory,
          HelpMessage='What is the Twitter Client API Key?')]
        [string]$APIKey,
        [Parameter(Mandatory,
          HelpMessage='What is the Twitter Client API Secret?')]
        [string]$APISecret,
        [Parameter(Mandatory,
          HelpMessage='What is the Twitter Client Access Token?')]
        [string]$AccessToken,
        [Parameter(Mandatory,
          HelpMessage='What is the Twitter Client Access Token Secret?')]
		[string]$AccessTokenSecret,
		[switch]$Force
      )
	begin {
		$RegKey = 'HKCU:\Software\MyTwitter'
	}
	process {
		#API key, the API secret, an Access token and an Access token secret are provided by Twitter application
		Write-Verbose "Checking registry to see if the Twitter application keys are already stored"
		if (!(Test-Path -Path $RegKey)) {
			Write-Verbose "No MyTwitter configuration found in registry. Creating one."
			New-Item -Path ($RegKey | Split-Path -Parent) -Name ($RegKey | Split-Path -Leaf) | Out-Null
		}
		
		$Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
		foreach ($Value in $Values) {
			if ((Get-Item $RegKey).GetValue($Value) -and !$Force.IsPresent) {
				Write-Verbose "'$RegKey\$Value' already exists. Skipping."
			} else {
				Write-Verbose "Creating $RegKey\$Value"
				New-ItemProperty $RegKey -Name $Value -Value ((Get-Variable $Value).Value) -Force | Out-Null
			}
		}
	}
}

Function Get-MyTwitterConfiguration {
	<#
	.SYNOPSIS
		This Function retrieves the Twitter API Application settings from the registry.
	.EXAMPLE
		PS> Get-Configuration
	
		This example will retrieve all (if any) MyTwitter configuration values
		from the registry.
	#>
	
	[CmdletBinding()]
	param ()
	process {
		$RegKey = 'HKCU:\Software\MyTwitter'
		if (!(Test-Path -Path $RegKey)) {
			Write-Verbose "No MyTwitter configuration found in registry"
		} else {
			$Values = 'APIKey', 'APISecret', 'AccessToken', 'AccessTokenSecret'
			$Output = @{ }
			foreach ($Value in $Values) {
				if ((Get-Item $RegKey).GetValue($Value)) {
					$Output.$Value = (Get-Item $RegKey).GetValue($Value)
				} else {
					$Output.$Value = ''
				}
			}
			[pscustomobject]$Output
		}
	}
}

Function Remove-MyTwitterConfiguration {
	<#
	.SYNOPSIS
		This function removes the Twitter API Application settings from the registry.
	.EXAMPLE
		PS> Remove-MyTwitterConfiguration
	
		This example will remove all (if any) MyTwitter configuration values
		from the registry.
	#>
	
	[CmdletBinding()]
	param ()
	process {
		$RegKey = 'HKCU:\Software\MyTwitter'
		if (!(Test-Path -Path $RegKey)) {
			Write-Verbose "No MyTwitter configuration found in registry"
		} else {
			Remove-Item $RegKey -Force
		}
	}
}

function Escape-SpecialCharacters
{
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory)]
		[ValidateLength(1, 140)]
		[string] $Message
	)
	try
	{
		[string[]] $specialChar = @("!", "*", "'", "(", ")")
		for ($i = 0; $i -lt $specialChar.Length; $i++)
		{
			$Message = $Message.Replace($specialChar[$i], [System.Uri]::HexEscape($specialChar[$i]))
		}
		return $Message
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
}

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
		[Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[ValidateLength(1, 140)]
		[string]$Message
	)
	
	process {
		$HttpEndPoint = 'https://api.twitter.com/1.1/statuses/update.json'
		
		####Added following line/function to properly escape !,*,(,) special characters
		$Message = $(Escape-SpecialCharacters -Message $Message)
		$AuthorizationString = Get-OAuthAuthorization -Api 'Update' -ApiParameters @{'status' = $Message } -HttpEndPoint $HttpEndPoint
		
		$Body = "status=$Message"
		Write-Verbose "Using POST body '$Body'"
		Invoke-RestMethod -URI $HttpEndPoint -Method Post -Body $Body -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/x-www-form-urlencoded"
	}
}

function Send-TwitterDm {
	<#
	.SYNOPSIS
		This sends a DM to another Twitter user.  NOTE: You can only send up to 
		250 DMs in a 24 hour period.
	.EXAMPLE
		Send-TwitterDm -Message 'hello, Adam' -Username 'adam','bill'
	
		This sends a DM with the text 'hello, Adam' to the username 'adam' and 'bill'
	.PARAMETER Message
		The text of the DM.
	.PARAMETER Username
		The username(s) you'd like to send the DM to.
	#>
	[CmdletBinding()]
	[OutputType('System.Management.Automation.PSCustomObject')]
	param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[ValidateLength(1, 140)]
		[string]$Message,
		[Parameter(Mandatory)]
		[string[]]$Username
	)
	
	process {
		$HttpEndPoint = 'https://api.twitter.com/1.1/direct_messages/new.json'
	
		$AuthorizationString = Get-OAuthAuthorization -Api 'DirectMessage' -ApiParameters @{ 'screen_name' = $Username; 'text' = $Message } -HttpEndPoint $HttpEndPoint
		
		## Convert the message to a Byte array
		$Message = [System.Uri]::EscapeDataString($Message)
		foreach ($User in $Username) {
			$User = [System.Uri]::EscapeDataString($User)
			$Body = [System.Text.Encoding]::ASCII.GetBytes("text=$Message&screen_name=$User");
			Write-Verbose "Using POST body '$Body'"
			Invoke-RestMethod -URI $HttpEndPoint -Method Post -Body $Body -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/x-www-form-urlencoded"
		}
		
	}
}

########################################################################################################################
# Split-Tweet
# Function for the PowerShell MyTwitter module
# Twitter has a max tweet message length of 140 characters and you may sometimes want to split a message into smaller
# separate tweets to comply to 140 character limit.
# Date: 05/10/2014
# Author; Stefan Stranger
# Version: 0.4
# Changes: 
#		(0.2) = split at word boundaries, removed parameter postfix, removed
#		(0.3) = Return a string object with more properties, like length etc.
#		(0.4) = removed Length parameter. The function will will decide on the size of the tweet.
# ToDo: Only split on complete words. << added @sqlchow
#       Make pipeline aware
#       Return a string object with more properties, like length etc. << added @sstranger
########################################################################################################################
Function Split-Tweet {
  <#
  .SYNOPSIS
   This Function splits a Twitter message that exceed the maximum length of 140 characters.
  .DESCRIPTION
   This Function splits a Twitter message that exceed the maximum length of 140 characters.
  .EXAMPLE
   $Message = "This is a very long message that needs to be split because it's too long for the max twitter characters. Hope you like my new split-tweet function."
   Split-Tweet -Message $Message
   Message                                                                                                          Length
   -------                                                                                                          ------
   This is a very long message that needs to be split...                                                                134
   split-tweet function. [2\2]                                                                                          27

   .EXAMPLE
   $Message = "This is a very long message that needs to be split because it's too long for the max twitter characters. Hope you like my new split-tweet function."
   Split-Tweet -Message $Message | Select-Object @{L="Message";E={$_}} | % {Send-Tweet -Message $_.Message}
   Splits a message into seperate messages and pipes the result to the Send-Tweet Function.
  #>

	[CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Message you want to split
        [Parameter(
                   HelpMessage = 'What is the message you want to split?',
                   Mandatory = $true,
                   Valuefrompipeline=$true,
                   Position = 0)]
        [string]$Message
    )

  [int]$Length = 130
  #Check length of Tweet
  if ($Message.length -gt $Length)
  {
    Write-Verbose 'Message needs to be split'
    #Total length of message
    Write-Verbose "Length of message is $($message.length)"
    #Calculate number message
    Write-Verbose "Split message in $(($message.Length)/$Length) times"
    #Create an array
    $numberofmsgs = [math]::Ceiling($(($Message.Length)/$Length))
    Write-Verbose "`$numberofmsgs: $numberofmsgs"
    $counter = 0 
    $result = @()

    #extract all the words for splitting the stream
    $wordCollection = [Regex]::Split($Message, '((?ins)(\w+))');
    $collectionCount = $wordCollection.Count
    Write-Verbose "number of words in message: $collectionCount"

    #add auto-post fix like [1\n]
	$Postfix = '['+'1\'+ $numberofmsgs.ToString() +']'
	Write-Verbose "`$Postfix length: $($Postfix.Length)"

	#if people tweet something that is greater than 1400 chars
	#we may need to account for that.
	$Length = $Length - $($Postfix.Length) + 2
	$numberofmsgs = [math]::Ceiling($(($Message.Length)/$Length)) 
    
    #word iterator and message container
    $wordIterator = 0
    $tempMessage=""

    while($wordIterator -lt $collectionCount) 
    {
        #May not be a good way of doing this but, works for now.
        $tempMsgLength = $tempMessage.Length
        $currentWordLength = $wordCollection[$wordIterator].Length
        $postFixLength = $Postfix.Length
        

	    While((($tempMsgLength + $currentWordLength + $postFixLength) -lt $Length) -and ($wordIterator -lt $collectionCount))
	    {
		    $tempMessage = $tempMessage + $wordCollection[$wordIterator]
            
            #housekeeping
            $tempMsgLength = $tempMessage.Length
            $currentWordLength = $wordCollection[$wordIterator].Length
		    $wordIterator += 1
    
	    }

        #if the parameter is not specified only then update the default postfix.
        #not needed any more if(-not $PSBoundParameters.ContainsKey('Postfix')){}
		$counter +=1;
		$Postfix = '[' + "$counter" + '\' + $numberofmsgs.ToString() + ']'

        #passing message to result array
        #Creating a msg object with message and length property
        $msgobject = [pscustomobject]@{
            Message= $tempMessage + " $Postfix"
            Length = ($tempMessage + " $Postfix").Length
            }

        $result += $msgobject

        Write-Verbose "Message: $tempMessage $Postfix" 
        $tempMessage = ""
    }
  }
  else
  {
    Write-Verbose 'No need to split tweet'
  }
  return $result
}

########################################################################################################################
# Get-ShortURL
# Function for the PowerShell MyTwitter module
# The function gets a shortened URL for using when you need to embed web-links.
# Date: 05/10/2014
# Author: SqlChow
# Version: 0.1
# Changes: 
# ToDo: Maybe we need to export it. However, it can stay inside the module.
########################################################################################################################
Function Get-ShortURL {
  <#
  .SYNOPSIS
   This Function creats a shortened URL.

  .DESCRIPTION
   This Function creats a shortened URL using the tinyURL service. The function is based on
   a powertip on http://powershell.com/cs/blogs/tips/archive/2014/09/25/creating-tinyurls.aspx

  .EXAMPLE
   Get-ShortURL -URL "https://raw.githubusercontent.com/stefanstranger/MyTwitter/master/MyTwitter.psm1"
   http://tinyurl.com/k8tktsk

  .LINK
    http://powershell.com/cs/blogs/tips/archive/2014/09/25/creating-tinyurls.aspx
  #>

    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Message you want to split
        [Parameter(
                   HelpMessage = 'The URL that needs shortening',
                   Mandatory = $true,
                   ValueFromPipelineByPropertyName = $false,
                   Position = 0)]
        [string]$URL
    )

    #code here
    $shortenedURL = $null;
    $tinyUrlApiLink = "http://tinyurl.com/api-create.php?url=$URL";
    $webClient = New-Object -TypeName System.Net.WebClient;
    $shortenedURL = $webClient.DownloadString($tinyUrlApiLink).ToString();
    return $shortenedURL;
}


########################################################################################################################
# Resize-Tweet
# Function for the PowerShell MyTwitter module
# You sometimes want to replace words in your tweet to comply to max tweet length of 140 characters
# Date: 09/10/2014
# Author; Stefan Stranger
# Version: 0.2
# Changes: 
#		(0.1) = initial version
#   (0.2) = renamed function from Shorten-Tweet to Resize-Tweet
# ToDo: - speed up performance. .Net class is faster but does not do case insensitive replace.
########################################################################################################################
Function Resize-Tweet {
  <#
  .SYNOPSIS
   This Function shortens Twitter messages for words stored in a hashtable.
  .DESCRIPTION
   This Function shortens Twitter messages for words stored in a hashtable so that you may stay within the Twitter message
   limit of 140 characters.
  .EXAMPLE
   $Message = "This is an example tweet for testing purposes. And here are some words to replace: two, and, One, at, too"
   Resize-Tweet -Message $Message
   c:\
   This is an example tweet 4 testing purposes. & here are some word to replace: 2, &, 1, @, 2                                                                                         27
  #>

	[CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Message you want to split
        [Parameter(
                   HelpMessage = 'What is the message you want to shorten?',
                   Mandatory = $true,
                   Valuefrompipeline=$true,
                   Position = 0)]
        [string]$Message
    )

    #Hashtable containing search and replace options
    $replacehash = [ordered]@{
      'two' = '2';
      'and' ='&';
      'one' = '1';
      'at' = '@';
      'too' = '2';
      'to' = '2';
      'wait' = 'w8';
      'enjoy' = 'njoy';
      'please' = 'plz';
      'thanks' = 'thx';
      'for' = '4';
      'you' = 'u';
      'people' = 'ppl';
      'okay' = 'K';
      'ok' = 'K'
    }



    Write-Verbose "Current length of message: $($message.Length)"

    foreach ($h in $replacehash.GetEnumerator()) {
      $Pattern = $h.Name
      $New = $h.Value
      #$strReplace = [regex]::replace($message, $pattern, $New) #remove because of not being case insensitive
      Write-Verbose "We will now replace $Pattern with $New :" 
      $strReplace = $Message -replace $h.Name, $h.Value
      $Message = $strReplace

    }

    Write-Verbose "New length of message: $($message.Length)"
    #Creating a msg object with message and length property
    $msgobject = [pscustomobject]@{
        Message= $Message
        Length = $Message.Length
        }

    $result += $msgobject

    $result
	
	
}

Function Get-TweetTimeline {
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
		[int]$MaximumTweets = 200
	)
	process {
		$HttpEndPoint = 'https://api.twitter.com/1.1/statuses/user_timeline.json'
		
		$ApiParams = @{
			#'include_rts' = @{ $true = 'true';$false = 'false' }[$IncludeRetweets -eq $true]
			#'exclude_replies' = @{ $true = 'false'; $false = 'true' }[$IncludeReplies -eq $true]
			'count' = $MaximumTweets
			'screen_name' = $Username
		}
		$Body = 'screen_name=randafaith'
		Write-Verbose "Using body '$Body'"
		$AuthorizationString = Get-OAuthAuthorization -Api 'Timeline' -ApiParameters $ApiParams -HttpEndPoint $HttpEndPoint
		Invoke-RestMethod -URI $HttpEndPoint -Method Post -Body $Body -Headers @{ 'Authorization' = $AuthorizationString } -ContentType "application/x-www-form-urlencoded"
		#$Timeline | Select Id, created_at, text, retweet_count, favorite_count
	}
}