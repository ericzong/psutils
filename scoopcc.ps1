
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

# delete temp file
Remove-Item (Join-Path $cacheDir *.txt) -Force
Remove-Item (Join-Path $cacheDir *.aria2) -Force

$hasChange=$false
foreach($file in dir $cacheDir -File)
{
    # skip temp files(deleted failed)
    if($file.Extension -eq ".aria2" -or $file.Extension -eq ".txt") {
        Write-Warning "Temp file[$txt] deleted failed."
        continue
    }

    $currentAppArray=$file.BaseName.Split("#")
    $currentAppName=$currentAppArray[0]
    $currentAppVer=$currentAppArray[1]
    if($currentAppName -eq $preAppName) {
        Remove-Item $preApp.FullName -Force
        Write-Host "[old version] $currentAppName@$currentAppVer deleted" -ForegroundColor Yellow
        $hasChange=$true
    }
    
    $preAppName=$currentAppName
    $preApp=$file
}

if(!$hasChange) {
    Write-Host "No change" -ForegroundColor Green
}
