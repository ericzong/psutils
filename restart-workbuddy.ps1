# restart-workbuddy.ps1  (v4)
#
# Restart WorkBuddy and make the NEW instance independent of whatever launched this script.
#
# Design notes:
#   1. Self-guard: aborts (exit 2) if WorkBuddy.exe appears in its own ancestor chain.
#      Running this from a terminal owned by WorkBuddy = suicide (kills the app AND this script).
#   2. Detached relaunch with 3 fallbacks: WMI create -> explorer -> Start-Process.
#      WMI/explorer make the child a child of WmiPrvSE.exe / explorer.exe, outside this
#      process tree and outside any console job object, so closing a terminal cannot kill it.
#   3. Explicit exit codes; never blocks on console input.
#
# HOW TO RUN (must be from OUTSIDE WorkBuddy):
#   - Windows Task Scheduler  (recommended)
#   - zTasker
#   - schtasks /run /tn "<task name>"    <- async, returns at once, no terminal involved
#
# LOG PATH (-LogPath), resolution order:
#   1. -LogPath <file or dir>   explicit   -> use it
#   2. $env:WORKBUDDY_RESTART_LOG         -> use it (handy for Task Scheduler env setup)
#   3. <script dir>\logs\restart-workbuddy.log
#   4. %TEMP%\restart-workbuddy.log       (fallback when script dir is not writable)
#   A directory (existing, or path ending in \) gets restart-workbuddy.log appended.
#   Log rotates to *.1.log when it exceeds -MaxLogKB.
#
# EXAMPLES
#   powershell -NoProfile -ExecutionPolicy Bypass -File restart-workbuddy.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File restart-workbuddy.ps1 -LogPath "D:\logs\wb.log"
#   powershell -NoProfile -ExecutionPolicy Bypass -File restart-workbuddy.ps1 -LogPath "D:\logs"
#   powershell -NoProfile -ExecutionPolicy Bypass -File restart-workbuddy.ps1 -Force -MaxLogKB 512
#
# Exit codes: 0 = ok | 1 = exe not found | 2 = aborted (ran from inside WorkBuddy) | 3 = relaunch failed

[CmdletBinding()]
param(
    [string]$LogPath,                # log file or directory; overrides env var and defaults
    [int]$MaxLogKB = 512,            # rotate when log exceeds this size; 0 = never rotate
    [switch]$Force,                  # skip graceful close, kill immediately
    [switch]$AllowInsideApp,         # override the self-guard (NOT recommended)
    [switch]$Quiet                   # do not write the log file at all
)

$ErrorActionPreference = 'SilentlyContinue'
$exe = Join-Path $env:LOCALAPPDATA 'Programs\WorkBuddy\WorkBuddy.exe'

# ---------- log path resolution -------------------------------------------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }

