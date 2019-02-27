
param(
    [Parameter(Position=0)]
    $fromDir="."
)

$fromDir=Resolve-Path $fromDir
$toDir="C:\Users\$env:username\AppData\Roaming\Typora\themes"

# check dir
if(!(Test-Path $fromDir -PathType Container))
{
    Write-Error "$fromDir not exists"
    Exit 1
}
if(!(Test-Path $toDir -PathType Container))
{
    Write-Error "$toDir not exists"
    Exit 1
}

$baseFile="base.user.css"
$nightFile="night.user.css"

$bakBaseFile="base.user.css.bak"
$bakNightFile="night.user.css.bak"

$fromBaseCss=Join-Path $fromDir $baseFile
$fromNightCss=Join-Path $fromDir $nightFile

$toBaseCss=Join-Path $toDir $baseFile
$toNightCss=Join-Path $toDir $nightFile

$bakBaseCss=Join-Path $toDir $bakBaseFile
$bakNightCss=Join-Path $toDir $bakNightFile

# check file
if(Test-Path $toBaseCss -PathType Leaf)
{
    if(Test-Path $bakBaseCss -PathType Leaf)
    {
        del $bakBaseCss -Force
    }
    Rename-Item $toBaseCss $bakBaseCss
    Copy-Item $fromBaseCss $toBaseCss
}
if(Test-Path $toNightCss -PathType Leaf)
{
    if(Test-Path $bakNightCss -PathType Leaf)
    {
        del $bakNightCss -Force
    }
    Rename-Item $toNightCss $bakNightCss
    Copy-Item $fromNightCss $toNightCss
}