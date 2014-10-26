$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ROOT\..\PSPowerLine.psm1"

Describe "Get-Provider" {
    InModuleScope PSPowerline {
        if ($env:CI) {
            Mock -ModuleName PSPowerline Get-Home { return "c:/User/" }
        }
        
        Context "Determining the provider" {
            It "Should handle the FileSystem" {
                Get-Provider "C:\Windows\System32" | Should Be "FileSystem"
            }

            It "Should handle Cert:" {
                Get-Provider "Cert:\CurrentUser\CA" | Should Be "Certificate"
            }

            It "Should handle SMB shares" {
                Get-Provider "\\localhost\c$\Windows\System32" | Should Be "FileSystem"
            }

            It "Should handle the registry" {
                Get-Provider "HKLM:\SOFTWARE\Microsoft" | Should Be "Registry"
            }
        }
    }
}

Describe "UNC Shares" {
    InModuleScope PSPowerline {
        if ($env:CI) {
            Mock -ModuleName PSPowerline Get-Home { return "c:/User/" }
        }

        Context "When navigated to a UNC share" {
            It "Get-Drive returns the name of the share" {
                Get-Drive "Microsoft.PowerShell.Core\FileSystem::\\localhost\c$\Windows\System32" | Should be "\\localhost\c$\"
                Get-Drive "Microsoft.PowerShell.Core\FileSystem::\\localhost\c$" | Should be "\\localhost\c$\"
            }
            It "Shorten-Path returns all parts after the share name" {
                Shorten-Path "\\localhost\c$" | Should Be ""
                Shorten-Path "\\localhost\c$\Windows" | Should be "Windows"
                Shorten-Path "\\localhost\c$\Windows\System32" | Should be "Win\System32"
            }
        }
    }
}

Describe "Drive Directories" {
    InModuleScope PSPowerline {
        if ($env:CI) {
            Mock -ModuleName PSPowerline Get-Home { return "c:/User/" }
        }
        
        Context "When in the C:\Windows\system32 directory" {
            It "Get-Drive returns C:\" {
                Get-Drive "C:\Windows\System32" | Should be "C:\"
            }
            It "Shorten-Path returns all parts after the C:\" {
                mkdir "$($env:temp)\a" -ErrorAction Ignore
                Shorten-Path "C:\Windows\System32" | Should Be "Win\System32"   
            }
        }

        Context "Shorten-Path should handle short (<2) directory names" {
            It "Shorten-Path can handle short folder names" {
                mkdir "C:\fn" -ErrorAction Ignore
                mkdir "C:\fn\fn" -ErrorAction Ignore
                Shorten-Path "C:\fn\fn" | Should be "fn\fn"
            }
            rm "C:\fn\fn"
            rm "C:\fn" -ErrorAction Ignore
        }
    }
}

Describe "PowerShell non-FileSystem Providers" {
    InModuleScope PSPowerline {
        if ($env:CI) {
            Mock -ModuleName PSPowerline Get-Home { return "c:/User/" }
        }

        Context "When in the cert provider"{
            It "Get-Drive should return something" {
                Get-Drive "Cert:\CurrentUser\CA" | Should Be "Cert:\"
            }
            It "Shorten-Path should return the rest of the directory" {
                Shorten-Path "Cert:\CurrentUser\CA" | Should Be "CurrentUser\CA"
            }
        }
    }
}

Describe "Customizable shortened number of chars" {
    InModuleScope PSPowerline {
        if ($env:CI) {
            Mock -ModuleName PSPowerline Get-Home { return "c:/User/" }
        }

        Context "When in the C:\Windows\system32 directory with Num_Chars set to 2" {
            $orig = $global:PSPL:Num_Chars
            $global:PSPL:Num_Chars = 2
            It "Get-Drive returns C:\" {    
                Get-Drive "C:\Windows\System32" | Should be "C:\"
            }
            It "Shorten-Path returns all parts after the C:\" {
                mkdir "$($env:temp)\a" -ErrorAction Ignore
                Shorten-Path "C:\Windows\System32" | Should Be "Wi\System32"   
            }
            $global:PSPL:Num_Chars = $orig
        }    
    }
}   