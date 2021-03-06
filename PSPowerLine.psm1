##############################################################################
################################## Constants #################################
##############################################################################
$FANCY_SPACER = [char]11136
$GIT_BRANCH = [char]11104
$FANCY_X = [char]10008

$DRIVE_DEFAULT_COLOR = "gray"
$GIT_COLOR_DEFAULT = "green"

$global:PSPL:Num_Chars = 3

$colors = @{}
$colors["blue"] = ([ConsoleColor]::Cyan, [ConsoleColor]::DarkBlue)
$colors["green"] = ([ConsoleColor]::Green, [ConsoleColor]::DarkGreen)
$colors["cyan"] = ([ConsoleColor]::Cyan, [ConsoleColor]::DarkCyan)
$colors["red"] = ([ConsoleColor]::Red, [ConsoleColor]::DarkRed)
$colors["magenta"] = ([ConsoleColor]::Magenta, [ConsoleColor]::DarkMagenta)
$colors["yellow"] = ([ConsoleColor]::Yellow, [ConsoleColor]::DarkYellow)
$colors["gray"] = ([ConsoleColor]::White, [ConsoleColor]::DarkGray)
$driveColor = $DRIVE_DEFAULT_COLOR
##############################################################################
################################## Constants #################################
##############################################################################





##############################################################################
################################# Main Methods ###############################
##############################################################################
<#
.SYNOPSIS
Generates the prompt before each line in the console
#>
function Prompt { 
    $drive = (Get-Drive (Get-Location).Path)
    
    switch -wildcard ($drive){
        "C:\" { $driveColor = "blue" }
        "~\"  { $driveColor = "blue"}
        "\\*" { $driveColor = "magenta" }
    }

    $lastColor = $driveColor

    # PowerLine starts with a space
    if(-not (Vanilla-Window)){ Write-Colors $driveColor " "}

    # Writes the drive portion
    Write-Colors $driveColor "$drive"
    Write-Colors $driveColor (Shorten-Path (Get-Location).Path)
    Write-Colors $driveColor " "

    if(Vanilla-Window){ #use the builtin posh-output
        Write-VcsStatus
    } else { #get ~fancy~
        $status = Get-VCSStatus
        if ($status) {
            $lastColor = Write-Fancy-Vcs-Branches($status);
        }
    }

    # Writes the postfix to the prompt
    if(Vanilla-Window) { 
        Write-Host -Object ">" -n 
    } else {
        Write-Colors $lastColor $FANCY_SPACER -invert -noB 
    }

    return " " 
} 
##############################################################################
################################# Main Methods ###############################
##############################################################################




##############################################################################
################################ Helper Methods ##############################
##############################################################################

function Get-VCSStatus{
    $status = $null
    $vcs_systems = @{"posh-git"  = "Get-GitStatus"; 
                     "posh-hg"   = "Get-HgStatus";
                     "posh-svn"  = "Get-SvnStatus"
                    }

    foreach ($key in $vcs_systems.Keys) {
        $module = Get-Module -Name $key;
        if($module -and @($module).Count -gt 0){
            $status = (Invoke-Expression -Command ($vcs_systems[$key]));
            if ($status) {
                return $status
            }
        }
    }
    return $status
}


function Write-Fancy-Vcs-Branches($status) {
    if ($status) {
        $color = $GIT_COLOR_DEFAULT

        # Determine Colors
        $localChanges = ($status.HasIndex -or $status.HasUntracked -or $status.HasWorking); #Git flags
        $localChanges = $localChanges -or (($status.Untracked -gt 0) -or ($status.Added -gt 0) -or ($status.Modified -gt 0) -or ($status.Deleted -gt 0) -or ($status.Renamed -gt 0)); #hg/svn flags

        if($localChanges) { $color = "yellow"}
        if(-not ($localChanges) -and ($status.AheadBy -gt 0)){ $color = "cyan" } #only affects git     
        
        Write-Host -Object $FANCY_SPACER -ForegroundColor $colors[$driveColor][1] -BackgroundColor $colors[$color][1] -NoNewline
        Write-Colors $color " $GIT_BRANCH $($status.Branch) "
        return $color
    }
}

