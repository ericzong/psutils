# Obsidian 插件配置文件备份脚本
# 功能：备份指定插件根目录下所有插件的 data.json 文件到目标目录，保留目录结构
# 参数：
#   - PluginRoot (必需): Obsidian 插件根目录（例如：.obsidian/plugins）
#   - BackupDir (可选): 备份目录，默认为当前工作目录

param(
    [Parameter(Mandatory=$true)]
    [string]$PluginRoot,
    
    [string]$BackupDir = $PWD
)

# 验证插件根目录是否存在
if (-not (Test-Path -Path $PluginRoot -PathType Container)) {
    Write-Error "错误：插件根目录不存在 - $PluginRoot"
    exit 1
}

# 创建备份目录（如果不存在）
if (-not (Test-Path -Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "已创建备份目录：$BackupDir"
}

# 递归获取所有 data.json 文件[6,8](@ref)
$dataJsonFiles = Get-ChildItem -Path $PluginRoot -Filter "data.json" -Recurse -File

if ($dataJsonFiles.Count -eq 0) {
    Write-Host "未在插件根目录下找到任何 data.json 文件。"
    exit 0
}

Write-Host "正在备份 $($dataJsonFiles.Count) 个 data.json 文件..."

# 遍历每个 data.json 文件并复制到备份目录[3](@ref)
foreach ($file in $dataJsonFiles) {
    # 计算相对于插件根目录的路径
    $relativePath = $file.FullName.Substring($PluginRoot.Length).TrimStart('\', '/')
    $targetPath = Join-Path -Path $BackupDir -ChildPath $relativePath
    $targetDir = Split-Path -Path $targetPath -Parent

    # 创建目标插件目录（如果不存在）
    if (-not (Test-Path -Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # 复制 data.json 文件
    Copy-Item -Path $file.FullName -Destination $targetPath -Force
    Write-Host "已备份: $relativePath"
}

Write-Host "备份完成！所有文件已保存到: $BackupDir" -ForegroundColor Green