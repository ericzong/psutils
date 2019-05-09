#v1.0.2
<#
.SYNOPSIS
Scoop cache clear tool.
.DESCRIPTION
Clear scoop caches without lastest version.
#>
if([String]::IsNullOrEmpty($env:SCOOP))
{
    Write-Error 'There is no $env:SCOOP.'
    Exit 1
}

$cacheDir=Join-Path $env:SCOOP cache
if(!(Test-Path $cacheDir -PathType Container))
{
    Write-Error "Cache dir[$cacheDir] not exist."
    Exit 1
}

# temp file extensions
$tempExtList = $('.txt', '.aria2', '.download')

# delete temp file
foreach($ext in $tempExtList)
{
    Remove-Item (Join-Path $cacheDir "*.$ext") -Force
}

$hasChange=$false
foreach($file in dir $cacheDir -File)
{
    # skip temp files(deleted failed)
    if($tempExtList -contains $file.Extension) {
        Write-Warning "Temp file[$txt] deleted failed."
        continue
    }

    $currentAppArray=$file.BaseName.Split("#_")
    $currentAppName=$currentAppArray[0]
    $currentAppVer=$currentAppArray[1]
    if($currentAppName -eq $preAppName) {
        $preDate = $preApp.lastWriteTime
        $currentDate = $file.lastWriteTime
        if($preDate -lt $currentDate)
        {
            Remove-Item $preApp.FullName -Force
            Write-Host "[old version] $preAppName@$preAppVer deleted"

            $preAppVer=$currentAppVer
            $preApp=$file
        }
        else
        {
            Remove-Item $file.FullName -Force
            Write-Host "[old version] $currentAppName@$currentAppVer deleted"
        }
        
        $hasChange=$true
    } else {
        $preApp = $file
        $preAppName = $currentAppName
        $preAppVer = $currentAppVer
    }
}

if(!$hasChange) {
    Write-Host "No change" -ForegroundColor Green
}
