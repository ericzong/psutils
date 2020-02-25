[CmdletBinding()]
param(
  [Parameter()]
  [string]$src = ".",
  [Parameter()]
  [string]$hDir = "h",
  [Parameter()]
  [string]$vDir = "v"
)
# ����Ԥ����
$exts = @('.jpg', '.jpeg', '.png')
$src = Resolve-Path $src
$hDir = [System.IO.Path]::Combine($src, $hDir)
$vDir = [System.IO.Path]::Combine($src, $vDir)
# ��������
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

    if($max -gt 1920) {
      copy $p.FullName $toDir
    }
  }

