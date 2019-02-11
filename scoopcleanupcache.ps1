
if("$env:SCOOP" -eq "") {
    echo("There is no `$env:SCOOP, exiting!")
    return
}

$cache_dir="$env:SCOOP\cache"

$hasChange=""

foreach($file in dir $cache_dir)
{
    # delete temp file
    if($file.Extension -eq ".aria2" -or $file.Extension -eq ".txt") {
        Remove-Item $file.FullName -Force
        echo("[temp file] " + $file.FullName + " deleted")
        continue
    }

    $currentAppArray=$file.BaseName.Split("#")
    $currentAppName=$currentAppArray[0]
    $currentAppVer=$currentAppArray[1]
    if($currentAppName -eq $preAppName) {
        Remove-Item $preApp.FullName -Force
        echo("[old version] $currentAppName@$currentAppVer deleted")
        $hasChange="true"
    }
    
    $preAppName=$currentAppName
    $preApp=$file
}

if($hasChange -ne "true") {
    echo("No change")
}
