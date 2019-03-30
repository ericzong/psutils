#v1.0.3
<#
.Synopsis
    Batch operate the Git repositories under the specified folder
.DESCRIPTION
    Pull/Push all Git repositories under one folder
.EXAMPLE
    git-all
.EXAMPLE
    git-all push
.EXAMPLE
    git-all pull D:\parent\of\git\dirs
#>
param(
    [Parameter(Position=0)]
    [ValidateScript({$_ -eq "pull" -or $_ -eq "push"})]
    [string]$type="pull",
    [Parameter(Position=1)]
    [string]$dir="."
)

$currentPath=$PSScriptRoot
$dir=Resolve-Path $dir

if(-not (Test-Path $dir))
{
    Write-Error $dir "is not exist."
    Exit 1
}

Trap { cd $currentPath }

foreach($d in dir $dir -Directory)
{
    if(-not (Test-Path (Join-Path $d.FullName ".git")))
    {
        Write-Warning "Skip non-git project" ($d.Name) "..."
        continue
    }

    cd $d.FullName
    if($type -eq "pull")
    {
        Write-Host "Updating project" ($d.Name) "..."
        git.exe pull --progress
    }
    else
    {
        Write-Host "Push project" ($d.Name) "..."
        git.exe push --progress
    }
}

cd $currentPath
