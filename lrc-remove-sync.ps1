# v0.0.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(ParameterSetName="std", Position=0, Mandatory=$true)]
    [string]$inputFile,
    [Parameter(ParameterSetName="std", Position=1, Mandatory=$true)]
    [string]$outputFile
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
功能：移除指定 .lrc 歌词文件中的同步标签。
    * inputFile     ：输入文件
    * outputFile    ：输出文件
"@
    return
}

$isExist = (Test-Path $inputFile)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "指定的输入文件不存在：$inputFile"
	return
}

# 正则表达式，用于匹配时间标签行
$timeTagPattern = '<\d{2}:\d{2}\.\d{2}>'

$lines = Get-Content -Path $InputFile
$lines | ForEach-Object `
{
    Add-Content -Path $outputFile -Value ($_ -replace $timeTagPattern)
}
