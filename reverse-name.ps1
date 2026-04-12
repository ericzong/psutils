<#
.SYNOPSIS
将文件名 "ABC - XYZ" 重命名为 "XYZ - ABC"
支持命令行参数传入路径，无参数时交互输入
#>

param(
    [string]$FilePath
)

# 如果没有传入参数，则提示输入
if (-not $FilePath) {
    $FilePath = Read-Host "请输入文件完整路径"
}

# 检查文件是否存在
if (-not (Test-Path $filePath -PathType Leaf)) {
    Write-Error "文件不存在：$filePath"
    pause
    exit
}

$file = Get-Item $filePath
$dir = $file.DirectoryName
$name = $file.BaseName
$ext = $file.Extension

# 匹配格式：任意内容 - 任意内容
if ($name -match '^(.*?)\s+-\s+(.*)$') {
    $part1 = $matches[1].Trim()
    $part2 = $matches[2].Trim()

    # 新文件名：XYZ - ABC
    $newBaseName = "$part2 - $part1"
    $newPath = Join-Path $dir "$newBaseName$ext"

    # 重命名
    Rename-Item -Path $filePath -NewName $newPath -Force
    Write-Host "✅ 重命名成功：$($file.Name) → $newBaseName$ext"
}
else {
    Write-Warning "文件名格式不符合 'ABC - XYZ'，已跳过"
}
