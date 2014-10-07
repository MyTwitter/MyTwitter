<#	
	===========================================================================
	 Created on:   	8/31/2014 3:11 PM
	 Created by:   	Adam Bertram
	 Filename:     	MyTwitter.psm1
	-------------------------------------------------------------------------
	 Module Name: MyTwitter
	 Description: This Twitter module was built to give a Twitter user the ability
		to send tweets from his account and to DM other users.  At this time this
		is the only functionality available.

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
	.PARAMETER ApiKey
		The API key for the Twitter application you previously setup.
	.PARAMETER ApiSecret
		The API secret key for the Twitter application you previously setup.
	.PARAMETER AccessToken
		The access token that you generated within your Twitter application.
	.PARAMETER
		The access token secret that you generated within your Twitter application.
	#>
	[CmdletBinding(DefaultParameterSetName = 'None')]
	[OutputType('System.Management.Automation.PSCustomObject')]
	param (
		[Parameter(Mandatory)]
		[string]$HttpEndPoint,
		[Parameter(Mandatory, ParameterSetName = 'NewTweet')]
		[string]$TweetMessage,
		[Parameter(Mandatory, ParameterSetName = 'DM')]
		[string]$DmMessage,
		[Parameter(Mandatory, ParameterSetName = 'DM')]
		[string]$Username
	)
	
	begin {
		$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
		Set-StrictMode -Version Latest
		try {
			[Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
			[Reflection.Assembly]::LoadWithPartialName("System.Net") | Out-Null
		} catch {
			Write-Error $_.Exception.Message
		}

    if(!(Test-Path -Path HKCU:\Software\MyTwitter))
    {
      #Call Set-OAuthorization function
      Set-OAuthAuthorization
    }
    else
    {
        Write-Verbose "Retrieving Twitter Application settings from registry HKCU:\Software\MyTwitter"
        $global:APIKey = (Get-Item HKCU:\Software\MyTwitter).getvalue("APIKey")
        $global:APISecret = (Get-Item HKCU:\Software\MyTwitter).getvalue("APISecret")
        $global:AccessToken = (Get-Item HKCU:\Software\MyTwitter).getvalue("AccessToken")
        $global:AccessTokenSecret = (Get-Item HKCU:\Software\MyTwitter).getvalue("AccessTokenSecret")

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
				'oauth_consumer_key' = $ApiKey;
				'oauth_nonce' = $OauthNonce;
				'oauth_signature_method' = 'HMAC-SHA1';
				'oauth_timestamp' = $OauthTimestamp;
				'oauth_token' = $AccessToken;
				'oauth_version' = '1.0';
			}
			if ($TweetMessage) {
				$SignatureParams.status = $TweetMessage
			} elseif ($DmMessage) {
				$SignatureParams.screen_name = $Username
				$SignatureParams.text = $DmMessage
			}
			
			## Create a string called $SignatureBase that joins all URL encoded 'Key=Value' elements with a &
			## Remove the URL encoded & at the end and prepend the necessary 'POST&' verb to the front
			$SignatureParams.GetEnumerator() | sort name | foreach { $SignatureBase += [System.Uri]::EscapeDataString("$($_.Key)=$($_.Value)&") }
			$SignatureBase = $SignatureBase.TrimEnd('%26')
			$SignatureBase = 'POST&' + $SignatureBase
			Write-Verbose "Base signature generated '$SignatureBase'"
			
			## Create the hashed string from the base signature
			$SignatureKey = [System.Uri]::EscapeDataString($ApiSecret) + "&" + [System.Uri]::EscapeDataString($AccessTokenSecret);
			
			$hmacsha1 = new-object System.Security.Cryptography.HMACSHA1;
			$hmacsha1.Key = [System.Text.Encoding]::ASCII.GetBytes($SignatureKey);
			$OauthSignature = [System.Convert]::ToBase64String($hmacsha1.ComputeHash([System.Text.Encoding]::ASCII.GetBytes($SignatureBase)));
			Write-Verbose "Using signature '$OauthSignature'"
			
			## Build the authorization headers using most of the signature headers elements.  This is joining all of the 'Key=Value' elements again
			## and only URL encoding the Values this time while including non-URL encoded double quotes around each value
			$AuthorizationParams = $SignatureParams
			$AuthorizationParams.Add('oauth_signature', $OauthSignature)
			
			## Remove any API call-specific params from the authorization params
			$AuthorizationParams.Remove('status')
			$AuthorizationParams.Remove('text')
			$AuthorizationParams.Remove('screen_name')
			
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

########################################################################################################################
# Set-OAuthAuthorization
# For the Twitter Authentication you need to use your own Client Application Consumer key and Consumer Secret
# Request your Twitter API Key at https://apps.twitter.com/
# We need the following info from the Twitter application you created
# API key, the API secret, an Access token and an Access token secret
# Date: 25/9/2014
# Author; Stefan Stranger
# Version: 0.1
# Changes: 
# ToDo: Check spaces at begin of Twitter API settings. Sometimes a space is being copied from webpage.
########################################################################################################################
Function Set-OAuthAuthorization
{
  <#
	.SYNOPSIS
		This Function stores the Twitter API Application settings in the registry.
	.EXAMPLE
		Set-OAuthAuthorization
	
		This example will check if the Twitter API Application settings are already stored in the registry.
    If not it opens the Twitter API application website to retrieve the Twitter API Settings.
	#>
 
    [CmdletBinding(SupportsShouldProcess=$true)]
      param
      (
        [Parameter(
          HelpMessage='What is the Twitter Client API Key?')]
        [string]$APIKey,
        [Parameter(
          HelpMessage='What is the Twitter Client API Secret?')]
        [string]$APISecret,
        [Parameter(
          HelpMessage='What is the Twitter Client Access Token?')]
        [string]$AccessToken,
        [Parameter(
          HelpMessage='What is the Twitter Client Access Token Secret?')]
        [string]$AccessTokenSecret,
        [switch] $Force
      )

    Write-Verbose "Function Set-OAuthAuthorization started"

    
    #API key, the API secret, an Access token and an Access token secret are provided by Twitter application/
    Write-Verbose "Check Registry if the Twitter Application keys are already stored"
    if(!(Test-Path -Path HKCU:\Software\MyTwitter) -or $force)
    {
        Write-Output "You first need to register a Twitter Application and store the API key, the API secret, an Access token and an Access token secret on your machine `n `nGo to https://apps.twitter.com"
        start "https://apps.twitter.com/"
        $APIKey = Read-Host "Enter Twitter API Key"
        $APISecret = Read-Host "Enter Twitter API Secret"
        $AccessToken = Read-Host "Enter Twitter Access Token"
        $AccessTokenSecret = Read-Host "Enter Twitter Access Token Secret"
        Write-Verbose "Storing Consumer and Consumer Secret keys in Registry HKCU:\Software\MyTwitter"
        #Store Application API settings in Registry

        if($APIKey -and $APISecret -and $AccessToken -and $AccessTokenSecret )
        {
            New-Item -Path hkcu:\software -Name MyTwitter | out-null
            New-ItemProperty HKCU:\Software\MyTwitter -name "APIKey" -value "$APIKey" | out-null
            New-ItemProperty HKCU:\Software\MyTwitter -name "APISecret" -value "$APISecret" | out-null
            New-ItemProperty HKCU:\Software\MyTwitter -name "AccessToken" -value "$AccessToken" | out-null
            New-ItemProperty HKCU:\Software\MyTwitter -name "AccessTokenSecret" -value "$AccessTokenSecret" | out-null
        }
        else 
        {
          write-error "Please restart Set-OAuthAuthorization Function. One of the requested properties is empty"
        }
    }
    else
    {
        Write-Verbose "Retrieving Twitter Application settings from registry HKCU:\Software\MyTwitter"
        $APIKey = (Get-Item HKCU:\Software\MyTwitter).getvalue("APIKey")
        $APISecret = (Get-Item HKCU:\Software\MyTwitter).getvalue("APISecret")
        $AccessToken = (Get-Item HKCU:\Software\MyTwitter).getvalue("AccessToken")
        $AccessTokenSecret = (Get-Item HKCU:\Software\MyTwitter).getvalue("AccessTokenSecret")
    }

    Write-Output "Finished Storing\Retrieving Twitter Application Authentication"
    Write-Verbose "Function Set-OAuthAuthorization finished"


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
		####
		
		$AuthorizationString = Get-OAuthAuthorization -TweetMessage $Message -HttpEndPoint $HttpEndPoint
		
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
		
		$AuthorizationString = Get-OAuthAuthorization -DmMessage $Message -HttpEndPoint $HttpEndPoint -Username $Username -Verbose
		
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
# seperate tweets to comply to 140 character limit.
# Date: 05/10/2014
# Author; Stefan Stranger
# Version: 0.3
# Changes: split at word boundaries, removed parameter postfix.
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
   $Message = "This is a very long message that needs to be splitted because it's too long for the max twitter characters. Hope you like my new split-tweet function."
   Split-Tweet -Message $Message
   This is a very long message that needs to be splitted because it's too long for the max twitter characters. Hope yo like my new split-tweet  
   function.
  .EXAMPLE
   $message = 1..100 -join ""
   Split-Tweet -Message $Message -Length 10 
   123456 [1\4]
   789101 [2\4]
   112131 [3\4]
   415161 [4\4]
   Splits a message into seperate messages with a length of 10 characters with a Postfix.
  .EXAMPLE
   $Message = "This is a very long message that needs to be splitted because it's too long for the max twitter characters. Hope you like my new split-tweet function."
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
                   ValueFromPipelineByPropertyName = $false,
                   Position = 0)]
        [string]$Message,
        [Parameter(
                   HelpMessage = 'What is length of the message?',
                   Mandatory = $false,
                   ValueFromPipelineByPropertyName = $false)]
        [int]$Length = 139
    )


  #Check length of Tweet
  if ($Message.length -gt $Length)
  {
    Write-Verbose 'Message needs to be splitted'
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

Export-ModuleMember Send-Tweet
Export-ModuleMember Send-TwitterDm
Export-ModuleMember Split-Tweet
Export-ModuleMember Set-OAuthAuthorization