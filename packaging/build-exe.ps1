#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Code Best — Full Windows EXE packaging pipeline.

.DESCRIPTION
    Orchestrates the complete build pipeline:
      1. Prerequisite checks (Bun, ps2exe)
      2. bun run packaging/build-compile.ts  →  packaging/output/claude-core.exe
         (uses Bun.build compile:true — embeds Bun runtime, ~138 MB)
      3. Copy native .node files (vendor/audio-capture) → output/
      4. ps2exe launcher.ps1 → ClaudeCode.exe
      5. iscc installer.iss → ClaudeCodeBest-Setup-2.1.888.exe
      6. Print final directory layout

.PARAMETER SkipBuild
    Skip step 2 (bun compile). Useful when claude-core.exe is already up to date.

.EXAMPLE
    .\packaging\build-exe.ps1
    .\packaging\build-exe.ps1 -SkipBuild
#>

[CmdletBinding()]
param(
    [switch]$SkipBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Resolve project root (one level up from packaging/) ──────────────────────
$PackagingDir = $PSScriptRoot
$ProjectRoot  = Split-Path -Parent $PackagingDir
$OutputDir    = Join-Path $PackagingDir 'output'

Write-Host "`n=====================================================" -ForegroundColor Cyan
Write-Host "  Claude Code Best — Windows EXE Packaging Pipeline" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Project root : $ProjectRoot"
Write-Host "Packaging dir: $PackagingDir"
Write-Host "Output dir   : $OutputDir"
Write-Host "pkg target   : $PkgTarget"
Write-Host ""

# ─────────────────────────────────────────────────────────────────────────────
# STEP 0 — Ensure output directory exists
# ─────────────────────────────────────────────────────────────────────────────
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Prerequisite checks
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[1/5] Checking prerequisites..." -ForegroundColor Yellow

function Assert-Tool {
    param([string]$Name, [string]$VersionArg = '--version', [string]$MinVersion = '', [string]$InstallHint = '')
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Error "MISSING: $Name is not in PATH.`n$InstallHint"
    }
    $verOut = & $Name $VersionArg 2>&1 | Select-Object -First 1
    Write-Host "  OK  $Name : $verOut"
    return $verOut
}

# Bun
Assert-Tool 'bun' '--version' -InstallHint 'Install Bun: https://bun.sh/docs/installation'

# ps2exe — optional but required for ClaudeCode.exe launcher
$ps2exeAvailable = $false
$ps2exeCmd = Get-Command 'ps2exe' -ErrorAction SilentlyContinue
if (-not $ps2exeCmd) {
    # Try as a PowerShell module command
    $ps2exeModule = Get-Command 'Invoke-PS2EXE' -ErrorAction SilentlyContinue
    if ($ps2exeModule) {
        $ps2exeAvailable = $true
        Write-Host "  OK  ps2exe (Invoke-PS2EXE module found)"
    } else {
        Write-Warning "WARNING: ps2exe / Invoke-PS2EXE not found. ClaudeCode.exe launcher will be SKIPPED."
        Write-Warning "To install: Install-Module -Name ps2exe -Scope CurrentUser -Force"
    }
} else {
    $ps2exeAvailable = $true
    Write-Host "  OK  ps2exe: $($ps2exeCmd.Source)"
}

Write-Host "Prerequisite check complete.`n" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — bun compile: src/entrypoints/cli.tsx → claude-core.exe
# Uses Bun.build(compile:true) which embeds the Bun runtime (~138 MB output).
# pkg cannot be used because the dist output is ESM with top-level await.
# ─────────────────────────────────────────────────────────────────────────────
$coreExeOut = Join-Path $OutputDir 'claude-core.exe'

