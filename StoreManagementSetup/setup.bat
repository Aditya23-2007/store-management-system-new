@echo off
:: Batch Installer Launcher for Store Management System
:: Prompts for configuration parameters and launches the PowerShell installer with administrator rights.

echo ==================================================================
echo STORE MANAGEMENT SYSTEM - COMPLETE AUTOMATED INSTALLER
echo ==================================================================
echo.

:: Check for Administrative Privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This installer must be run as Administrator.
    echo Please right-click setup.bat and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

:: Prompt for configurations with defaults
set "STATIC_IP=N"
set /p "STATIC_IP=Assign Recommended Static IP (192.168.1.100) to Server? (Y/N) [default: N]: "

set "MYSQL_PWD=root123"
set /p "MYSQL_PWD=Enter MySQL Root Password [default: root123]: "

set "MYSQL_PORT=3306"
set /p "MYSQL_PORT=Enter MySQL Port [default: 3306]: "

set "DB_NAME=store_db"
set /p "DB_NAME=Enter Database Name [default: store_db]: "

set "DOMAIN_NAME=bsietstore.local"
set /p "DOMAIN_NAME=Enter Local Domain Name [default: bsietstore.local]: "

set "TOMCAT_PORT=80"
set /p "TOMCAT_PORT=Enter Tomcat Port [default: 80]: "

echo.
echo ==================================================================
echo CONFIGURATION SUMMARY
echo ==================================================================
echo Configure Static IP : %STATIC_IP%
echo MySQL Port          : %MYSQL_PORT%
echo MySQL Password      : [PROTECTED]
echo Database Name       : %DB_NAME%
echo Local Domain        : %DOMAIN_NAME%
echo Tomcat Port         : %TOMCAT_PORT%
echo ==================================================================
echo.
set /p "CONFIRM=Proceed with installation? (Y/N) [default: Y]: "
if /i "%CONFIRM%"=="N" (
    echo Installation cancelled by user.
    pause
    exit /b 0
)

echo.
echo Starting automated deployment. Please wait...
echo Detailed progress will be logged to C:\StoreManagementWebApp_setup.log
echo.

:: Prepare PowerShell switch for static IP
set "STATIC_SWITCH="
if /i "%STATIC_IP%"=="Y" (
    set "STATIC_SWITCH=-ConfigureStaticIP"
)

:: Launch the PowerShell installer script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\setup.ps1" -MySQLPassword "%MYSQL_PWD%" -MySQLPort "%MYSQL_PORT%" -DBName "%DB_NAME%" -DomainName "%DOMAIN_NAME%" -TomcatPort "%TOMCAT_PORT%" %STATIC_SWITCH%

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Installation failed. See C:\StoreManagementWebApp_setup.log for details.
    echo.
    pause
    exit /b 1
)

echo.
echo [SUCCESS] Installation completed successfully!
echo.
pause
exit /b 0
