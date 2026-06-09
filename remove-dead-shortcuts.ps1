#Requires -Version 5.1
<#
.SYNOPSIS
    删除目录下的失效快捷方式
.DESCRIPTION
    遍历指定目录（递归）中的所有 .lnk 快捷方式，检测目标是否有效，
    自动删除失效（目标不存在）的快捷方式。
.PARAMETER Path
    要扫描的目录路径
.PARAMETER WhatIf
    预览模式，仅显示将要删除的快捷方式，不实际删除
.PARAMETER Recurse
    是否递归扫描子目录，默认 $true
.EXAMPLE
    .\Remove-DeadShortcuts.ps1 "C:\Users\Public\Desktop"
.EXAMPLE
    .\Remove-DeadShortcuts.ps1 "C:\Users\Public\Desktop" -WhatIf
#>

param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "要扫描的目录路径")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [bool]$Recurse = $true
)

$shell = New-Object -ComObject WScript.Shell

$shortcuts = if ($Recurse) {
    Get-ChildItem -Path $Path -Filter "*.lnk" -Recurse -File -ErrorAction SilentlyContinue
} else {
    Get-ChildItem -Path $Path -Filter "*.lnk" -File -ErrorAction SilentlyContinue
}

$total = $shortcuts.Count
$dead  = 0
$alive = 0

foreach ($lnk in $shortcuts) {
    $target = $null
    try {
        $shortcut = $shell.CreateShortcut($lnk.FullName)
        $target   = $shortcut.TargetPath
    } catch {
        # 无法解析，视为失效
        $target = $null
    }

    $valid = $false
    if (-not [string]::IsNullOrWhiteSpace($target)) {
        # 支持 URI（无盘符路径，如 \\server\share）
        if ($target -match '^\\\\' -or $target -match '^[a-zA-Z]:') {
            $valid = Test-Path $target -PathType Any
        }
        # 也接受其他合法路径形式
        elseif (Test-Path $target -PathType Any -ErrorAction SilentlyContinue) {
            $valid = $true
        }
    }

    if (-not $valid) {
        $dead++
        if ($WhatIf) {
            Write-Host "[WhatIf] 将删除失效快捷方式: $($lnk.FullName)" -ForegroundColor Yellow
            if ($target) {
                Write-Host "       目标不存在: $target" -ForegroundColor DarkGray
            } else {
                Write-Host "       无法读取目标路径" -ForegroundColor DarkGray
            }
        } else {
            Write-Host "[删除] $($lnk.FullName)" -ForegroundColor Red
            if ($target) {
                Write-Host "       目标不存在: $target" -ForegroundColor DarkGray
            } else {
                Write-Host "       无法读取目标路径" -ForegroundColor DarkGray
            }
            Remove-Item -Path $lnk.FullName -Force
        }
    } else {
        $alive++
    }
}

Write-Host ""
Write-Host "========== 扫描完成 ==========" -ForegroundColor Cyan
Write-Host "总计快捷方式 : $total"
Write-Host "有效         : $alive"
Write-Host "失效（已删除）: $dead"
if ($WhatIf) { Write-Host "[WhatIf 模式] 未实际删除任何文件" -ForegroundColor Yellow }

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
[GC]::Collect()
