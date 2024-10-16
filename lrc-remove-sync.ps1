# v0.0.1

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(ParameterSetName="std", Position=0, Mandatory=$true)]
    [string]$inputFile,
    [Parameter(ParameterSetName="std", Position=1, Mandatory=$true)]
    [string]$outputFile
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
���ܣ��Ƴ�ָ�� .lrc ����ļ��е�ͬ����ǩ��
    * inputFile     �������ļ�
    * outputFile    ������ļ�
"@
    return
}

$isExist = (Test-Path $inputFile)
if(-not $isExist)
{
    Write-Host -ForegroundColor Red "ָ���������ļ������ڣ�$inputFile"
	return
}

# ������ʽ������ƥ��ʱ���ǩ��
$timeTagPattern = '<\d{2}:\d{2}\.\d{2}>'

$lines = Get-Content -Path $InputFile
$lines | ForEach-Object `
{
    Add-Content -Path $outputFile -Value ($_ -replace $timeTagPattern)
}
