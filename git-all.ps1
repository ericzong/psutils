#v1.6.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(Position=0)]
    [ValidateSet('pull', 'push', 'seturl')]
    [string]$type="pull",
    [Parameter(Position=1)]
    [string]$dir=".",
    [string[]]$include = @(),
    [string[]]$exclude = @(),
    [string]$inFile,
    [string]$exFile,
    [switch]$all,
    [string[]]$replace
)

# 不传参提示帮助命令
if($args.Length + $PSBoundParameters.Count -eq 0)
{
    Write-Host -ForegroundColor Red "git-all -help 查看帮助"
    return
}

# 帮助命令，输出帮助提示
if($help)
{
    Write-Host @"
功能：
    本命令用以批量执行某些git命令，以操作指定根目录下所有/部分git库文件夹。
参数：
    * type    ：执行何种git操作，目前包括：pull(*), push, seturl。
    * dir     ：指定根目录，默认为当前工作目录。
    * include ：包括的git库文件夹模式。
    * exclude ：排除的git库文件夹模式。
    * inFile  ：包括的git库列表文件。
    * exFile  ：排除的git库列表文件。
    * all     ：是否操作所有分支，仅type=pull|push时有效。
    * replace ：替换远程仓库URL，仅type=seturl时有效。
示例：
    git-all push
    git-all pull parent\of\git\dirs
    git-all -include test.* -exclude pro.*
    git-all -inFile path\to\include-file.txt -exFile path\to\exclude-file.txt
    git-all seturl -replace old_url_pattern, replace_string
"@
    return
}

# 判断指定字符串是否与模式数组中任一匹配
# name：匹配字符串
# array：模式数组
function matchArray([string]$name, [string[]]$array)
{
    foreach($i in $array)
    {
        if($name -match $i)
        {
            return $true
        }
    }

    return $false
}

# 判断指定字符串是否被匹配包含，包含与否由包含模式数组与排除模式数组共同确定，排除优先
# name：匹配字符串
# include：包含模式数组
# exclude：排除模式数组
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

# 判断git库是否有分支
function hasBranches()
{
    $count = (git branch).count

    return ($count -gt 1)
}

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

if(-not ([String]::IsNullOrEmpty($inFile)) -and (Test-Path $inFile)) {
    $include = $include + (Get-Content $inFile)
}

if(-not ([String]::IsNullOrEmpty($exFile)) -and (Test-Path $exFile)) {
    $exclude = $exclude + (Get-Content $exFile)
}

$operationCount=0
$changeCount=0
$errorCount=0
foreach($d in dir $dir -Directory)
{
	Write-Host -ForegroundColor Green $d
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

    $isMultiBranch = hasBranches
    $text = $null
    $textBytes = $null
    if($type -eq 'pull') 
    {
        if($all -and $isMultiBranch) {
            $text = (git.exe pull --all --progress)
        } else {
            $text = (git.exe pull --progress)
        }

        if($text -contains 'Already up to date.')
        {
            Write-Verbose '------------------------------'
            Write-Verbose "project $($d.Name) up to date"
        }
        elseif($text -like 'fatal*')
        {
            $errorCount++
        }
        elseif(-not [String]::IsNullOrEmpty($text))
        {
            # convert to UTF8
            $textBytes = [text.Encoding]::Default.GetBytes($text)
            $text = [text.Encoding]::UTF8.GetString($textBytes)

            Write-Host "pull project $($d.Name) " -ForegroundColor DarkYellow
            Write-Host $text
            $changeCount++
        }
    } 
    elseif($type -eq 'push')
    {
        Write-Host "push project $($d.Name) " -ForegroundColor DarkYellow
        if($all -and $isMultiBranch) {
            git.exe push --all --progress
        } else {
            git.exe push --progress
        }
    }
    else
    {
        $oldUrl = (git remote get-url --all origin)
        $newUrl = $oldUrl -replace $replace
        Write-Host "set url project $($d.Name): $oldUrl -> $newUrl "
        git.exe remote set-url origin $newUrl
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
