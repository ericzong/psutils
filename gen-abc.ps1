#v1.0.0
[CmdletBinding(DefaultParameterSetName="textInput")]
param(
    [Parameter(ParameterSetName="textInput", Position=0, Mandatory)]
    [string]$text,
    [Parameter(ParameterSetName="fileInput", Mandatory)]
    [string]$inputFile,
    [Parameter(ParameterSetName="textInput")]
    [Parameter(ParameterSetName="fileInput")]
    [switch]$upperCase
)

if($PSCmdlet.ParameterSetName -eq 'fileInput')
{
    $input = (Resolve-Path $inputFile -ErrorAction SilentlyContinue)
    # exception handler
    if(!$?)
    {
        Write-Error "Miss input file: $inputFile"
        Exit 1
    }
    $text=(Get-Content $input)
}

$start = 97;
$end = 122;
if($upperCase)
{
    $start = 65
    $end = 90
}

for($i = $start; $i -le $end; $i++)
{
    $abc = ([char][int]("0x00" + ($i).toString('X')))
    $outText = $ExecutionContext.InvokeCommand.ExpandString($text)
    Write-Output $outText
}
