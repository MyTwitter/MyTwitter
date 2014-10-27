<#
  Pester provides a framework for running Unit Tests to execute and validate PowerShell commands inside of PowerShell.
  More info can be found here: 
  https://github.com/pester/Pester

  To test run the following command:
  invoke-pester from ..\Pester\MyTwitter folder

#>

Remove-Module MyTwitter -Force -ErrorAction SilentlyContinue

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path
cd $scriptRoot
cd ..\..
Import-Module .\MyTwitter.psm1 -Force -ErrorAction Stop

#Variables:
$username = "sstranger"

Describe "Get-TweetTimeline" {
Context "Mandatory UserName parameter is provided" {
    It "outputs 'User screen_name properties'" {
                ((get-tweettimeline -Username $username -MaximumTweets 1).user).screen_name | Should Be "$username"
    }
  }
Context "MaxTweets parameter of more than 200 is entered." {
      It "fails" {
           { Get-TweetTimeline -MaximumTweets 201} | Should Throw
      }
  }

Context "no UserName parameter is provided. Hit enter during Pester test." {
      It "fails" {
           { Get-TweetTimeline } | Should Throw
      }
  }
}

cd $scriptRoot