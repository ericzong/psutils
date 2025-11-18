# 定义Scoop的persist目录和已安装应用列表的路径
$scoopPersistDir = "$env:scoop\persist"
$scoopInstalled = scoop list | Select-Object -ExpandProperty Name

# 获取persist目录中的所有子文件夹名称
$persistSubDirs = Get-ChildItem -Path $scoopPersistDir -Directory | Select-Object -ExpandProperty Name

# 找出那些在persist目录中存在，但当前未安装的应用对应的文件夹
$orphanedPersistDirs = $persistSubDirs | Where-Object { $_ -notin $scoopInstalled }

# 如果没有找到残留数据，则提示并退出
if (-not $orphanedPersistDirs) {
    Write-Host "恭喜！未发现已卸载应用的persist残留数据。" -ForegroundColor Green
    exit
}

# 显示找到的残留数据文件夹
Write-Host "发现以下已卸载应用的persist文件夹：" -ForegroundColor Yellow
$orphanedPersistDirs | ForEach-Object { Write-Host "  $_" }

# 确认是否删除
$confirmation = Read-Host "是否要删除以上所有残留的persist数据？(y/N)"
if ($confirmation -eq 'y') {
    $orphanedPersistDirs | ForEach-Object {
        $dirToRemove = Join-Path $scoopPersistDir $_
        try {
            Remove-Item -Path $dirToRemove -Recurse -Force -ErrorAction Stop
            Write-Host "已删除: $_" -ForegroundColor Green
        } catch {
            Write-Host "删除失败: $_ - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-Host "清理操作完成。" -ForegroundColor Green
} else {
    Write-Host "已取消操作。" -ForegroundColor Gray
}