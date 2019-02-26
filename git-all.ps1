
param(
    [Parameter(Mandatory=$true, Position=1)]
    $dir=".",
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({$_ -eq "pull" -or $_ -eq "push"})]
    $type="pull"
)

$dir=Resolve-Path $dir

if(-not (Test-Path $dir))
{
    Write-Error $dir "is not exist."
    Exit 1
}

foreach($d in dir $dir -Directory)
{
    if(-not (Test-Path (Join-Path $d.FullName ".git")))
    {
        Write-Warning "Skip non-git project" ($d.Name) "..."
        continue
    }

    cd $d.FullName
    if($type -eq "pull")
    {
        Write-Host "Updating project" ($d.Name) "..."
        git.exe pull --progress
    }
    else
    {
        Write-Host "Push project" ($d.Name) "..."
        git.exe push --progress
    }
}
