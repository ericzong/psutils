function getGitHubIp 
{
    $html = Invoke-WebRequest -URI https://github.com.ipaddress.com/
    $pattern = '(?<=<ul class="comma-separated"><li>)(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
    $ip = [regex]::matches($html, $pattern).groups[0].value

    return $ip
}

Function Edit-Hosts
{
    Start-Process notepad.exe -Verb runas -ArgumentList $env:windir\System32\drivers\etc\hosts -Wait
    ipconfig /flushdns | Out-Null
}

function overrideHosts 
{
    $gitHubIp = getGitHubIp
    $githubConfig = "$gitHubIp`tgithub.com"

    $hostsPath = 'C:\Windows\System32\drivers\etc\hosts'
    $hostsText = Get-Content $hostsPath
    $hostsText = ($hostsText -replace "$githubConfig",'')
    $hosts = $hostsText -split '`r`n'

    $outString = ""
    $firstConfig = $True
    foreach($line in $hosts) {
        if(($line -match "^#") -or ($line -eq "")) {
            $outString += "$line`r`n"
        } else {
            if($firstConfig) {
                $firstConfig = $False
                $outString += "$githubConfig`r`n"
            }
            
            $outString += "$line`r`n"
        }
    }

    Set-Clipboard $outString
    Edit-Hosts
}