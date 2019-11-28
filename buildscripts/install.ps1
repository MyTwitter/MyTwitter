$ErrorActionPreference = 'Stop'

try {

    $provParams = @{
        Name           = 'NuGet'
        MinimumVersion = '2.8.5.208'
        Force          = $true
    }

    $null = Install-PackageProvider @provParams
    $null = Import-PackageProvider @provParams

    $requiredModules = @('PSPostMan')
    foreach ($m in $requiredModules) {
        Write-Host "Installing [$($m)] module..."
        Install-Module -Name $m -Force -Confirm:$false
        Write-Host "Removing [$($m)] module from current session..."
        Remove-Module -Name $m -Force -ErrorAction Ignore
        Write-Host "Importing [$($m)] module into current session..."
        Import-Module -Name $m
    }

} catch {
    Write-Error -Message $_.Exception.Message
    $host.SetShouldExit($LastExitCode)
}