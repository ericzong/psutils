# v0.0.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(Position=0)]
    [string]$dir="."
)

# ��������ʾ��������
if($args.Length + $PSBoundParameters.Count -eq 0)
{
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptBasename = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    Write-Host -ForegroundColor Red "$scriptBasename -help �鿴����"
    return
}

# ����������������ʾ
if($help)
{
    Write-Host @"
���ܣ�������������ļ���
������Ϊָ��Ŀ¼�µ� .mp3 �ļ�������Ӧ .lrc ����ļ���
    * dir     ��ָ������Ŀ¼��Ĭ��Ϊ��ǰ����Ŀ¼��
"@
    return
}


$isExist = (Test-Path $dir)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "ָ����Ŀ¼�����ڣ�$dir"
}

Push-Location
Set-Location $dir
Get-ChildItem $dir -File -Filter *.mp3 | ForEach-Object `
{
    $basename = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
    $lrcFilename = "$basename.lrc"
    $needCreat = -not (Test-Path $lrcFilename)
    
    if($needCreat)
    {
        Set-Content -Path "$basename.lrc" -Value "[00:00.00]"
        Write-Host -ForegroundColor Green "$lrcFilename �Ѵ���"
    }
    else
    {
        Write-Host -ForegroundColor DarkYellow "$lrcFilename �Ѵ��ڣ���������..."
    }
}

Pop-Location
