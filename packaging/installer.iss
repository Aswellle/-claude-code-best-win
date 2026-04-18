; ============================================================
; Claude Code Best — Inno Setup Installer Script
; ============================================================
; Application : Claude Code Best
; Version     : 2.1.888 (matches package.json "version")
; Architecture: x64 (native) + arm64 compatible
; Privilege   : No admin required (user-level install)
; Install dir : %LOCALAPPDATA%\ClaudeCodeBest\
; Features    :
;   - Desktop shortcut (ClaudeCode.exe)
;   - Start Menu shortcut
;   - User PATH entry (install dir added)
;   - Uninstaller
; ============================================================
; Build command (from project root):
;   iscc packaging\installer.iss
; Or open this file in the Inno Setup IDE and press F9.
; ============================================================

#define MyAppName       "Claude Code Best"
#define MyAppVersion    "2.1.888"
#define MyAppPublisher  "claude-code-best"
#define MyAppURL        "https://github.com/claude-code-best/claude-code"
#define MyAppExeName    "ClaudeCode.exe"
#define MyCoreExeName   "claude-core.exe"
#define MyOutputDir     "output"

[Setup]
; ---------- Identity ----------
AppId={{A3F8C2D1-9E47-4B6A-8D35-7C1F2E4A0B98}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
AppUpdatesURL={#MyAppURL}/releases

; ---------- Installation mode ----------
; No admin rights needed — installs per-user
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

; ---------- Paths ----------
; Install to %LOCALAPPDATA%\ClaudeCodeBest\ by default
DefaultDirName={localappdata}\ClaudeCodeBest
DefaultGroupName={#MyAppName}
DisableDirPage=no

; ---------- Output ----------
OutputDir=.
OutputBaseFilename=ClaudeCodeBest-Setup-{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
; Sign the installer if a certificate is configured:
; SignTool=signtool sign /f "cert.pfx" /p "password" /tr "http://timestamp.digicert.com" $f

; ---------- UI ----------
WizardStyle=modern
SetupIconFile=
; If you have an icon file: SetupIconFile=assets\icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
ShowLanguageDialog=no

; ---------- Architecture ----------
; x64 only — pkg bundles a Node.js x64 runtime
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; ---------- Misc ----------
MinVersion=10.0.19041
; Require Windows 10 20H1 or later (Windows Terminal commonly available)
ChangesEnvironment=yes
; We modify the user PATH

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon";    Description: "Create a &desktop shortcut";     GroupDescription: "Additional icons:"
Name: "startmenuicon";  Description: "Create a &Start Menu shortcut";  GroupDescription: "Additional icons:"
Name: "addtopath";      Description: "Add install directory to &PATH (recommended)"; GroupDescription: "System integration:"

[Files]
; ---------- Core executable ----------
Source: "{#MyOutputDir}\{#MyCoreExeName}";   DestDir: "{app}"; Flags: ignoreversion

; ---------- Launcher / double-click entry ----------
Source: "{#MyOutputDir}\{#MyAppExeName}";    DestDir: "{app}"; Flags: ignoreversion

; ---------- Native audio-capture addon (x64-win32) ----------
Source: "{#MyOutputDir}\vendor\audio-capture\x64-win32\*"; \
    DestDir: "{app}\vendor\audio-capture\x64-win32"; \
    Flags: ignoreversion recursesubdirs createallsubdirs; \
    Check: IsX64Compatible

; ---------- Native audio-capture addon (arm64-win32) ----------
Source: "{#MyOutputDir}\vendor\audio-capture\arm64-win32\*"; \
    DestDir: "{app}\vendor\audio-capture\arm64-win32"; \
    Flags: ignoreversion recursesubdirs createallsubdirs

; ---------- Computer Use Python bridge (must be alongside claude-core.exe) ----------
Source: "{#MyOutputDir}\bridge.py"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; ---------- Desktop shortcut ----------
Name: "{autodesktop}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    Comment: "Launch Claude Code Best in Windows Terminal"; \
    Tasks: desktopicon

; ---------- Start Menu shortcut ----------
Name: "{group}\{#MyAppName}"; \
    Filename: "{app}\{#MyAppExeName}"; \
    Comment: "Launch Claude Code Best in Windows Terminal"; \
    Tasks: startmenuicon

; ---------- Start Menu uninstaller ----------
Name: "{group}\Uninstall {#MyAppName}"; \
    Filename: "{uninstallexe}"; \
    Tasks: startmenuicon

[Registry]
; ---------- Add install dir to user PATH ----------
; Appends to existing PATH; does not overwrite.
Root: HKCU; Subkey: "Environment"; ValueType: expandsz; \
    ValueName: "Path"; \
    ValueData: "{olddata};{app}"; \
    Check: PathNotExists('{app}'); \
    Tasks: addtopath

[Run]
; Optionally open a welcome page / release notes after install
; Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName} now"; \
;     Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove vendor directory on uninstall (native addons)
Type: filesandordirs; Name: "{app}\vendor"

[Code]
// ── Helper: check whether {app} is already in user PATH ──────────────────
function PathNotExists(Path: string): Boolean;
var
  EnvPath: string;
begin
  if not RegQueryStringValue(HKCU, 'Environment', 'Path', EnvPath) then
    EnvPath := '';
  Result := Pos(ExpandConstant(Path), EnvPath) = 0;
end;

// ── Remove install dir from PATH on uninstall ─────────────────────────────
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  EnvPath, AppDir, NewPath: string;
  StartPos, EndPos: Integer;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    AppDir := ExpandConstant('{app}');
    if RegQueryStringValue(HKCU, 'Environment', 'Path', EnvPath) then
    begin
      // Remove all occurrences of AppDir from PATH
      NewPath := EnvPath;
      repeat
        StartPos := Pos(';' + AppDir, NewPath);
        if StartPos > 0 then
        begin
          EndPos := StartPos + Length(';' + AppDir);
          Delete(NewPath, StartPos, EndPos - StartPos);
        end else
        begin
          StartPos := Pos(AppDir + ';', NewPath);
          if StartPos > 0 then
          begin
            EndPos := StartPos + Length(AppDir + ';');
            Delete(NewPath, StartPos, EndPos - StartPos);
          end else
            StartPos := 0;
        end;
      until StartPos = 0;

      if NewPath <> EnvPath then
        RegWriteStringValue(HKCU, 'Environment', 'Path', NewPath);
    end;
  end;
end;

// ── Show a friendly message if wt.exe is not found ───────────────────────
procedure CurStepChanged(CurStep: TSetupStep);
var
  WtPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    WtPath := ExpandConstant('{localappdata}\Microsoft\WindowsApps\wt.exe');
    if not FileExists(WtPath) then
    begin
      MsgBox(
        'Claude Code Best was installed successfully.' + #13#10 + #13#10 +
        'Windows Terminal (wt.exe) was not detected on this machine.' + #13#10 +
        'Claude Code Best will fall back to a standard Command Prompt window.' + #13#10 + #13#10 +
        'For the best experience, install Windows Terminal from the Microsoft Store:' + #13#10 +
        'https://aka.ms/terminal',
        mbInformation, MB_OK
      );
    end;
  end;
end;
