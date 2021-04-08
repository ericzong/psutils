function getGitHubIp {
    $html = Invoke-WebRequest -URI https://github.com.ipaddress.com/
    $pattern = '(?<=<ul class="comma-separated"><li>)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    $ip = [regex]::matches($html, $pattern).groups[0].value

    return $ip
}

function overrideHosts {
    $hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
    $hostsText = Get-Content $hostsPath
    $hosts = $hostsText -split '\r\n'



    foreach($line in $hosts) {
        # Out-Host $line
        if(($line -match "^#") -or ($line -eq "")) {
            Out-File -FilePath E:/hosts.txt -Append -InputObject $line
        } else {
            $ipDomain = ($line -split "\t")
        }
    }
}