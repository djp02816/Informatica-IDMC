@ECHO off
REM ============================================================================
REM Process Engine Diagnostic Script
REM Purpose: Identify root causes of process-engine deployment failures
REM Author: GitHub Copilot
REM Date: 2026-06-01
REM ============================================================================

SETLOCAL ENABLEDELAYEDEXPANSION

REM Color codes for output
SET "GREEN=[92m"
SET "RED=[91m"
SET "YELLOW=[93m"
SET "BLUE=[94m"
SET "RESET=[0m"

REM Log file
SET "DIAG_LOG=%~dp0process-engine-diagnostics.log"

ECHO. >> "%DIAG_LOG%"
ECHO ============================================================================ >> "%DIAG_LOG%"
ECHO Process Engine Diagnostic Report >> "%DIAG_LOG%"
ECHO Generated: %date% %time% >> "%DIAG_LOG%"
ECHO ============================================================================ >> "%DIAG_LOG%"

ECHO.
ECHO %BLUE%===== PROCESS ENGINE DIAGNOSTICS =====%RESET%
ECHO.

REM ============================================================================
REM 1. Check Environment Variables
REM ============================================================================
ECHO %BLUE%[1] Checking Environment Variables...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [1] ENVIRONMENT VARIABLES CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

IF EXIST "lcm-env.bat" (
    ECHO %GREEN%✓ lcm-env.bat found%RESET%
    ECHO ✓ lcm-env.bat found >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ lcm-env.bat NOT found%RESET%
    ECHO ✗ lcm-env.bat NOT found >> "%DIAG_LOG%"
)

REM ============================================================================
REM 2. Check Directory Structure
REM ============================================================================
ECHO.
ECHO %BLUE%[2] Checking Directory Structure...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [2] DIRECTORY STRUCTURE CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

SET "APP_DIR=C:\PROGRA~1\INFORM~1\apps\process-engine"
SET "APP_VER=15124581.1.1"

IF EXIST "%APP_DIR%" (
    ECHO %GREEN%✓ Process Engine directory exists: %APP_DIR%%RESET%
    ECHO ✓ Process Engine directory exists: %APP_DIR% >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ Process Engine directory NOT found: %APP_DIR%%RESET%
    ECHO ✗ Process Engine directory NOT found: %APP_DIR% >> "%DIAG_LOG%"
)

IF EXIST "%APP_DIR%\%APP_VER%" (
    ECHO %GREEN%✓ Version directory exists: %APP_DIR%\%APP_VER%%RESET%
    ECHO ✓ Version directory exists: %APP_DIR%\%APP_VER% >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ Version directory NOT found: %APP_DIR%\%APP_VER%%RESET%
    ECHO ✗ Version directory NOT found: %APP_DIR%\%APP_VER% >> "%DIAG_LOG%"
)

IF EXIST "%APP_DIR%\%APP_VER%\.lcm" (
    ECHO %GREEN%✓ .lcm directory exists%RESET%
    ECHO ✓ .lcm directory exists >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ .lcm directory NOT found%RESET%
    ECHO ✗ .lcm directory NOT found >> "%DIAG_LOG%"
)

REM ============================================================================
REM 3. Check Critical Files
REM ============================================================================
ECHO.
ECHO %BLUE%[3] Checking Critical Files...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [3] CRITICAL FILES CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\.lcm\deploy-wrapper.bat" "deploy-wrapper.bat"
CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\.lcm\app-key.pem" "app-key.pem"
CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\.lcm\app-ca-bundle.pem" "app-ca-bundle.pem"
CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\.lcm\app-keystore.jks" "app-keystore.jks"
CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\.lcm\app-truststore.jks" "app-truststore.jks"
CALL :CHECK_FILE "%APP_DIR%\%APP_VER%\bin\start.bat" "start.bat"

REM ============================================================================
REM 4. Check Java Installation
REM ============================================================================
ECHO.
ECHO %BLUE%[4] Checking Java Installation...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [4] JAVA INSTALLATION CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

SET "JAVA_HOME_8=C:\PROGRA~1\INFORM~1\jdk8\jre"
SET "JAVA_HOME_17=C:\PROGRA~1\INFORM~1\jdk"

IF EXIST "%JAVA_HOME_8%\bin\java.exe" (
    ECHO %GREEN%✓ Java 8 found: %JAVA_HOME_8%%RESET%
    ECHO ✓ Java 8 found: %JAVA_HOME_8% >> "%DIAG_LOG%"
    "%JAVA_HOME_8%\bin\java.exe" -version >> "%DIAG_LOG%" 2>&1
) ELSE (
    ECHO %RED%✗ Java 8 NOT found: %JAVA_HOME_8%%RESET%
    ECHO ✗ Java 8 NOT found: %JAVA_HOME_8% >> "%DIAG_LOG%"
)

IF EXIST "%JAVA_HOME_17%\bin\java.exe" (
    ECHO %GREEN%✓ Java 17 found: %JAVA_HOME_17%%RESET%
    ECHO ✓ Java 17 found: %JAVA_HOME_17% >> "%DIAG_LOG%"
    "%JAVA_HOME_17%\bin\java.exe" -version >> "%DIAG_LOG%" 2>&1
) ELSE (
    ECHO %YELLOW%⚠ Java 17 NOT found: %JAVA_HOME_17%%RESET%
    ECHO ⚠ Java 17 NOT found: %JAVA_HOME_17% >> "%DIAG_LOG%"
)

