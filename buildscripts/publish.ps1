$ErrorActionPreference = 'Stop'

try {
    ## Don't upload the build scripts and appveyor.yml to PowerShell Gallery
    $tempmoduleFolderPath = "$env:Temp\MyTwitter"
    $null = mkdir $tempmoduleFolderPath

    ## Remove all of the files/folders to exclude out of the main folder
    $excludeFromPublish = @(
        'MyTwitter\\buildscripts'
        'MyTwitter\\tests'
        'MyTwitter\\appveyor\.yml'
        'MyTwitter\\\.git'
        'MyTwitter\\\.nuspec'
        'MyTwitter\\README\.md'
        'MyTwitter\\PesterSplitTweet\.gif'
    )
    $exclude = $excludeFromPublish -join '|'
    Get-ChildItem -Path $env:APPVEYOR_BUILD_FOLDER -Recurse | where { $_.FullName -match $exclude } | Remove-Item -Force -Recurse

    ## Publish module to PowerShell Gallery
    $publishParams = @{
        Path        = $env:APPVEYOR_BUILD_FOLDER
        NuGetApiKey = $env:nuget_apikey
        Repository  = 'PSGallery'
        Force       = $true
        Confirm     = $false
    }
    Publish-Module @publishParams

} catch {
    Write-Error -Message $_.Exception.Message
    $host.SetShouldExit($LastExitCode)
}