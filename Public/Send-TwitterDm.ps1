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
        ## Convert the message to a Byte array
        $Message = [System.Uri]::EscapeDataString($Message)
        foreach ($User in $Username) {
            $User = [System.Uri]::EscapeDataString($User)
            $Body = [System.Text.Encoding]::ASCII.GetBytes("text=$Message&screen_name=$User");

            $apiParams = @{
                'screen_name' = $Username
                'text'        = $Message
            }
            InvokeTwitterPostApiCall -HttpEndpoint 'https://api.twitter.com/1.1/direct_messages/new.json' -ApiParams $apiParams -Body $Body
        }
		
    }
}