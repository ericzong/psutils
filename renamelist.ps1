#v1.0.0
# Issue-001*: 列表文件数与目录中文件数不匹配检查
# Issue-002*: 文件名合法性检查
# Issue-003*: $dir参数默认为当前工作目录
# Issue-004*: 条件检查抛异常
# Issue-005*: 重命名前要求确认
# Issue-006*: 重命令列表重名检测
# Issue-007*: 重命名前列出

[CmdletBinding(DefaultParameterSetName="A")]
param(
    [Parameter(ParameterSetName="A", Mandatory=$true, Position=0)]
    [Parameter(ParameterSetName="B", Mandatory=$true, Position=0)]
    $listfile,
    [Parameter(ParameterSetName="B", Mandatory=$true, Position=1)]
    $dir=".",
    [Switch]
    $quiet
)

# check parameters
if([String]::IsNullOrEmpty($dir) `
    -or [String]::IsNullOrEmpty($listfile) `
    -or !(Test-Path $dir -PathType Container) `
    -or !(Test-Path $listfile -PathType Leaf))
{
    Write-Error params -dir and -listfile should be assigned and exist
    Exit 1
}

# convert relative path to abusolute path
$dir=Resolve-Path $dir
$listfile=Resolve-Path $listfile

# filter directories and blank line
$files=(dir $dir -File)
$lines=(Get-Content $listfile | Where-Object {$_.trim() -ne ""})

# check count
if($files.Count -ne $lines.Count)
{
    Write-Error Count mismatch, file count $files.Count but list count $lines.Count
    Exit 1
}

# check filename
foreach($filename in $lines)
{
    if($filename -match "[\\/:*?`"<>|]")
    {
        Write-Error $filename maybe contains illegal characters: "\ / : * ? `" < > |"
        Exit 1
    }
}

# check duplicate filename
$uniqueLines=($lines | Select-Object -Unique)
if(!($lines.Count -eq $uniqueLines.Count))
{
    Write-Error "Duplicate filename found"
    Exit 1
}

# list file
if(!$quiet)
{
    $i=0
    $files.ForEach({
        $toFilename=$lines[$i++] + $_.Extension
        write-host $_.Name "->" $toFilename -ForegroundColor Magenta
    })
}

# confirm
if(!$quiet -and !((Read-Host "Confirm? Y to continue, or cancel...") -eq 'Y'))
{
    Write-Warning "You chose to cancel!"
    Exit 0
}

$i=0
$files.ForEach({
    $toFilename=$lines[$i++] + $_.Extension
    write-host $_.Name "->" $toFilename -ForegroundColor Green
    Rename-Item $_.FullName ([io.path]::Combine($dir, $toFilename))
})