function Write-Colors{
    param(
        [Parameter(Mandatory=$True)][string]$color,
        [string]$message,
        [switch]$newLine,
        [switch]$invert,
        [switch]$noBackground
    )

    if(-not $colors[$color]){
        throw "Not a valid color: $color"
    }

    $noBackground = ($noBackground -or (Vanilla-Window))

    $FG = 0
    $BG = 1
    if($invert){
        $FG = 1
        $BG = 0
    }


    if(-not ($noBackground)){
        Write-Host -Object $message -ForegroundColor $colors[$color][$FG] -BackgroundColor $colors[$color][$BG] -NoNewline
    } else {
        Write-Host -Object $message -ForegroundColor $colors[$color][$FG] -NoNewline
    }

    if($newLine) { Write-Host -Object "" }
}



function Vanilla-Window{
    if($env:PROMPT -or $env:ConEmuANSI){
        # Console
        return $false
    } else {
        # Powershell
        return $true
    }
}

function Get-Home 
{
    return $HOME;
}


function Get-Provider( [string] $path ){
    return (Get-Item $path).PSProvider.Name
}



function Get-Drive( [string] $path ) {
    $provider = Get-Provider $path

    if($provider -eq "FileSystem"){
        $homedir = Get-Home;
        if( $path.StartsWith( $homedir ) ) {
            return "~\"
        } elseif( $path.StartsWith( "Microsoft.PowerShell.Core" ) ){
            $parts = $path.Replace("Microsoft.PowerShell.Core\FileSystem::\\","").Split("\")
            return "\\$($parts[0])\$($parts[1])\"
        } else {
            $root = (Get-Item $path).Root
            if($root){
                return $root
            } else {
                return $path.Split(":\")[0] + ":\"
            }
        }
    } else {
        return (Get-Item $path).PSDrive.Name + ":\"
    } 
}

function Is-VCSRoot( $dir ) {
    return (Get-ChildItem -Path $dir.FullName -force .git) `
       -Or (Get-ChildItem -Path $dir.FullName -force .hg) `
       -Or (Get-ChildItem -Path $dir.FullName -force .svn) `
}

function Shorten-Path([string] $path) {
    $provider = Get-Provider $path

    if($provider -eq "FileSystem"){
        $result = @()
        $dir = Get-Item $path

        while( ($dir.Parent) -And ($dir.FullName -ne $HOME) ) {

            if( (Is-VCSRoot $dir) -Or ($result.length -eq 0) ) {
                $result = ,$dir.Name + $result
            } else {
                if($dir.Name.length -gt $global:PSPL:Num_Chars){
                   $result = ,$dir.Name.Substring(0, $global:PSPL:Num_Chars) + $result
                } else {
                    $result = ,$dir.Name + $result
                }
            }

            $dir = $dir.Parent
        }
        return $result -join "\"
    } else {
        return $path.Replace((Get-Drive $path), "") 
    }

}


function Colors {
    Write-Host -Object "INDIVIDUAL COLORS"
    [ConsoleColor].DeclaredMembers | Select-Object -Property Name `
        | Where-Object {$_.Name -ne "value__" } `
        | ForEach-Object {
            Write-Host -Object $_.Name -ForegroundColor $_.Name
        }

    Write-Host
    Write-Host -Object "NAMED PAIRS"
    $colors.Keys | ForEach-Object {
        Write-Host -Object " $_ " `
            -ForegroundColor $colors[$_][0] `
            -BackgroundColor $colors[$_][1]
    }
}
##############################################################################
################################ Helper Methods ##############################
##############################################################################

Export-ModuleMember -Function Prompt