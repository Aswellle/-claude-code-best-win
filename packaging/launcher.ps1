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

# Parse args: consume --cwd <dir> for starting directory; forward everything else.
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

# ── Find wt.exe (Windows Terminal) ───────────────────────────────────────────
# IMPORTANT: never use & or Invoke-Expression to call external commands here —
# ps2exe -noConsole compiles a GUI process; synchronous console-child calls hang.
# Use only PowerShell-native detection (Get-Command, Test-Path, Get-Item).

# Inject WindowsApps into PATH so Get-Command resolves app-execution aliases.
$waDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
if ($env:PATH -notlike "*$waDir*") { $env:PATH = "$waDir;$env:PATH" }

$WtExe = $null

# 1. PATH / app-execution alias (covers Store and bundled-Win11 installs)
$WtGcm = Get-Command 'wt.exe' -ErrorAction SilentlyContinue
if ($WtGcm) { $WtExe = $WtGcm.Source }

# 2. WindowsApps alias path directly (reparse point — no -PathType Leaf)
if (-not $WtExe) {
    $p = "$waDir\wt.exe"
    if (Test-Path $p) { $WtExe = $p }
}

# 3. Packaged binary under Program Files (side-load / enterprise)
if (-not $WtExe) {
    $p = Get-Item "$env:ProgramFiles\WindowsApps\Microsoft.WindowsTerminal*\wt.exe" `
         -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
    if ($p) { $WtExe = $p.FullName }
}

# ── Build wt argument string ──────────────────────────────────────────────────
# Run claude-core.exe DIRECTLY inside Windows Terminal (no PowerShell wrapper).
# wt new-tab --startingDirectory <dir> -- <exe> [args]
$safeDir = $CallerDir -replace '"', '\"'
$safeExe = $CoreExe   -replace '"', '\"'

# Use the built-in Command Prompt profile (GUID is fixed across all Windows Terminal installs).
# Omitting --title lets the tab show "命令提示符" / "Command Prompt" from the profile name.
$cmdPromptGuid = '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}'
$wtArgs = "new-tab --profile `"$cmdPromptGuid`" --startingDirectory `"$safeDir`" -- `"$safeExe`""
if ($quotedArgs.Count -gt 0) { $wtArgs += ' ' + ($quotedArgs -join ' ') }

# ── Launch ────────────────────────────────────────────────────────────────────
if ($WtExe) {
    # Start-Process uses ShellExecute internally, which correctly activates
    # app-execution aliases without needing cmd.exe as an intermediary.
    Start-Process -FilePath $WtExe -ArgumentList $wtArgs
    exit 0
}

# Fallback: Windows Terminal not found — open directly in OS default terminal
if ($quotedArgs.Count -gt 0) {
    Start-Process -FilePath $CoreExe -WorkingDirectory $CallerDir -ArgumentList ($quotedArgs -join ' ')
} else {
    Start-Process -FilePath $CoreExe -WorkingDirectory $CallerDir
}
