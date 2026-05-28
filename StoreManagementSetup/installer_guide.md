# Automated Server Installer Deployment Guide
This guide details the complete Windows automation suite created to package and install the LAN-based Store Management System as a single-click server installer.

> [!NOTE]
> All scripts and settings are modeled strictly after the database schema, firewall configs, static IP assignments, and service requirements outlined in Dr. Rajendra D. Bhosale's LAN deployment guide.

---

## 1. Directory Structure
The setup package is stored under `StoreManagementSetup` and organized as follows:

```
StoreManagementSetup/
│
├── StoreManagementSetup.iss      # Inno Setup compiler script (Wizard GUI + Pascal Script)
├── setup.bat                     # Command-line launcher (prompts for settings, checks Admin)
│
├── redist/                       # Redistribution folder for offline packages
│   └── place_installers_here.txt # Instructions for pre-bundling JDK, MySQL, Tomcat, Maven
│
├── sql/                          # SQL database initializers
│   └── reset_store_db_transfer_scrap.sql  # Database creation and seed data
│
├── client_setup/                 # Shareable scripts generated post-install
│   └── configure_client_hosts.ps1 # Auto-generated template for client machines on LAN
│
└── scripts/                      # Core automation PowerShell scripts
    ├── setup.ps1                 # Master installation orchestrator
    ├── configure_static_ip.ps1   # Static IP configuration (192.168.1.100)
    ├── download_dependencies.ps1  # Automated downloader (JDK, Tomcat, MySQL, Maven)
    ├── install_jdk.ps1           # Java JDK 25 silent installer
    ├── install_tomcat.ps1        # Tomcat 9 extractor, port config & service installation
    ├── install_mysql.ps1         # MySQL 8 extractor, service installer & password setter
    ├── setup_database.ps1        # Database schema import, seeder & LAN user setup
    ├── deploy_war.ps1            # DBConnection.java update, Maven compile, copy to webapps
    ├── configure_firewall.ps1    # Inbound firewall rules for Ports 80, 8080 & 3306
    ├── configure_hosts.ps1       # Localhost mapping and client script generator
    └── verify_server.ps1         # Deployment checks (localhost and local domain url)
```

---

## 2. Component Automation Logic & Silent Commands

### 2.1 Static IP Address Assignment
* **PowerShell Automation**: Discovers the active network routing adapter and applies:
  - Static IP: `192.168.1.100`
  - Subnet Mask: `255.255.255.0`
  - Default Gateway: `192.168.1.1`
  - Primary DNS: `8.8.8.8`
* **Silent Command Execution**: Handled in Inno Setup through the network settings task checkbox or in the command CLI launcher.

### 2.2 Java JDK 25 Silent Installation
* **Package**: Eclipse Temurin OpenJDK 25 MSI.
* **Silent Command**:
  ```powershell
  msiexec.exe /i "openjdk25.msi" /quiet /qn /norestart ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome
  ```
* **Post-Install**: Environment variable `JAVA_HOME` is set system-wide to the install directory (discovered via Registry lookup under `HKLM:\SOFTWARE\Eclipse Adoptium\JDK\25\hotspot\MSI`), and `%JAVA_HOME%\bin` is appended to the system `Path`.

### 2.3 Apache Tomcat 9 Service Configuration
* **Package**: Apache Tomcat `9.0.89` Core Windows x64 ZIP.
* **Silent Commands**:
  ```powershell
  # Register service
  C:\Tomcat9\bin\service.bat install Tomcat9
  # Set automatic startup
  Set-Service -Name "Tomcat9" -StartupType Automatic
  # Start Tomcat service
  Start-Service Tomcat9
  ```
* **Configuration**: The HTTP connector port is read from the installer GUI and set to `80` by default in `C:\Tomcat9\conf\server.xml` to allow portless client access.

### 2.4 MySQL Server 8 Service Configuration
* **Package**: MySQL Community Server `8.0.36` Windows x64 ZIP.
* **Silent Commands**:
  ```powershell
  # Initialize database directory without password
  C:\mysql-8.0\bin\mysqld.exe --defaults-file="C:\mysql-8.0\my.ini" --initialize-insecure --user=mysql
  # Register Windows Service
  C:\mysql-8.0\bin\mysqld.exe --install MySQL80 --defaults-file="C:\mysql-8.0\my.ini"
  # Set automatic startup and start service
  Set-Service -Name "MySQL80" -StartupType Automatic
  Start-Service MySQL80
  ```
* **Configuration**: Sets `bind-address=0.0.0.0` inside `my.ini` to enable external network requests.
* **Password Configuration**: Connects to the database locally on initialization and updates the root account:
  ```sql
  ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123';
  FLUSH PRIVILEGES;
  ```

