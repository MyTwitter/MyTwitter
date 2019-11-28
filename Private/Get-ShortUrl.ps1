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
	.NOTES
		Date: 28/10/2014
		Author: SqlChow, sstranger
		Version: 0.2
		Changes: Added support for the following url shortning services:
		         is.gd, snurl, tr.im, bit.ly
		         Inspiration from following blogpost: http://twitter.ulitzer.com/node/1009036
		
		ToDo: Maybe we need to export it. However, it can stay inside the module.
		      Update Synopsis with examples
		      Bitly part needs to check for http in url.
  #>

    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # The URL you want to split.
        [Parameter(
            HelpMessage = 'The URL that needs shortening',
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $false,
            Position = 0)]
        [string]$URL,
        [Parameter(
            Mandatory=$False,
            ParameterSetName='Default')]
        [ValidateSet('TinyURL', 'Bitly', 'isgd', 'Trim')]
        [string]$provider='TinyURL'
    )
 
    DynamicParam {
        if ($provider -eq 'Bitly') {
            $bitlyAttribute = New-Object System.Management.Automation.ParameterAttribute
            $bitlyAttribute.Position = 3
            $bitlyAttribute.Mandatory = $false
            $bitlyAttribute.HelpMessage = 'Please enter your Bitly Generic Access Token:'
            $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attributeCollection.Add($bitlyAttribute)
            $bitlyParam = New-Object System.Management.Automation.RuntimeDefinedParameter('BitlyAccessToken', [string], $attributeCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('BitlyAccessToken', $bitlyParam)
            return $paramDictionary
        }
    }
    
    Process {
        #code here
        $shortenedURL = $null;

        #Check if BitlyAccessToken is entered
        $BitlyAccessToken = $PSBoundParameters['BitlyAccessToken']


        switch ($provider.ToLower()) {
            "tinyurl" {
                $tinyUrlApiLink = "http://tinyurl.com/api-create.php?url=$URL";
                $webClient = New-Object -TypeName System.Net.WebClient;
                $shortenedURL = $webClient.DownloadString($tinyUrlApiLink).ToString();
            }

            "isgd" {
                $isgdUrlApiLink = "http://is.gd/api.php?longurl=$URL";
                $webClient = New-Object -TypeName System.Net.WebClient;
                $shortenedURL = $webClient.DownloadString($isgdUrlApiLink).ToString();
            }

            "trim" {
                $trimUrlApiLink = "http://api.tr.im/api/trim_url.xml?url=$URL";
                $webClient = New-Object -TypeName System.Net.WebClient;
                $shortenedURL = $webClient.DownloadString($trimUrlApiLink).ToString();
            }

            "bitly" {
                Write-Verbose "Checking for Bitly Access Token"
                if (!($BitlyAccessToken)) {
                    Write-Verbose "Missing Bitly Access Token. Trying Registry..."
                    $RegKey = 'HKCU:\Software\MyTwitter\Bitly'
                    if (!(Test-Path -Path $RegKey)) {
                        Write-Error "No Bitly Bitly Access Token found in registry. Run Set-BitlyAccesToken function"
                    } else {
                        $Values = 'BitlyAccessToken'
                        $Output = @{ }
                        foreach ($Value in $Values) {
                            if ((Get-Item $RegKey).GetValue($Value)) {
                                $Output.$Value = (Get-Item $RegKey).GetValue($Value)
                            } else {
                                $Output.$Value = ''
                            }
                        }
                        $BitlyAccessToken = $Output.BitlyAccessToken
                    }

                } else {
                    'Bitly Access Token parameter entered'
                }
                Write-Verbose "`$BitlyAccessToken = $BitlyAccessToken"
                #Check if http is present in url?
                if(!($URL -like "http*")){ $URL='http://' + $URL }
                # Make the call
                $BitlyURL=Invoke-WebRequest `
                    -Uri https://api-ssl.bitly.com/v3/shorten `
                    -Body @{access_token=$BitlyAccessToken; longURL=$URL } `
                    -Method Get

                #Get the elements from the returned JSON
                $Bitlyjson = $BitlyURL.Content | convertfrom-json 

                # Print out the shortened URL 
                $shortenedURL = $Bitlyjson.data.url 
            }

        }

        $BitlyAccessToken = $null
        return $shortenedURL;
    }
}