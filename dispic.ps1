#v1.0.0
<#
���ܣ��ּ����/�����ͼƬ��
������
  src - ��ּ��ͼƬ�����ļ��У����ݹ鴦��ͼƬ����Ĭ��Ϊ��ǰ����Ŀ¼��
  hDir - ����ͼƬ�ּ𵽵��ļ��У��� src �£�Ĭ��Ϊ h��
  vDir - ����ͼƬ�ּ𵽵��ļ��У��� src �£�Ĭ��Ϊ v��
  limit - �������ƣ�ͼƬ������ش��ڸ�ֵ�Ž��зּ�Ĭ��Ϊ 1920��
������������Ƶĺ���/����ͼƬ�ֱ𿽱��� hDir/vDir��
������System.Drawing
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
# ����Ԥ����
$exts = @('.jpg', '.jpeg', '.png')
$src = Resolve-Path $src
$hDir = [System.IO.Path]::Combine($src, $hDir)
$vDir = [System.IO.Path]::Combine($src, $vDir)
# ���ÿ����
[system.reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
# ����Ԥ����
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

    if($width -ge $height) { # ����
      $max = $width
      $toDir = $hDir
    } else { # ����
      $max = $height
      $toDir = $vDir
    }

    if($max -gt $limit) {
      copy $p.FullName $toDir
    }
  }
