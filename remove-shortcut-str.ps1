# v0.0.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(ParameterSetName="std", Position=0, Mandatory=$true)]
    [string]$file
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
功能：重命名，移除指定 .lnk 快捷方式文件的中“快捷方式”字样
    * file     ：输入文件
"@
    return
}

$isExist = (Test-Path $file)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "指定的输入文件不存在：$file"
	return
}

$isLnk = $file.EndsWith(".lnk")
if(-not $isLnk)
{
	Write-Host -ForegroundColor Red "指定的文件不是快捷方式(.lnk)：$file"
	
}

Rename-Item -Path $file -NewName ($file -replace "\.\w{3,4} - 快捷方式")