# v0.0.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(Position=0)]
    [string]$dir="."
)

# 不传参提示帮助命令
if($args.Length + $PSBoundParameters.Count -eq 0)
{
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptBasename = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    Write-Host -ForegroundColor Red "$scriptBasename -help 查看帮助"
    return
}

# 帮助命令，输出帮助提示
if($help)
{
    Write-Host @"
功能：批量创建歌词文件。
描述：为指定目录下的 .mp3 文件创建对应 .lrc 歌词文件。
    * dir     ：指定处理目录，默认为当前工作目录。
"@
    return
}


$isExist = (Test-Path $dir)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "指定的目录不存在：$dir"
}

Push-Location
Set-Location $dir
Get-ChildItem $dir -File -Filter *.mp3 | ForEach-Object `
{
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
    $lrcFilename = "$basename.lrc"
    $needCreat = -not (Test-Path $lrcFilename)
    
    if($needCreat)
    {
        Set-Content -Path "$basename.lrc" -Value "[00:00.00]"
        Write-Host -ForegroundColor Green "$lrcFilename 已创建"
    }
    else
    {
        Write-Host -ForegroundColor DarkYellow "$lrcFilename 已存在，跳过创建..."
    }
}

Pop-Location
