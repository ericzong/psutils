#v0.0.1
<#
.SYNOPSIS
Scoop proxy 设置工具
.DESCRIPTION
设置 Scoop & buckets 的代理
#>
[CmdletBinding(DefaultParameterSetName="help")]
param(
	[Parameter(ParameterSetName="help")]
    [switch]$help,
	[Parameter(Mandatory=$false)]
	[string]$proxyProtocol = "socks",
	[Parameter(Mandatory=$false)]
	[string]$proxyHost = "localhost",
	[Parameter(Mandatory=$false)]
	[string]$proxyPort = "10808"
)

if($help)
{
	Write-Host @"
功能：设置 scoop & buckets 的 git 配置 http.proxy
参数：
    * proxyProtocol：代理协议。默认值：socks
    * proxyHost：代理主机地址。默认值：localhost
    * proxyPort：代理端口。默认值：10808
    * 默认代理地址为：socks://localhost:10808
"@
	return
}

if(!(Test-Path -Path $env:scoop/buckets))
{
	Write-Host "未发现`$env:scoop配置"
	return
}

pushd
cd $env:scoop/buckets

$proxy = "${proxyProtocol}://${proxyHost}:$proxyPort"
Get-ChildItem -Directory | ForEach-Object {
	cd $_.FullName
	
	if (!((git remote -vv|findstr "(fetch)").Contains("github.com"))) {
		# GitHub bucket 需要代理加速，默认其他仓库不需要
		Write-Host -ForegroundColor Green "跳过 $($_.Name)，非 GitHub 仓库"
		return 
	}
	
	Write-Host -ForegroundColor DarkYellow "$($_.Name.PadRight(20))库代理已设置"
	git config --local --unset http.proxy
	git config --local http.proxy $proxy
}

cd $env:scoop/apps/scoop/current
Write-Host -ForegroundColor DarkYellow "$('scoop'.PadRight(20))　代理已设置"
git config --local --unset http.proxy
git config --local http.proxy $proxy

popd