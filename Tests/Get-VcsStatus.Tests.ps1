$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ROOT\..\PSPowerLine.psm1"

#Unload posh-hg/svn/git if they exist, and load in our own shims in their place
Get-Module -Name posh-git | Remove-Module 
New-Module -Name posh-git  -ScriptBlock { 
    function Get-GitStatus {}
} | Import-Module -Force

Get-Module -Name posh-hg | Remove-Module 
New-Module -Name posh-hg  -ScriptBlock {
    function Get-HgStatus {}

    Export-ModuleMember -Function Get-HgStatus
} | Import-Module -Force

Get-Module -Name posh-svn | Remove-Module 
New-Module -Name posh-svn  -ScriptBlock {
    function Get-SvnStatus {}

    Export-ModuleMember -Function Get-SvnStatus
} | Import-Module -Force

Describe "When in a git repo with posh-git installed" {
    Mock -ModuleName PSPowerline Get-GitStatus { return $true; }
    
    Context "And neither posh-hg nor posh-svn are installed" {
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-hg is installed" {
        Mock -ModuleName PSPowerline Get-HgStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-svn is installed" {
        Mock -ModuleName PSPowerline Get-SvnStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-hg and posh-svn are installed" {
        Mock -ModuleName PSPowerline Get-SvnStatus { return $false; }
        Mock -ModuleName PSPowerline Get-HgStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
}

Describe "When in a hg repo with posh-hg installed" {
    Mock -ModuleName PSPowerline Get-HgStatus { return $true; }
    
    Context "And neither posh-git nor posh-svn are installed" {

        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-git is installed" {
        Mock -ModuleName PSPowerline Get-GitStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-svn is installed" {
        Mock -ModuleName PSPowerline Get-SvnStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-git and posh-svn are installed" {
        Mock -ModuleName PSPowerline Get-SvnStatus { return $false; }
        Mock -ModuleName PSPowerline Get-GitStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
}

Describe "When in a svn repo with posh-svn installed" {
    Mock -ModuleName PSPowerline Get-SvnStatus { return $true; }
    
    Context "And neither posh-git nor posh-hg are installed" {
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-git is installed" {
        Mock -ModuleName PSPowerline Get-GitStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-hg is installed" {
        Mock -ModuleName PSPowerline Get-HgStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
    
    Context "And posh-git and posh-hg are installed" {
        Mock -ModuleName PSPowerline Get-HgStatus { return $false; }
        Mock -ModuleName PSPowerline Get-GitStatus { return $false; }
        
        It "Returns a positive status" {
            Get-VcsStatus | Should Be $true
        }
    }
}