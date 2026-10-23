#define AppVersion "0.1.0-dev"
[Setup]
AppId={{0D42E120-37D1-430A-8734-E62111F53625}
AppName=EHRNow Development
AppVersion={#AppVersion}
AppPublisher=EHRNow
DefaultDirName={localappdata}\Programs\EHRNow
DefaultGroupName=EHRNow Development
OutputDir=..\..\artifacts
OutputBaseFilename=EHRNow-Setup-Windows-x64
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
WizardStyle=modern
DisableProgramGroupPage=yes
[Files]
Source: "..\..\compose.installer.yaml"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\backend\*"; DestDir: "{app}\backend"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "target\*,node_modules\*,.env*,*.log"
Source: "..\..\apps\clinician-web\*"; DestDir: "{app}\apps\clinician-web"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "node_modules\*,dist\*,.env*,*.log"
Source: "..\..\install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\installer\windows\EHRNow.cmd"; DestDir: "{app}"; Flags: ignoreversion
[Icons]
Name: "{group}\EHRNow"; Filename: "{app}\EHRNow.cmd"; WorkingDir: "{app}"
Name: "{autodesktop}\EHRNow"; Filename: "{app}\EHRNow.cmd"; WorkingDir: "{app}"; Tasks: desktopicon
[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Shortcuts:"
[Run]
Filename: "{app}\EHRNow.cmd"; Description: "Start EHRNow"; Flags: postinstall nowait skipifsilent unchecked
[Code]
function InitializeSetup(): Boolean;
begin
  Result := MsgBox('This is development-only EHRNow. Do not enter real patient records or use it for care. Requires Docker Desktop with WSL2 and an Internet connection. Continue?', mbConfirmation, MB_YESNO) = IDYES;
end;
