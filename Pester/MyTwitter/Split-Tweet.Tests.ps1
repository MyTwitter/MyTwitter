<#
  Pester provides a framework for running Unit Tests to execute and validate PowerShell commands inside of PowerShell.
  More info can be found here: 
  https://github.com/pester/Pester

  To test run the following command:
  invoke-pester from ..\Pester\MyTwitter folder

#>

Import-Module MyTwitter

#Variables:
$Message = "This is a very long message that needs to be splitted because it's too long for the max twitter characters. Hope you like my new split-tweet function."

Describe "Split-Tweet" {
    It "outputs 'Split tweet'" {
                (split-tweet -message $message).message[0] | Should Match "^This*"
    }

    It "outputs 'No need to split tweet'" {
                split-tweet -message "This is a short message" | Should Be $null
    }

    It "outputs 'Split tweet into 2 messages'" {
                (split-tweet -message $message).count | Should Be 2
    }

    It "outputs 'Test pipeline input Split-Tweet'" {
                (split-tweet -message $message).message[0] | Should Match "^This*"
    }
}