function getGitHubIp {
    $html = Invoke-WebRequest -URI https://github.com.ipaddress.com/
    $pattern = '(?<=<ul class="comma-separated"><li>)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    $ip = [regex]::matches($html, $pattern).groups[0].value

    return $ip
}

function overrideHosts {
    $hostsText = Get-Content C:\Windows\System32\drivers\etc\hosts
    $hosts = $hostsText -split '\r\n'
    foreach($line in $hosts) {
        Write-Host $line
    }
}