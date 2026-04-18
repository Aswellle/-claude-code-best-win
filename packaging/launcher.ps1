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

# Build forwarded arg string
$quoted = @()
foreach ($a in $PassArgs) {
    if ($a -match '\s') { $quoted += '"' + ($a -replace '"','\"') + '"' }
    else                 { $quoted += $a }
}
$ArgString = $quoted -join ' '

# ── Find wt.exe ───────────────────────────────────────────────────────────────
$WtExe = $null

$WtGcm = Get-Command 'wt.exe' -ErrorAction SilentlyContinue
if ($WtGcm) { $WtExe = $WtGcm.Source }

if (-not $WtExe) {
    $p = "$env:LOCALAPPDATA\Microsoft\WindowsApps\wt.exe"
    if (Test-Path $p -PathType Leaf) { $WtExe = $p }
}

if (-not $WtExe) {
    $p = Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal*\wt.exe" `
         -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { $WtExe = $p.FullName }
}

# ── Launch ────────────────────────────────────────────────────────────────────
# KEY: $CoreExe embeds directly in ONE string with single-level quotes.
# Do NOT wrap $InnerCmd (which already has quotes) in another set of quotes —
# that produces ""path"" which cmd.exe splits at the first space.
#
# Correct wt.exe syntax:
#   wt.exe --title "Claude Code Best" cmd /k "D:\path with spaces\claude-core.exe"

if ($WtExe) {
    if ($ArgString -ne '') {
        $WtArgs = "--title `"$WindowTitle`" cmd /k `"$CoreExe`" $ArgString"
    } else {
        $WtArgs = "--title `"$WindowTitle`" cmd /k `"$CoreExe`""
    }
    Start-Process -FilePath $WtExe -ArgumentList $WtArgs
    exit 0
}

# Fallback: plain cmd.exe /k
$CmdExe = "$env:SystemRoot\System32\cmd.exe"
if (Test-Path $CmdExe -PathType Leaf) {
    if ($ArgString -ne '') {
        Start-Process -FilePath $CmdExe -ArgumentList "/k `"$CoreExe`" $ArgString"
    } else {
        Start-Process -FilePath $CmdExe -ArgumentList "/k `"$CoreExe`""
    }
} else {
    Start-Process -FilePath $CoreExe -ArgumentList $PassArgs
}
