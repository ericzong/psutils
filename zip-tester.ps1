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
    
    #if(($length -gt 16) -and ($result[12] -ceq 'Everything is Ok')) {
    #  Write-Host "password is $password"
    #  $isFound = $true
    #  break
    #}
  }
}

if(-not $isFound) {
    Write-Host "password not found"
  }