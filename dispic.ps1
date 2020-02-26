#v1.0.0
<#
功能：分拣横向/纵向的图片。
参数：
  src - 需分拣的图片所在文件夹（不递归处理图片），默认为当前工作目录。
  hDir - 横向图片分拣到的文件夹，在 src 下，默认为 h。
  vDir - 纵向图片分拣到的文件夹，在 src 下，默认为 v。
  limit - 处理限制，图片最长边像素大于该值才进行分拣，默认为 1920。
输出：符合限制的横向/纵向图片分别拷贝到 hDir/vDir。
依赖：System.Drawing
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$src = ".",
  [Parameter()]
  [string]$hDir = "h",
  [Parameter()]
  [string]$vDir = "v",
  [Parameter()]
  [int32]$limit = 1920
)
# 数据预处理
$exts = @('.jpg', '.jpeg', '.png')
$src = Resolve-Path $src
$hDir = [System.IO.Path]::Combine($src, $hDir)
$vDir = [System.IO.Path]::Combine($src, $vDir)
# 引用库加载
[system.reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
# 环境预处理
if(![System.IO.Directory]::Exists($hDir)) {
  mkdir $hDir
}
if(![System.IO.Directory]::Exists($vDir)) {
  mkdir $vDir
}

$list = Get-ChildItem $src -File | 
  ? { $exts.Contains([IO.Path]::GetExtension($_)) }

  foreach($p in $list) {
    $pic = New-Object System.Drawing.Bitmap($p.FullName)
    $height = $pic.Height
    $width = $pic.Width
    $pic.Dispose()

    if($width -ge $height) { # 横向
      $max = $width
      $toDir = $hDir
    } else { # 纵向
      $max = $height
      $toDir = $vDir
    }

    if($max -gt $limit) {
      copy $p.FullName $toDir
    }
  }
