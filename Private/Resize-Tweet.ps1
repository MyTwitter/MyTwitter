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
		This is an example tweet 4 testing purposes. & here are some word to replace: 2, &, 1, @, 2
	.NOTES
		You sometimes want to replace words in your tweet to comply to max tweet length of 140 characters
		Date: 09/10/2014
		Author; Stefan Stranger
		Version: 0.2
		Changes: 
			(0.1) = initial version
		  	(0.2) = renamed function from Shorten-Tweet to Resize-Tweet
		ToDo: - speed up performance. .Net class is faster but does not do case insensitive replace.
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
        'two'    = '2';
        'and'    ='&';
        'one'    = '1';
        'at'     = '@';
        'too'    = '2';
        'to'     = '2';
        'wait'   = 'w8';
        'enjoy'  = 'njoy';
        'please' = 'plz';
        'thanks' = 'thx';
        'for'    = '4';
        'you'    = 'u';
        'people' = 'ppl';
        'okay'   = 'K';
        'ok'     = 'K'
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
        Message = $Message
        Length  = $Message.Length
    }

    $result += $msgobject

    $result
	
	
}