REM ============================================================================
REM 5. Check PostgreSQL Database
REM ============================================================================
ECHO.
ECHO %BLUE%[5] Checking PostgreSQL Database...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [5] POSTGRESQL DATABASE CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

SET "PG_BINARIES=C:\PROGRA~1\INFORM~1\apps\process-engine\data\db"

IF EXIST "%PG_BINARIES%\util\server_start.bat" (
    ECHO %GREEN%✓ PostgreSQL startup script found%RESET%
    ECHO ✓ PostgreSQL startup script found >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ PostgreSQL startup script NOT found%RESET%
    ECHO ✗ PostgreSQL startup script NOT found >> "%DIAG_LOG%"
)

REM Check if PostgreSQL is running
TASKLIST /FI "IMAGENAME eq postgres.exe" 2>NUL | FIND /I /N "postgres.exe">NUL
IF "%ERRORLEVEL%"=="0" (
    ECHO %GREEN%✓ PostgreSQL is currently running%RESET%
    ECHO ✓ PostgreSQL is currently running >> "%DIAG_LOG%"
) ELSE (
    ECHO %YELLOW%⚠ PostgreSQL is NOT running%RESET%
    ECHO ⚠ PostgreSQL is NOT running >> "%DIAG_LOG%"
)

REM ============================================================================
REM 6. Check File Permissions
REM ============================================================================
ECHO.
ECHO %BLUE%[6] Checking File Permissions...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [6] FILE PERMISSIONS CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

ECHO. >> "%DIAG_LOG%"
ECHO Permissions for: %APP_DIR%\%APP_VER%\.lcm\deploy-wrapper.bat >> "%DIAG_LOG%"
ICACLS "%APP_DIR%\%APP_VER%\.lcm\deploy-wrapper.bat" >> "%DIAG_LOG%" 2>&1

ECHO. >> "%DIAG_LOG%"
ECHO Permissions for: %APP_DIR%\%APP_VER% >> "%DIAG_LOG%"
ICACLS "%APP_DIR%\%APP_VER%" >> "%DIAG_LOG%" 2>&1

REM ============================================================================
REM 7. Check Disk Space
REM ============================================================================
ECHO.
ECHO %BLUE%[7] Checking Disk Space...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [7] DISK SPACE CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

FOR /F "tokens=3" %%A IN ('dir C:\ ^| find " bytes free"') DO (
    ECHO Disk Space Available on C: %%A >> "%DIAG_LOG%"
    ECHO %BLUE%Disk Space Available on C: %%A%RESET%
)

REM ============================================================================
REM 8. Check Log Files
REM ============================================================================
ECHO.
ECHO %BLUE%[8] Checking Log Files...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [8] LOG FILES CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

SET "LOG_DIR=%APP_DIR%\logs"

IF EXIST "%LOG_DIR%" (
    ECHO %GREEN%✓ Logs directory exists: %LOG_DIR%%RESET%
    ECHO ✓ Logs directory exists: %LOG_DIR% >> "%DIAG_LOG%"
    ECHO. >> "%DIAG_LOG%"
    ECHO Recent log files: >> "%DIAG_LOG%"
    DIR "%LOG_DIR%" /O:-D /B >> "%DIAG_LOG%" 2>&1
) ELSE (
    ECHO %RED%✗ Logs directory NOT found: %LOG_DIR%%RESET%
    ECHO ✗ Logs directory NOT found: %LOG_DIR% >> "%DIAG_LOG%"
)

REM ============================================================================
REM 9. Check Windows System Paths
REM ============================================================================
ECHO.
ECHO %BLUE%[9] Checking Windows System Paths...%RESET%
ECHO. >> "%DIAG_LOG%"
ECHO [9] WINDOWS SYSTEM PATHS CHECK >> "%DIAG_LOG%"
ECHO ------------------------------------- >> "%DIAG_LOG%"

where WMIC >NUL 2>&1
IF "%ERRORLEVEL%"=="0" (
    ECHO %GREEN%✓ WMIC is available%RESET%
    ECHO ✓ WMIC is available >> "%DIAG_LOG%"
) ELSE (
    ECHO %YELLOW%⚠ WMIC is NOT available (optional but recommended)%RESET%
    ECHO ⚠ WMIC is NOT available >> "%DIAG_LOG%"
)

where ICACLS >NUL 2>&1
IF "%ERRORLEVEL%"=="0" (
    ECHO %GREEN%✓ ICACLS is available%RESET%
    ECHO ✓ ICACLS is available >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ ICACLS is NOT available (required for permissions)%RESET%
    ECHO ✗ ICACLS is NOT available >> "%DIAG_LOG%"
)

REM ============================================================================
REM Summary
REM ============================================================================
ECHO.
ECHO %BLUE%============================================%RESET%
ECHO %BLUE%Diagnostic report saved to: %DIAG_LOG%%RESET%
ECHO %BLUE%============================================%RESET%
ECHO.

PAUSE
EXIT /B 0

REM ============================================================================
REM Subroutine: CHECK_FILE
REM ============================================================================
:CHECK_FILE
SET "FILE_PATH=%~1"
SET "FILE_NAME=%~2"

IF EXIST "%FILE_PATH%" (
    ECHO %GREEN%✓ %FILE_NAME% found%RESET%
    ECHO ✓ %FILE_NAME% found >> "%DIAG_LOG%"
) ELSE (
    ECHO %RED%✗ %FILE_NAME% NOT found%RESET%
    ECHO ✗ %FILE_NAME% NOT found >> "%DIAG_LOG%"
)
EXIT /B 0