### 2.5 Database Creation, Seeding & LAN Access
* **Automation**: Uses the native command line client `mysql.exe` to run the seed scripts:
  ```powershell
  # Create database
  C:\mysql-8.0\bin\mysql.exe -u root -p"root123" --port=3306 --host=127.0.0.1 -e "CREATE DATABASE IF NOT EXISTS store_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  # Import schema tables and default values
  C:\mysql-8.0\bin\mysql.exe -u root -p"root123" --port=3306 --host=127.0.0.1 --database=store_db -e "source C:\StoreManagementWebApp\sql\reset_store_db_transfer_scrap.sql"
  # Create LAN DB user and grant access
  C:\mysql-8.0\bin\mysql.exe -u root -p"root123" --port=3306 --host=127.0.0.1 -e "CREATE USER IF NOT EXISTS 'storeuser'@'%' IDENTIFIED BY 'store123'; GRANT ALL PRIVILEGES ON store_db.* TO 'storeuser'@'%'; FLUSH PRIVILEGES;"
  ```

### 2.6 Dynamic Code Update & WAR Deployment
* **DBConnection.java configuration**: Replaces hardcoded port, database name, and root credentials in the source file `src/main/java/com/store/util/DBConnection.java` on-the-fly before compilation.
* **Maven Compilation**: Extracts Apache Maven `3.9.6` zip silently to `C:\maven` and compiles the updated source code:
  ```powershell
  C:\maven\apache-maven-3.9.6\bin\mvn.cmd clean package -f "C:\StoreManagementWebApp\StoreManagementWebApp\pom.xml"
  ```
* **Tomcat Deployment**: Stops `Tomcat9` service, purges `C:\Tomcat9\webapps\ROOT\` and `ROOT.war`, copies the freshly compiled `StoreManagementWebApp.war` to `C:\Tomcat9\webapps\ROOT.war`, and starts the service.
* **Uploads Directory Permissions**: Wait for Tomcat to extract the WAR file, create the uploads structure, and grant full access:
  ```powershell
  $uploads = "C:\Tomcat9\webapps\ROOT\uploads"
  $Acl = Get-Acl $uploads
  $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","FullControl","ContainerInherit,ObjectInherit","None","Allow")
  $Acl.SetAccessRule($AccessRule)
  Set-Acl -Path $uploads -AclObject $Acl
  ```

### 2.7 Windows Firewall Configuration
* **Port open rules**:
  ```powershell
  # Allow Inbound TCP rules for HTTP ports 80 and 8080 and Database port 3306
  New-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 80)" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow -Force
  New-NetFirewallRule -DisplayName "Store Management System (Tomcat Port 8080)" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow -Force
  New-NetFirewallRule -DisplayName "Store Management Database (MySQL)" -Direction Inbound -LocalPort 3306 -Protocol TCP -Action Allow -Force
  ```

### 2.8 Local Domain Routing
* **Server**: Appends the local domain to the hosts file:
  ```text
  127.0.0.1   bsietstore.local
  ```
* **LAN Clients**: Dynamically outputs a customized `configure_client_hosts.ps1` script inside `C:\StoreManagementWebApp\client_setup\`. Running this on any client PC automatically resolves the domain name `bsietstore.local` to the server's detected LAN IP.

---

## 3. Creating the Single Setup Executable File

Follow these steps to compile everything into `StoreManagementSetup.exe`:

### Step 1: Install Inno Setup
Download and install Inno Setup 6 (or latest) on your developer machine:
* [Inno Setup Downloads](https://jrsoftware.org/isdl.php)

### Step 2: Bundle Redistributables (Optional for Offline Deployment)
If the server PC has internet access, the installer will download dependency packages dynamically. If you need a **100% Offline Installer**, download these files and place them in the `StoreManagementSetup\redist\` folder:
1. **Adoptium Temurin JDK 25 MSI**: [Download Link](https://adoptium.net/temurin/releases/?version=25) (rename to `openjdk25.msi`).
2. **Apache Tomcat 9.0.89 Core ZIP**: [Download Link](https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.89/bin/apache-tomcat-9.0.89-windows-x64.zip) (rename to `tomcat9.zip`).
3. **MySQL 8.0.36 Core ZIP**: [Download Link](https://downloads.mysql.com/archives/get/p/23/file/mysql-8.0.36-winx64.zip) (rename to `mysql8.zip`).
4. **Apache Maven 3.9.6 ZIP**: [Download Link](https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip) (rename to `maven.zip`).

### Step 3: Compile the Installer
1. Open Inno Setup Compiler (`Compil32.exe`).
2. Select **Open an existing script file** and choose `StoreManagementSetup.iss`.
3. Click **Build** -> **Compile** (or press `Ctrl + F9`).
4. Once completed, a single file `StoreManagementSetup.exe` will be generated inside the `StoreManagementSetup` directory.

---

## 4. How to Verify & Launch

### On the Server:
1. Double-click `StoreManagementSetup.exe` (run as Administrator).
2. Choose configuration options in the wizard pages (check the "Configure Static IP" box if you want to assign 192.168.1.100 automatically).
3. Click **Install**.
4. Access the portal locally via:
   * `http://localhost`
   * `http://bsietstore.local`

### On the Clients:
1. Ensure the Client PC is on the same Local Area Network (LAN) as the Server.
2. Copy `configure_client_hosts.ps1` from the Server's `C:\StoreManagementWebApp\client_setup\` directory to the Client PC.
3. Right-click `configure_client_hosts.ps1` on the Client PC and select **Run with PowerShell** (as administrator) to map the local domain.
4. Open a browser on the client and navigate to:
   * `http://bsietstore.local`
   * `http://192.168.1.100` (or the server's LAN IP)
