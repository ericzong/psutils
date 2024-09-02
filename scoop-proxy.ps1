function ScoopProxy {
	param(
		[Parameter(Mandatory=$false)]
        [string]$proxyProtocol = "socks",
		[Parameter(Mandatory=$false)]
        [string]$proxyHost = "localhost",
		[Parameter(Mandatory=$false)]
        [string]$proxyPort = "10808"
	)

	if(!(Test-Path -Path $env:scoop/buckets))
	{
		Write-Host "未发现`$env:scoop配置"
		return
	}
	cd $env:scoop/buckets
	pushd

	$proxy = "${proxyProtocol}://${proxyHost}:$proxyPort"
	Get-ChildItem -Directory | ForEach-Object {
		cd $_.FullName
		if (!((git remote -vv|findstr "(fetch)").Contains("github.com"))) {
			Write-Host -ForegroundColor Green "跳过 $($_.Name)，非 GitHub 仓库"
		} else {
			Write-Host -ForegroundColor DarkYellow "设置代理 $($_.Name)" 
			git config --local --unset http.proxy
			git config --local http.proxy $proxy
		}
	}
	
	popd
	
	cd $env:scoop/apps/scoop/current
	Write-Host -ForegroundColor DarkYellow "设置代理 scoop"
	git config --local --unset http.proxy
	git config --local http.proxy $proxy
}