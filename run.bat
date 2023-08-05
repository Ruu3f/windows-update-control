@ECHO OFF
SET CUR_DIR=%~dp0
TITLE Windows Update Control
GOTO CHECK_IF_FILE_EXISTS

:CHECK_IF_FILE_EXISTS
IF NOT EXIST "%CUR_DIR%main.ps1" (
    COLOR C
    CLS
    ECHO main.ps1 not found.
    PAUSE > NUL
    EXIT
)
GOTO ADMIN_PERM_CHECK

:ADMIN_PERM_CHECK
REG QUERY "HKEY_USERS\S-1-5-20" || (
    CLS
    COLOR C
    CLS
    ECHO Run this script again with the `Run as Administrator` option.
    PAUSE > NUL
    EXIT
)
CLS
GOTO START_SCRIPT

:START_SCRIPT
powershell -NoProfile -ExecutionPolicy Bypass -File "%CUR_DIR%main.ps1"
PAUSE
EXIT
