# Claude Code Best — Windows EXE Packaging

Produces a standalone Windows installer for **Claude Code Best** (version 2.1.888).

## Architecture Overview

```
Project source (src/entrypoints/cli.tsx)
  │
  ▼
bun run packaging/build-compile.ts
  → Bun.build({ compile: true })
  → packaging/output/claude-core.exe   (138 MB, embeds Bun runtime + all JS)
  │
  ├─ Copy vendor/audio-capture/*.node ──→ packaging/output/vendor/audio-capture/
  │
  ▼
ps2exe launcher.ps1 ──→ packaging/output/ClaudeCode.exe  (37 KB, double-click entry)
  │                         opens Windows Terminal → runs claude-core.exe
  ▼
Inno Setup installer.iss ──→ packaging/ClaudeCodeBest-Setup-2.1.888.exe  (31 MB)
```

> **Why Bun compile, not pkg?**
> `dist/cli.js` is ESM with top-level await. `pkg` cannot handle `require()` of such modules
> (`ERR_REQUIRE_ASYNC_MODULE`). `bun build --compile` embeds the Bun runtime and handles
> ESM + top-level await natively.

---

## Prerequisites

| Tool | Install |
|------|---------|
| **Bun** ≥ 1.2 | `irm bun.sh/install.ps1 \| iex` |
| **ps2exe** | `Install-Module -Name ps2exe -Scope CurrentUser -Force` |
| **Inno Setup** ≥ 6.2 | https://jrsoftware.org/isdl.php |

---

## Quick Start (automated)

Run from the **project root** in PowerShell:

```powershell
.\packaging\build-exe.ps1
```

Re-run packaging only (skip compile):

```powershell
.\packaging\build-exe.ps1 -SkipBuild
```

---

## Manual Step-by-Step

**Step 1 — Compile standalone EXE**

```powershell
# From project root
bun run packaging/build-compile.ts
# → packaging/output/claude-core.exe (138 MB)
```

**Step 2 — Copy native addons**

```powershell
$dest = "packaging/output/vendor/audio-capture"
New-Item -ItemType Directory -Force "$dest/x64-win32", "$dest/arm64-win32"
Copy-Item vendor/audio-capture/x64-win32/*.node  "$dest/x64-win32/"
Copy-Item vendor/audio-capture/arm64-win32/*.node "$dest/arm64-win32/"
```

**Step 3 — Compile launcher**

```powershell
Import-Module ps2exe
Invoke-ps2exe `
    -InputFile  packaging/launcher.ps1 `
    -OutputFile packaging/output/ClaudeCode.exe `
    -noConsole -title "Claude Code Best" -version "2.1.888"
```

**Step 4 — Build installer**

```powershell
Set-Location packaging
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
# → packaging/ClaudeCodeBest-Setup-2.1.888.exe
```

---

## Output Structure

```
packaging/
├── ClaudeCodeBest-Setup-2.1.888.exe   ← distribute this to users
└── output/
    ├── claude-core.exe                ← Bun runtime + all JS (138 MB)
    ├── ClaudeCode.exe                 ← double-click launcher (37 KB)
    └── vendor/
        └── audio-capture/
            ├── x64-win32/audio-capture.node
            └── arm64-win32/audio-capture.node
```

The installer places everything into `%LOCALAPPDATA%\ClaudeCodeBest\` (no admin required)
and adds the directory to the user PATH.

---

## Files in This Directory

| File | Purpose |
|------|---------|
| `build-exe.ps1` | Master automation — runs all 4 steps |
| `build-compile.ts` | Bun compile script (step 1) |
| `launcher.ps1` | Windows Terminal launcher (compiled to ClaudeCode.exe) |
| `installer.iss` | Inno Setup script |
| `pkg-config.json` | Legacy pkg config (kept for reference, not used) |
| `output/` | Build artifacts |

---

## Troubleshooting

### Windows Terminal not found
`ClaudeCode.exe` automatically falls back to `cmd /k` when `wt.exe` is absent.
Install via: `winget install Microsoft.WindowsTerminal`

### audio-capture.node not loading
Ensure `vendor/audio-capture/x64-win32/audio-capture.node` is in the **same directory** as
`claude-core.exe`. The installer handles this. Voice mode will silently skip if missing.

### SmartScreen warning on first run
Unsigned executables trigger SmartScreen. Click "More info → Run anyway", or sign the
binaries with a code-signing certificate.

### Updating version
1. Update `"version"` in `package.json`
2. Update `MACRO.VERSION` in `scripts/defines.ts`
3. Update `#define MyAppVersion` in `packaging/installer.iss`
4. Re-run `.\packaging\build-exe.ps1`
