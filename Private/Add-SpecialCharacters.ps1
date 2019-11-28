function Add-SpecialCharacters {
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory)]
        [ValidateLength(1, 140)]
        [string] $Message
    )
    try {
        [string[]] $specialChar = @("!", "*", "'", "(", ")")
        for ($i = 0; $i -lt $specialChar.Length; $i++) {
            $Message = $Message.Replace($specialChar[$i], [System.Uri]::HexEscape($specialChar[$i]))
        }
        return $Message
    } catch {
        Write-Error $_.Exception.Message
    }
}