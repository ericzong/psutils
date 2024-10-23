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

# 不传参提示帮助命令
if($args.Length + $PSBoundParameters.Count -eq 0)
{
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptBasename = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    Write-Host -ForegroundColor Red "$scriptBasename -help 查看帮助"
    return
}

# 帮助命令，输出帮助提示
if($help)
{
    Write-Host @"
功能：指定输入文件，其格式是一行注音，一行文字，每两行转换为形如 <ruby>字<rt>zi</rt></ruby> 形式。
    * inputFile     ：输入文件
    * outputFile    ：输出文件
"@
    return
}

# 检查输入文件是否存在
if (Test-Path $inputFile) {
    # 读取文件内容
    $content = Get-Content -Path $inputFile

    # 初始化一个空字符串用于构建输出内容
    $outputContent = ''

    # 遍历文件内容，每次处理两行
    for ($i = 0; $i -lt $content.Length; $i += 2) {
        # 获取粤拼和粤语文本
        $jyutping = $content[$i].Trim()
        $yueyuText = $content[$i + 1].Replace(" ", "").Trim()

        # 分割粤拼和粤语文本为单个字符和对应的粤拼
        $jyutpingArray = $jyutping -split ' '
        $yueyuArray = $yueyuText.ToCharArray()

        # 检查长度是否匹配
        if ($jyutpingArray.Length -ne $yueyuArray.Length) {
            Write-Host "Warning: Jyutping and Yueyu text lengths do not match at line $(2*$i). $($jyutpingArray.Length) $($yueyuArray.Length)"
            continue
        }

        # 将构建的内容添加到输出内容字符串
		$outputContent += "<ruby>"
		
		for ($j = 0; $j -lt $jyutpingArray.Length; $j++)
		{
			$outputContent += "$($yueyuArray[$j])<rt>$($jyutpingArray[$j])</rt>"
		}
        
		$outputContent += "</ruby>`r`n"
    }

    # 将输出内容写入到输出文件
    $outputContent | Set-Content -Path $outputFile
} else {
    Write-Host "Input file not found."
}

