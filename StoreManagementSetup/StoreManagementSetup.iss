  ; Inno Setup Configuration Script for Store Management System
; Automates full LAN server deployment of JDK, Tomcat, MySQL, Maven, database tables, and firewall rules.

[Setup]
AppName=Store Management System
AppVersion=1.0
AppPublisher=BSIET Store Management
DefaultDirName=C:\StoreManagementWebApp
DefaultGroupName=Store Management System
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=StoreManagementSetup
SetupIconFile=compiler:SetupClassicIcon.ico
Compression=lzma2/ultra64
SolidCompression=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

[Messages]
WelcomeLabel2=This installer will automatically deploy the Store Management Web Portal and Server stack on this computer.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
; Copy web application source code files (ignoring build artifacts to minimize installer size)
Source: "..\StoreManagementWebApp\*"; DestDir: "{app}\StoreManagementWebApp"; Flags: recursesubdirs createallsubdirs ignoreversion; Excludes: "target\*, .git\*, .idea\*, *.war, *.zip, .settings\*"
; Copy database schemas
Source: "sql\*"; DestDir: "{app}\sql"; Flags: recursesubdirs createallsubdirs ignoreversion
; Copy automation scripts
Source: "scripts\*"; DestDir: "{app}\scripts"; Flags: recursesubdirs createallsubdirs ignoreversion
; Copy manual setup runner
Source: "setup.bat"; DestDir: "{app}"; Flags: ignoreversion
; Copy redist folder (if files are pre-downloaded, they will be bundled. Otherwise downloaded at runtime)
Source: "redist\*"; DestDir: "{app}\redist"; Flags: recursesubdirs createallsubdirs ignoreversion; Check: RedistFolderExists

[Dirs]
Name: "{app}\redist"
Name: "{app}\client_setup"

[Run]
; Run the master PowerShell deployment script silently with parameters from wizard input
Filename: "{sys}\windowspowershell\v1.0\powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\setup.ps1"" -MySQLPassword ""{code:GetMySQLPassword}"" -MySQLPort ""{code:GetMySQLPort}"" -DBName ""{code:GetDBName}"" -DomainName ""{code:GetDomainName}"" -TomcatPort ""{code:GetTomcatPort}"" -StaticIP ""{code:GetStaticIP}"" -SubnetMask ""{code:GetSubnetMask}"" -Gateway ""{code:GetGateway}"" -DNS ""{code:GetDNS}"""; \
  Flags: runhidden; \
  StatusMsg: "Deploying Server Services (Java, Tomcat, MySQL, Maven, Database schemas, and Firewall rules). This may take a few minutes..."

[Code]
var
  ConfigPage: TInputQueryWizardPage;
  NetworkPage: TInputQueryWizardPage;

function RedistFolderExists: Boolean;
begin
  Result := DirExists(ExpandConstant('{src}\redist'));
end;

procedure InitializeWizard;
begin
  { Create Network Settings page }
  NetworkPage := CreateInputQueryPage(wpSelectDir,
    'Network Adapter Settings', 'Configure Static IP Address',
    'Please enter the static IP configuration. Leave the IP Address blank to skip configuring a static IP.');

  NetworkPage.Add('IP Address:', False);
  NetworkPage.Add('Subnet Mask:', False);
  NetworkPage.Add('Default Gateway:', False);
  NetworkPage.Add('Preferred DNS:', False);

  NetworkPage.Values[0] := '192.168.1.100';
  NetworkPage.Values[1] := '255.255.255.0';
  NetworkPage.Values[2] := '192.168.1.1';
  NetworkPage.Values[3] := '8.8.8.8';

  { Create custom page to gather credentials and configuration parameters }
  ConfigPage := CreateInputQueryPage(NetworkPage.ID,
    'Database and Server Settings', 
    'Configure MySQL and Tomcat ports, passwords and domain name.',
    'Please verify or modify the configuration options below. The installer will automatically configure these services.');

  { Add input labels and boxes }
  ConfigPage.Add('MySQL Root Password (set during installation):', True); { password input mask }
  ConfigPage.Add('MySQL Server Port:', False);
  ConfigPage.Add('Database Name:', False);
  ConfigPage.Add('Local Domain Name (for LAN clients):', False);
  ConfigPage.Add('Tomcat HTTP Server Port:', False);

  { Pre-fill default settings from the PDF deployment manual }
  ConfigPage.Values[0] := 'root123';
  ConfigPage.Values[1] := '3306';
  ConfigPage.Values[2] := 'store_db';
  ConfigPage.Values[3] := 'bsietstore.local';
  ConfigPage.Values[4] := '80';
end;

{ Getter functions to supply inputs as arguments to command line scripts }
function GetMySQLPassword(Param: String): String;
begin
  Result := ConfigPage.Values[0];
end;

function GetMySQLPort(Param: String): String;
begin
  Result := ConfigPage.Values[1];
end;

function GetDBName(Param: String): String;
begin
  Result := ConfigPage.Values[2];
end;

function GetDomainName(Param: String): String;
begin
  Result := ConfigPage.Values[3];
end;

function GetTomcatPort(Param: String): String;
begin
  Result := ConfigPage.Values[4];
end;

function GetStaticIP(Param: String): String;
begin
  Result := NetworkPage.Values[0];
end;

function GetSubnetMask(Param: String): String;
begin
  Result := NetworkPage.Values[1];
end;

function GetGateway(Param: String): String;
begin
  Result := NetworkPage.Values[2];
end;

function GetDNS(Param: String): String;
begin
  Result := NetworkPage.Values[3];
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    MsgBox('Deployment scripts executed successfully!' + #13#10 +
           'Tomcat server is now running on Port ' + GetTomcatPort('') + '.' + #13#10 +
           'Access local: http://localhost:' + GetTomcatPort('') + #13#10 +
           'Access LAN: http://' + GetDomainName('') + ':' + GetTomcatPort('') + #13#10 +
           'Please share the client setup script in client_setup folder with network PCs.', 
           mbInformation, MB_OK);
  end;
end;
