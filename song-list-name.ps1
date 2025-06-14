[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(Position=0)]
    [string]$dir="."
)

if($args.Length + $PSBoundParameters.Count -eq 0)
{
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptBasename = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    Write-Host -ForegroundColor Red "$scriptBasename -help"
    return
}

# 帮助命令，输出帮助提示
if($help)
{
    Write-Host @"
功能：批量输出歌曲名称，期望格式：歌手 - 歌名
参数：
    * dir     ：指定处理目录，默认为当前工作目录。
"@
    return
}

# 处理目录不存在
$isExist = (Test-Path $dir)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "指定的目录不存在：$dir"
}

(split-path $dir/* -leaf -Resolve) | ForEach-Object {
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($_)
    
    $parts = $basename -split ' - ', 2

    if($parts.Count -eq 2) {
        "$($parts[1])  $($parts[0])"
    } else {
        $_
    }
}