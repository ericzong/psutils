function Get-GitHub-Ip 
{
    $html = Invoke-WebRequest -URI https://github.com.ipaddress.com/
    $pattern = '(?<=<ul class="comma-separated"><li>)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    $ip = [regex]::matches($html, $pattern).groups[1].value

    return $ip
}

Function Edit-Hosts
{
    Start-Process notepad.exe -Verb runas -ArgumentList $env:windir\System32\drivers\etc\hosts -Wait
    ipconfig /flushdns | Out-Null
}

function GitHub-Hosts
{
    $gitHubIp = Get-GitHub-Ip 
    $githubConfig = "$gitHubIp`tgithub.com"

    Set-Clipboard $githubConfig
    Edit-Hosts
}