function Send-PicTweet {
    <#
	.SYNOPSIS
		This uploads a picture using the chunked Twitter upload and sends a tweet witht the message.

	.DESCRIPTION
		Unlike tweeting with from browser or smartphone Media Upload is handled seperately from the tweet process in the TwitterAPI. 
		The media data must be uploaded first and the provided media_id is used in the tweet.
		This function combines both mechanisms to one function.

	.PARAMETER Message
		Enter the message that the tweet should include
		Example: '-message "Hello World"'
	
	.PARAMETER PathtoPic
		Enter the Path to the image you want to include in the tweet. File  must be smaller than 5MB. (Twitter Restriction)
		Example: '-PathtoPic "C:\temp\test.jpg"'
	
	.EXAMPLE
		Send-PicTweet -Message "Hello World" -PathtoPic "C:\temp\test.jpg"
		This uploads the test.jpg file to twitter and then sends a tweet with the provided message as well as the media_id received by the upload
	#>
	
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateLength(1, 140)]
        [string]$Message,

        [Parameter(Mandatory)]
        [ValidateScript({ (Get-ChildItem $_).Length -le 5MB })]
        [string]$PathtoPic
    )

    process {
        $TotalBytes = (Get-ChildItem $PathtoPic).Length	
        ######
        ### Splitting the Picture in 900KB-sized Base64encoded Strings. (better performance and can be directly combined with chunked upload to twitter)
        ### For the splitting of the Base64Encoding I used this wonderful solution:
        ### https://mnaoumov.wordpress.com/2013/08/20/efficient-base64-conversion-in-powershell/
        ######
        $bufferSize = 900000 # should be a multiplier of 3
        $buffer = New-Object byte[] $bufferSize
        $reader = [System.IO.File]::OpenRead($PathtoPic)
        [System.Collections.ArrayList]$img = @()
        do {
            $bytesread = $reader.Read($buffer, 0, $bufferSize)
            $null = $img.Add([Convert]::ToBase64String($Buffer, 0, $bytesread))
        } while ($bytesread -eq $bufferSize)
        $reader.Dispose()

        ######
        ### Using Chunked Media Upload, as suggested by Twitter.
        ### See TwitterAPI Refernce for...well...Reference: https://developer.twitter.com/en/docs/media/upload-media/uploading-media/chunked-media-upload
        ######
			
        ## INIT Chunked Upload
        try {
            $INITBody = @{ command="INIT"; total_bytes=$TotalBytes; media_type="image/jpeg" }
            InvokeTwitterPostApiCall -HttpEndpoint 'https://upload.twitter.com/1.1/media/upload.json' -ApiParams @{ } -Form $INITBody
        } catch { throw 'Error during Upload INIT' }

        ## APPEND Body
        try {
            $x = 0
            foreach ($chunk in $img) {
                $AppendBody = @{ command="APPEND"; media_id=$INITResponse.media_id; media_data=$img[$x]; segment_index=$x }
                InvokeTwitterPostApiCall -HttpEndpoint 'https://upload.twitter.com/1.1/media/upload.json' -ApiParams @{ } -Form $AppendBody
                $x++
            }
        } catch { throw 'Error during Upload APPEND' }

        ### FINALIZE Body
        try {
            $FINALIZEBody = @{ command="FINALIZE"; media_id=$INITResponse.media_id }
            InvokeTwitterPostApiCall -HttpEndpoint 'https://upload.twitter.com/1.1/media/upload.json' -ApiParams @{ } -Form $FINALIZEBody
        } catch { throw 'Error during Upload FINALIZE' }

        ####Added following line/function to properly escape !,*,(,) special characters
        $Message = $(Add-SpecialCharacters -Message $Message)
        $MediaID = $INITResponse.media_id
        $Body = "status=$Message&media_ids=$MediaID"
        $apiParams =  @{
            'status'    =$message
            'media_ids' =$MediaID
        }
        InvokeTwitterPostApiCall -HttpEndpoint 'https://api.twitter.com/1.1/statuses/update.json' -ApiParams $apiParams -Body $Body
    }
}