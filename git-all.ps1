#v1.6.0

[CmdletBinding(DefaultParameterSetName="help")]
param(
    [Parameter(ParameterSetName="help")]
    [switch]$help,
    [Parameter(Position=0)]
    [ValidateSet('pull', 'push', 'seturl')]
    [string]$type="pull",
    [Parameter(Position=1)]
    [string]$dir=".",
    [string[]]$include = @(),
    [string[]]$exclude = @(),
    [string]$inFile,
    [string]$exFile,
    [switch]$all,
    [string[]]$replace
)

# ��������ʾ��������
if($args.Length + $PSBoundParameters.Count -eq 0)
{
    Write-Host -ForegroundColor Red "git-all -help �鿴����"
    return
}

# ����������������ʾ
if($help)
{
    Write-Host @"
���ܣ�
    ��������������ִ��ĳЩgit����Բ���ָ����Ŀ¼������/����git���ļ��С�
������
    * type    ��ִ�к���git������Ŀǰ������pull(*), push, seturl��
    * dir     ��ָ����Ŀ¼��Ĭ��Ϊ��ǰ����Ŀ¼��
    * include ��������git���ļ���ģʽ��
    * exclude ���ų���git���ļ���ģʽ��
    * inFile  ��������git���б��ļ���
    * exFile  ���ų���git���б��ļ���
    * all     ���Ƿ�������з�֧����type=pull|pushʱ��Ч��
    * replace ���滻Զ�ֿ̲�URL����type=seturlʱ��Ч��
ʾ����
    git-all push
    git-all pull parent\of\git\dirs
    git-all -include test.* -exclude pro.*
    git-all -inFile path\to\include-file.txt -exFile path\to\exclude-file.txt
    git-all seturl -replace old_url_pattern, replace_string
"@
    return
}

# �ж�ָ���ַ����Ƿ���ģʽ��������һƥ��
# name��ƥ���ַ���
# array��ģʽ����
function matchArray([string]$name, [string[]]$array)
{
    foreach($i in $array)
    {
        if($name -match $i)
        {
            return $true
        }
    }

    return $false
}

# �ж�ָ���ַ����Ƿ�ƥ���������������ɰ���ģʽ�������ų�ģʽ���鹲ͬȷ�����ų�����
# name��ƥ���ַ���
# include������ģʽ����
# exclude���ų�ģʽ����
function isInclude([string]$name, [string[]]$include, [string[]]$exclude) 
{
    if($exclude -and (matchArray $name $exclude))
    {
        return $false
    }

    if($include -and !(matchArray $name $include))
    {
        return $false
    }

    return $true
}

# �ж�git���Ƿ��з�֧
function hasBranches()
{
    $count = (git branch).count

    return ($count -gt 1)
}

$currentPath=$PWD
$dir=Resolve-Path $dir

if(-not (Test-Path $dir))
{
    Write-Error $dir "is not exist."
    Exit 1
}

$ErrorActionPreference='stop'
Trap 
{ 
    cd $currentPath
    break
}

if(-not ([String]::IsNullOrEmpty($inFile)) -and (Test-Path $inFile)) {
    $include = $include + (Get-Content $inFile)
}

if(-not ([String]::IsNullOrEmpty($exFile)) -and (Test-Path $exFile)) {
    $exclude = $exclude + (Get-Content $exFile)
}

$operationCount=0
$changeCount=0
$errorCount=0
foreach($d in dir $dir -Directory)
{
 
    if(-not (Test-Path (Join-Path $d.FullName ".git")))
    {
        Write-Verbose ("Skip non-git project $($d.Name)...")
        continue
    }
    if(!(isInclude $d $include $exclude))
    {
        Write-Warning "Filter out $($d.Name)" 
        continue
    }

    cd $d.FullName

    $isMultiBranch = hasBranches
    $text = $null
    $textBytes = $null
    if($type -eq 'pull') 
    {
        if($all -and $isMultiBranch) {
            $text = (git.exe pull --all --progress)
        } else {
            $text = (git.exe pull --progress)
        }

        if($text -contains 'Already up to date.')
        {
            Write-Verbose '------------------------------'
            Write-Verbose "project $($d.Name) up to date"
        }
        elseif($text -like 'fatal*')
        {
            $errorCount++
        }
        elseif(-not [String]::IsNullOrEmpty($text))
        {
            # convert to UTF8
            $textBytes = [text.Encoding]::Default.GetBytes($text)
            $text = [text.Encoding]::UTF8.GetString($textBytes)

            Write-Host "pull project $($d.Name) " -ForegroundColor DarkYellow
            Write-Host $text
            $changeCount++
        }
    } 
    elseif($type -eq 'push')
    {
        Write-Host "push project $($d.Name) " -ForegroundColor DarkYellow
        if($all -and $isMultiBranch) {
            git.exe push --all --progress
        } else {
            git.exe push --progress
        }
    }
    else
    {
        $oldUrl = (git remote get-url --all origin)
        $newUrl = $oldUrl -replace $replace
        Write-Host "set url project $($d.Name): $oldUrl -> $newUrl "
        git.exe remote set-url origin $newUrl
    }


    $operationCount++
}
if($operationCount -eq 0)
{
    Write-Warning "Operate no git repo"
}
elseif ($type -eq 'pull')
{
    Write-Warning "${changeCount}/${operationCount} changes, ${errorCount} errors"
}

cd $currentPath
