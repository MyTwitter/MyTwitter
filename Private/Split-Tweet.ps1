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
	.NOTES
		Twitter has a max tweet message length of 140 characters and you may sometimes want to split a message into smaller
		separate tweets to comply to 140 character limit.
		Date: 05/10/2014
		Author; Stefan Stranger
		Version: 0.4
		Changes: 
				(0.2) = split at word boundaries, removed parameter postfix, removed
				(0.3) = Return a string object with more properties, like length etc.
				(0.4) = removed Length parameter. The function will will decide on the size of the tweet.
		ToDo: Only split on complete words. << added @sqlchow
		      Make pipeline aware
		      Return a string object with more properties, like length etc. << added @sstranger
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
    if ($Message.length -gt $Length) {
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

        while($wordIterator -lt $collectionCount) {
            #May not be a good way of doing this but, works for now.
            $tempMsgLength = $tempMessage.Length
            $currentWordLength = $wordCollection[$wordIterator].Length
            $postFixLength = $Postfix.Length
        

            While((($tempMsgLength + $currentWordLength + $postFixLength) -lt $Length) -and ($wordIterator -lt $collectionCount)) {
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
                Message = $tempMessage + " $Postfix"
                Length  = ($tempMessage + " $Postfix").Length
            }

            $result += $msgobject

            Write-Verbose "Message: $tempMessage $Postfix" 
            $tempMessage = ""
        }
    } else {
        Write-Verbose 'No need to split tweet'
    }
    return $result
}