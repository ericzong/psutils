#v1.2.8
<#
.SYNOPSIS
Batch operate the Git repositories under the specified folder
.DESCRIPTION
Pull/Push all Git repositories under one folder
.PARAMETER type
Git command. Git pull/push supported. Default: pull.
.PARAMETER dir
The root directory. 
All of sub-directories execute git command while it is the root of a git project. 
Default: active directory.
.PARAMETER include
The pattern of include directories.
.PARAMETER exclude
Then pattern of exclude directories.
.EXAMPLE
git-all
.EXAMPLE
git-all push
.EXAMPLE
git-all pull D:\parent\of\git\dirs
.EXAMPLE
git-all -include test.* -exclude pro.*
#>
[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateSet('pull', 'push')]
    [string]$type="pull",
    [Parameter(Position=1)]
    [string]$dir=".",
    [string[]]$include,
    [string[]]$exclude
)

function matchArray([string]$name, [string[]]$array)
{
    foreach($i in $array)
    {
        if($name -match $i)
        {
            return $true
        }
    }
}

function isInclude([string]$name, [string[]]$include, [string[]]$exclude) 
{
    if($exclude -and (matchArray $name $exclude))
    {
        return $false
    }

    if($include -and !(matchArray $name $include))
    {
        return $false
    }

    return $true
}

# encoding UTF-8
# $OutputEncoding = New-Object -typename System.Text.UTF8Encoding
chcp 65001

$currentPath=$PWD
$dir=Resolve-Path $dir

if(-not (Test-Path $dir))
{
    Write-Error $dir "is not exist."
    Exit 1
}

$ErrorActionPreference='stop'
Trap 
{ 
    cd $currentPath
    break
}

$operationCount=0
$changeCount=0
$errorCount=0
foreach($d in dir $dir -Directory)
{
    if(-not (Test-Path (Join-Path $d.FullName ".git")))
    {
        Write-Verbose ("Skip non-git project $($d.Name)...")
        continue
    }
    if(!(isInclude $d $include $exclude))
    {
        Write-Warning "Filter out $($d.Name)" 
        continue
    }

    cd $d.FullName

    if($type -eq 'pull') 
    {
        $text = (git.exe pull --progress)
        if($text -eq 'Already up to date.')
        {
            Write-Verbose '------------------------------'
            Write-Verbose "project $($d.Name) up to date"
        }
        elseif($text -like 'fatal*')
        {
            $errorCount++
        }
        else 
        {
            Write-Host "pull project $($d.Name) " -ForegroundColor DarkYellow
            Write-Host $text -
            $changeCount++
        }
    } 
    else 
    {
        Write-Host "push project $($d.Name) " -ForegroundColor DarkYellow
        git.exe push --progress
    }

    $operationCount++
}
if($operationCount -eq 0)
{
    Write-Warning "Operate no git repo"
}
elseif ($type -eq 'pull')
{
    Write-Warning "${changeCount}/${operationCount} changes, ${errorCount} errors"
}

cd $currentPath
