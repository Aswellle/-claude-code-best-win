# Claude Code Best launcher — ps2exe compatible
# No #Requires, no <# #> blocks — both break ps2exe

param([Parameter(ValueFromRemainingArguments=$true)][string[]]$PassArgs)

$WindowTitle = 'Claude Code Best'

# Resolve directory of this EXE (ps2exe sets $PSScriptRoot to the EXE dir)
if ($PSScriptRoot -and $PSScriptRoot -ne '') {
    $ScriptDir = $PSScriptRoot
} else {
    $ScriptDir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}

$CoreExe = Join-Path $ScriptDir 'claude-core.exe'

# Validate
if (-not (Test-Path $CoreExe -PathType Leaf)) {
    $msg = "claude-core.exe not found at:`n$CoreExe`n`nPlease re-install Claude Code Best."
    [System.Windows.Forms.MessageBox]::Show(
        $msg, 'Claude Code Best',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# Parse args: consume --cwd <dir> for the starting directory; forward everything else.
$quotedArgs = @()
$CallerDir  = $PWD.Path
$i = 0
while ($i -lt $PassArgs.Count) {
    if ($PassArgs[$i] -eq '--cwd' -and ($i + 1) -lt $PassArgs.Count) {
        $CallerDir = $PassArgs[$i + 1]
        $i += 2
    } else {
        $a = $PassArgs[$i]
        if ($a -match '\s') { $quotedArgs += '"' + ($a -replace '"', '\"') + '"' }
        else                 { $quotedArgs += $a }
        $i++
    }
}

# ── Build the wt argument string ──────────────────────────────────────────────
# Run claude-core.exe DIRECTLY inside Windows Terminal (no PowerShell wrapper).
# wt: new-tab --startingDirectory <dir> -- <program> [args]
$safeTitle = $WindowTitle -replace '"', '\"'
$safeDir   = $CallerDir   -replace '"', '\"'
$safeExe   = $CoreExe     -replace '"', '\"'

$wtArgs = "new-tab --title `"$safeTitle`" --startingDirectory `"$safeDir`" -- `"$safeExe`""
if ($quotedArgs.Count -gt 0) { $wtArgs += ' ' + ($quotedArgs -join ' ') }

# ── Launch strategy ───────────────────────────────────────────────────────────
#
# Windows Terminal is installed in two ways:
#   A) Store/manual install  → wt.exe appears in PATH via WindowsApps app-execution alias
#   B) System-bundled (Win11)→ wt.exe only reachable via the WindowsApps alias
#
# App-execution aliases are reparse stubs that cmd.exe resolves correctly but
# Start-Process may not activate from a compiled (ps2exe) GUI context.
# Strategy: prefer cmd /c wt.exe (always works when WT is installed) over
# direct Start-Process on the alias path.

$launched = $false

# 1. cmd /c wt.exe — resolves app-execution alias reliably in all contexts
$testWt = & cmd.exe /c "where wt.exe 2>nul" 2>$null
if ($LASTEXITCODE -eq 0 -or (Test-Path "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe")) {
    Start-Process 'cmd.exe' -ArgumentList "/c wt.exe $wtArgs" -WindowStyle Hidden
    $launched = $true
}

# 2. Direct path from Get-Command (PATH lookup, non-alias installs)
if (-not $launched) {
    $WtGcm = Get-Command 'wt.exe' -ErrorAction SilentlyContinue
    if ($WtGcm) {
        Start-Process -FilePath $WtGcm.Source -ArgumentList $wtArgs
        $launched = $true
    }
}

# 3. Packaged app under Program Files (side-load / enterprise installs)
if (-not $launched) {
    $wtPf = Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal*\wt.exe" `
            -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($wtPf) {
        Start-Process -FilePath $wtPf.FullName -ArgumentList $wtArgs
        $launched = $true
    }
}

if ($launched) { exit 0 }

# ── Fallback: Windows Terminal not found — open in OS default terminal ────────
if ($quotedArgs.Count -gt 0) {
    Start-Process -FilePath $CoreExe -WorkingDirectory $CallerDir -ArgumentList ($quotedArgs -join ' ')
} else {
    Start-Process -FilePath $CoreExe -WorkingDirectory $CallerDir
}
