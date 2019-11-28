function Set-BitlyAPI {
    [CmdletBinding()]
    Param
    (
        # BitLy Login
        [Parameter(Mandatory=$true)]
        [string]$Login,

        # Bitly API Key 
        [Parameter(Mandatory=$true)]
        [string]$BitlyAPIKey,
        [switch]$Force
    )

    begin {
        $RegKey = 'HKCU:\Software\MyTwitter\Bitly'
    }
    process {
        #Bitly Login and API key are provided by Bitly application
        Write-Verbose "Checking registry to see if the Bitly Login and API Key  are already stored"
        if (!(Test-Path -Path $RegKey)) {
            Write-Verbose "No BitLy configuration found in registry. Creating one."
            New-Item -Path ($RegKey | Split-Path -Parent) -Name ($RegKey | Split-Path -Leaf) | Out-Null
        }
		
        $Values = 'Login', 'BitlyAPIKey'
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