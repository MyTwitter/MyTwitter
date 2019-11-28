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
$Message = "This is an example tweet for testing purposes. And here are some words to replace: two, and, One, at, too"
Describe "Resize-Tweet" {
  Context "Message parameter is provided" {
    It "outputs 'Rezize tweet'" {
                (Resize-tweet -message $Message).Message | Should Be "This is an example tweet 4 testing purposes. & here are some words 2 replace: 2, &, 1, @, 2"
    }
  }


  Context "no Message parameter is provided. Hit enter during Pester test." {
      It "fails" {
           { Resize-Tweet } | Should Throw
      }
  }

  It "outputs 'Test pipeline input Rezise-Tweet'" {
                (Resize-tweet -message $Message).message | Should Be "This is an example tweet 4 testing purposes. & here are some words 2 replace: 2, &, 1, @, 2"
    }
}




cd $scriptRoot