if ($SkipBuild) {
    Write-Host "[2/4] Skipping bun compile (-SkipBuild flag set)" -ForegroundColor Yellow
    if (-not (Test-Path $coreExeOut)) {
        Write-Error "claude-core.exe not found at $coreExeOut! Remove -SkipBuild or run packaging first."
    }
    Write-Host "  claude-core.exe found, continuing."
} else {
    Write-Host "[2/4] Running bun compile → claude-core.exe..." -ForegroundColor Yellow
    Push-Location $ProjectRoot
    try {
        & bun run packaging/build-compile.ts
        if ($LASTEXITCODE -ne 0) {
            Write-Error "bun compile failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
    Write-Host "Compile complete.`n" -ForegroundColor Green
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Copy native .node files to output/
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[4/5] Copying native .node addon files..." -ForegroundColor Yellow

$vendorAudioDir = Join-Path $ProjectRoot 'vendor\audio-capture'

# Windows-specific architectures
$winArchDirs = @(
    Join-Path $vendorAudioDir 'x64-win32',
    Join-Path $vendorAudioDir 'arm64-win32'
)

foreach ($archDir in $winArchDirs) {
    if (Test-Path $archDir) {
        $nodeFiles = Get-ChildItem -Path $archDir -Filter '*.node' -ErrorAction SilentlyContinue
        foreach ($nf in $nodeFiles) {
            # Preserve arch subfolder structure in output so the loader can find them
            $archName  = Split-Path -Leaf $archDir
            $destSubDir = Join-Path $OutputDir "vendor\audio-capture\$archName"
            New-Item -ItemType Directory -Force -Path $destSubDir | Out-Null
            Copy-Item -Path $nf.FullName -Destination $destSubDir -Force
            Write-Host "  Copied: $($nf.Name) → output\vendor\audio-capture\$archName\"
        }
    } else {
        Write-Host "  Skipped (not found): $archDir"
    }
}

Write-Host "Native addon copy complete.`n" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — ps2exe: compile launcher.ps1 → ClaudeCode.exe
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[3/4] Compiling launcher.ps1 → ClaudeCode.exe..." -ForegroundColor Yellow

$launcherPs1  = Join-Path $PackagingDir 'launcher.ps1'
$launcherExe  = Join-Path $OutputDir 'ClaudeCode.exe'

if ($ps2exeAvailable) {
    # Prefer the module form (Invoke-PS2EXE); fall back to exe form
    $useModule = [bool](Get-Command 'Invoke-PS2EXE' -ErrorAction SilentlyContinue)
    if ($useModule) {
        Invoke-PS2EXE `
            -InputFile  $launcherPs1 `
            -OutputFile $launcherExe `
            -noConsole `
            -title      'Claude Code Best' `
            -version    '2.1.888' `
            -company    'claude-code-best' `
            -description 'Claude Code Best Launcher'
    } else {
        # exe form
        & ps2exe `
            $launcherPs1 `
            $launcherExe `
            -noConsole `
            -title 'Claude Code Best'
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "ps2exe completed with exit code $LASTEXITCODE — inspect output above."
    } else {
        Write-Host "ClaudeCode.exe created successfully.`n" -ForegroundColor Green
    }
} else {
    Write-Warning "Skipped: ps2exe not available."
    Write-Warning "Users can still run: node claude-core.exe  OR  double-click launcher.ps1 (Right-click → Run with PowerShell)"
}

# ─────────────────────────────────────────────────────────────────────────────
# FINAL — Print output directory layout
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Output directory layout:" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Get-ChildItem -Path $OutputDir -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($OutputDir.Length + 1)
    $pad = '  ' * ($rel.Split('\').Count - 1)
    $icon = if ($_.PSIsContainer) { '[DIR] ' } else { '[FILE]' }
    $size = if (-not $_.PSIsContainer) { '  ({0:N0} KB)' -f [math]::Round($_.Length / 1024, 0) } else { '' }
    Write-Host "$pad$icon $($_.Name)$size"
}

Write-Host "`n" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Inno Setup: build installer EXE
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[4/4] Building installer with Inno Setup..." -ForegroundColor Yellow
$isccPaths = @(
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe'
)
$isccExe = $isccPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $isccExe) {
    $isccExe = (Get-Command 'iscc' -ErrorAction SilentlyContinue)?.Source
}

if ($isccExe) {
    Push-Location $PackagingDir
    try {
        & $isccExe installer.iss
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Inno Setup exited with code $LASTEXITCODE"
        } else {
            Write-Host "Installer built successfully.`n" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warning "Inno Setup (ISCC.exe) not found — installer step skipped."
    Write-Warning "Install from https://jrsoftware.org/isdl.php then re-run with -SkipBuild."
}

Write-Host "DONE. Distributable files:" -ForegroundColor Green
Write-Host "  EXE bundle : $OutputDir" -ForegroundColor White
Write-Host "  Installer  : $PackagingDir\ClaudeCodeBest-Setup-2.1.888.exe" -ForegroundColor White
Write-Host ""