function Resolve-LogFile {
    param([string]$Requested, [string]$Dir, [switch]$Skip)

    if ($Skip) { return $null }

    $defaultName = 'restart-workbuddy.log'
    $candidates = @()

    if ($Requested) {
        if (Test-Path -LiteralPath $Requested -PathType Container) {
            $candidates += (Join-Path $Requested $defaultName)
        } elseif ($Requested.EndsWith('\') -or $Requested.EndsWith('/')) {
            $candidates += (Join-Path $Requested $defaultName)
        } elseif ((Split-Path -Leaf $Requested) -match '\.') {
            $candidates += $Requested
        } else {
            $candidates += (Join-Path $Requested $defaultName)
            $candidates += $Requested
        }
    }

    if ($env:WORKBUDDY_RESTART_LOG) {
        if (Test-Path -LiteralPath $env:WORKBUDDY_RESTART_LOG -PathType Container) {
            $candidates += (Join-Path $env:WORKBUDDY_RESTART_LOG $defaultName)
        } else {
            $candidates += $env:WORKBUDDY_RESTART_LOG
        }
    }

    $candidates += (Join-Path (Join-Path $Dir 'logs') $defaultName)
    $candidates += (Join-Path $Dir $defaultName)
    $candidates += (Join-Path $env:TEMP $defaultName)

    foreach ($c in $candidates) {
        try {
            $parent = Split-Path -Parent $c
            if ($parent -and -not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }
            # probe writability
            Add-Content -LiteralPath $c -Value '' -Encoding UTF8 -ErrorAction Stop
            $content = Get-Content -LiteralPath $c -Raw -ErrorAction SilentlyContinue
            if ($null -eq $content -or $content -eq '') {
                Set-Content -LiteralPath $c -Value '' -Encoding UTF8 -ErrorAction Stop
            }
            return $c
        } catch { }
    }
    return $null
}

$log = Resolve-LogFile -Requested $LogPath -Dir $scriptDir -Skip:$Quiet

function Write-Log([string]$msg) {
    if (-not $log) { return }
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    try {
        if ($MaxLogKB -gt 0 -and (Test-Path -LiteralPath $log)) {
            if ((Get-Item -LiteralPath $log).Length -gt ($MaxLogKB * 1024)) {
                Move-Item -LiteralPath $log -Destination ($log -replace '\.log$', '.1.log') -Force
            }
        }
        Add-Content -LiteralPath $log -Value $line -Encoding UTF8
    } catch { }
}

# ---------- process helpers -----------------------------------------------------
function Get-WorkBuddy {
    Get-Process -Name 'WorkBuddy' -ErrorAction SilentlyContinue | Where-Object {
        (-not $_.Path) -or ($_.Path -eq $exe)
    }
}

function Get-AncestorNames {
    $names = New-Object System.Collections.Generic.List[string]
    $cur = $PID
    for ($i = 0; $i -lt 12; $i++) {
        $me = Get-CimInstance Win32_Process -Filter "ProcessId = $cur" -ErrorAction SilentlyContinue
        if (-not $me -or -not $me.ParentProcessId -or $me.ParentProcessId -eq 0) { break }
        $cur = [int]$me.ParentProcessId
        $par = Get-CimInstance Win32_Process -Filter "ProcessId = $cur" -ErrorAction SilentlyContinue
        if (-not $par) { break }
        $names.Add($par.Name)
    }
    return $names
}

# ---------- run ----------------------------------------------------------------
Write-Log '=== restart start (v4) ==='
Write-Log ('log file: {0}' -f $log)

if (-not (Test-Path -LiteralPath $exe)) {
    Write-Log "ERROR: exe not found: $exe"
    exit 1
}

if (-not $AllowInsideApp) {
    $anc = Get-AncestorNames
    Write-Log ('ancestors: {0}' -f ($anc -join ' < '))
    if ($anc -contains 'WorkBuddy.exe') {
        Write-Log 'ABORT: running INSIDE WorkBuddy. Killing the app would kill this script.'
        Write-Log '       Trigger from Task Scheduler / zTasker / schtasks instead.'
        exit 2
    }
}

$running = Get-WorkBuddy
if ($running) {
    Write-Log ('running: {0}' -f (($running | ForEach-Object { $_.Id }) -join ','))

    if ($Force) {
        Write-Log 'force kill (requested)'
        $running | Stop-Process -Force
        Start-Sleep -Seconds 3
    } else {
        $running | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object {
            Write-Log ('CloseMainWindow -> PID {0}' -f $_.Id)
            try { $_.CloseMainWindow() | Out-Null } catch { }
        }

        $graceful = $false
        for ($i = 0; $i -lt 15; $i++) {
            Start-Sleep -Seconds 1
            if (-not (Get-WorkBuddy)) { $graceful = $true; break }
        }

        if ($graceful) {
            Write-Log 'closed gracefully'
        } else {
            $left = Get-WorkBuddy
            Write-Log ('force kill remaining: {0}' -f (($left | ForEach-Object { $_.Id }) -join ','))
            $left | Stop-Process -Force
            Start-Sleep -Seconds 3
        }
    }
} else {
    Write-Log 'no running instance'
}

# ---- start, detached ----------------------------------------------------------
$launcher = $null
$quoted = '"{0}"' -f $exe

try {
    $r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $quoted }
    if ($r -and $r.ReturnValue -eq 0) {
        $launcher = 'wmi'
        Write-Log ('launch via WMI ok, new PID {0} (parent WmiPrvSE.exe)' -f $r.ProcessId)
    } else {
        Write-Log ('WMI create returned {0}' -f $(if ($r) { $r.ReturnValue } else { 'null' }))
    }
} catch {
    Write-Log ('WMI create threw: {0}' -f $_.Exception.Message)
}

if (-not $launcher) {
    try {
        Start-Process -FilePath 'explorer.exe' -ArgumentList $quoted
        Start-Sleep -Seconds 3
        if (Get-WorkBuddy) { $launcher = 'explorer'; Write-Log 'launch via explorer ok' }
        else { Write-Log 'explorer launch produced no process' }
    } catch {
        Write-Log ('explorer launch threw: {0}' -f $_.Exception.Message)
    }
}

if (-not $launcher) {
    Start-Process -FilePath $exe
    Start-Sleep -Seconds 3
    if (Get-WorkBuddy) { $launcher = 'start-process'; Write-Log 'launch via Start-Process ok (may stay attached to caller)' }
}

if (-not $launcher) {
    Write-Log 'ERROR: relaunch failed'
    Write-Log '=== restart aborted ==='
    exit 3
}

Write-Log ('=== restart done, launcher={0} ===' -f $launcher)
exit 0
