function Get-TotalProcessMemory {
    <#
    .SYNOPSIS
    批量统计多个不同进程名的总物理内存占用
    .PARAMETER ProcessNames
    进程名数组，例如 @("chrome","qq","wechat")
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ProcessNames
    )

    $sumObj = Get-Process -Name $ProcessNames -ErrorAction SilentlyContinue |
        Measure-Object -Property WorkingSet64 -Sum

    [PSCustomObject]@{
        进程数量    = $sumObj.Count
        总内存MB  = [math]::Round($sumObj.Sum / 1MB, 2)
        总内存GB  = [math]::Round($sumObj.Sum / 1GB, 3)
    }
}