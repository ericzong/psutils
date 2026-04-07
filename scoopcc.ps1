#v1.1.0
<#
.SYNOPSIS
Scoop cache clear tool.
.DESCRIPTION
Clear scoop caches without lastest version.
.PARAMETER CleanPersist
If specified, also remove orphan directories in the persist folder
(i.e. apps that are no longer installed).
#>
param(
    [Alias('p')]
    [switch]$CleanPersist
)
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
    Remove-Item (Join-Path $cacheDir "*$ext") -Force
}

$hasChange=$false
foreach($file in dir $cacheDir -File)
{
    # skip temp files(deleted failed)
    if($tempExtList -contains $file.Extension) {
        Write-Warning "Temp file[$txt] deleted failed."
        continue
    }

    $currentAppArray=$file.BaseName.Split("#")
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

# ----- clean persist dir (-p) -----
if($CleanPersist) {
    $persistDir = Join-Path $env:SCOOP persist
    $appsDir    = Join-Path $env:SCOOP apps

    if(!(Test-Path $persistDir -PathType Container)) {
        Write-Warning "Persist dir[$persistDir] not exist, skip."
    } elseif(!(Test-Path $appsDir -PathType Container)) {
        Write-Warning "Apps dir[$appsDir] not exist, skip persist clean."
    } else {
        $persistHasChange = $false
        foreach($persistItem in Get-ChildItem $persistDir -Directory) {
            $appPath = Join-Path $appsDir $persistItem.Name
            if(!(Test-Path $appPath -PathType Container)) {
                Remove-Item $persistItem.FullName -Recurse -Force
                Write-Host "[persist] $($persistItem.Name) deleted (app not installed)" -ForegroundColor Yellow
                $persistHasChange = $true
            }
        }
        if(!$persistHasChange) {
            Write-Host "Persist: no orphan dirs found" -ForegroundColor Green
        }
    }
}
