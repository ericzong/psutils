#v1.0.0
<#
功能：使用解压密码字典测试压缩文件。
参数：
  zipFile - 压缩文件路径。
  dic - 解压密码字典文件。纯文本，每行一个解压密码。
输出：如果字典中有正确的密码则输出，否则输出未找到密码。
依赖：7zip，确保可以直接调用 7z 命令。
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory, Position=0)]
  [string]$zipFile,
  [Parameter(Mandatory, Position=1)]
  [string]$dic
)

$pwds = (Get-Content $dic)

$isFound = $false

$zipFile > $PSScriptRoot/zip-tester.log
foreach($password in $pwds) {
  ($result = (7z t $zipFile "-p$password")) *>>$PSScriptRoot/zip-tester.log

  $type = $result.getType().BaseType.Name
  if($type -ceq 'Array') {
    $length = $result.count

    foreach($i in $result) {
      if($i -ceq 'Everything is Ok') {
        Write-Host "password is $password"
        $isFound = $true
        break
      }
    }

    if($isFound) {
      break
    }
  }
}

if(-not $isFound) {
    Write-Host "password not found"
 }
