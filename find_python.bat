@ECHO OFF
SETLOCAL EnableDelayedExpansion
GOTO :start


:usage
ECHO.%FIND_PYTHON_SELF%: Find Python.exe, and optionally configure environment to run it.         1>&2
ECHO.                                                                                             1>&2
ECHO.Usage:                                                                                       1>&2
ECHO.                                                                                             1>&2
ECHO.   %FIND_PYTHON_SELF% [/VERSION ^<version^>] [/PYTHONLOCALROOT ^<dir^>] [/CONFIGURE] [/DEBUG] 1>&2
ECHO.                                                                                             1>&2
ECHO.   /VERSION ^<version^>      or    %%FIND_PYTHON_VERSION%%=^<version^>                       1>&2
ECHO.      The version of Python to download and install ^(e.g., /VERSION 3.7.0^), if an already- 1>&2
ECHO.      installed version cannot be found. The downloaded package will be a "python-embed"     1>&2
ECHO.      package. See http://scons.org/pages/download.html for more information.                1>&2
ECHO.                                                                                             1>&2
ECHO.   /PYTHONLOCALROOT ^<dir^>   or   %%FIND_PYTHON_LOCAL_ROOT%%=^<dir^>                        1>&2
ECHO.      The parent directory in which to look for python-embed installations ^(e.g.,           1>&2
ECHO.      /PYTHONLOCALROOT D:\tools^). Also, if /VERSION is specified, this is where the         1>&2
ECHO.      downloaded python-embed package will be installed.                                     1>&2
ECHO.                                                                                             1>&2
ECHO.   /CONFIGURE              or      %%FIND_PYTHON_CONFIGURE%%=1                               1>&2
ECHO.      Rather than printing the full path to Python on stdout, set the %%FOUND_PYTHON_AT%%    1>&2
ECHO.      and %%PYTHONPATH%% environment variables in the calling shell, as well as updating     1>&2
ECHO.      %%PATH%% to include python.exe, if it doesn't already.                                 1>&2
ECHO.                                                                                             1>&2
ECHO.   /DEBUG                  or      %%FIND_PYTHON_DEBUG%%=1                                   1>&2
ECHO.      Causes this script to print detaled information about what it is doing ^(useful for    1>&2
ECHO.      diagnosing why it's not finding your installed copy of Python^).                       1>&2
ECHO.                                                                                             1>&2
ECHO.   /?   Show this help.                                                                      1>&2
ECHO.                                                                                             1>&2
ECHO.This script searches for an installed version of Python on this computer, looking in a       1>&2
ECHO.number of places. If Python is successfully found, the path to the directory in which        1>&2
ECHO.python.exe is located is printed to stdout, or alternately ^(if /CONFIGURE is specified^),   1>&2
ECHO.%%FOUND_PYTHON_AT%% is set to this path in the calling shell's environment, and %%PATH%% and 1>&2
ECHO.%%PYTHONPATH%% are set/updated appropriately, and this script exits with a return code of 0; 1>&2
ECHO.otherwise, it exits with a non-zero return code indicating failure.                          1>&2
ECHO.                                                                                             1>&2
ECHO.Each command-line parameter has an equivalent environment variable which may be set in order 1>&2
ECHO.to pass this information to %FIND_PYTHON_SELF%. If both a command-line parameter and its     1>&2
ECHO.corresponding environment variable are specified, the value specified on the the command-line 1>&2
ECHO.takes precedence.                                                                            1>&2
ECHO.                                                                                             1>&2
GOTO :eof


:start

:: The argument parsing logic below will alter %*, so grab the path to this script now
SET FIND_PYTHON_SELF=%~n0
SET FIND_PYTHON_PATH=%0
SET FIND_PYTHON_PARENT_PATH=%~dp0


:: Process command-line arguments to set script-local environment variables:
::    /VERSION         ->   FIND_PYTHON_VERSION
::    /PYTHONLOCALROOT ->   FIND_PYTHON_LOCAL_ROOT
::    /CONFIGURE       ->   FIND_PYTHON_CONFIGURE
::    /DEBUG           ->   FIND_PYTHON_DEBUG
:: Note that we don't initialize these variables beforehand so, in addition to specifying these command-line arguments
:: (which will set these variables only locally to this script), the caller may also opt to explicitly set these
:: variables in its environment, in which case this script will inherit them.
:parse_args
SET ARG=%1
SHIFT
IF "%ARG%" == "" (
    GOTO :done_parsing
) ELSE IF "%ARG%" == "/VERSION" (
    SET FIND_PYTHON_VERSION=%1
    SHIFT
    IF "!FIND_PYTHON_VERSION!" == "" (
        CALL :error_print /VERSION option requires a version number
        ECHO Run %FIND_PYTHON_SELF% /? for usage 1>&2
        EXIT /B 1
    )
) ELSE IF "%ARG%" == "/PYTHONLOCALROOT" (
    SET FIND_PYTHON_LOCAL_ROOT=%1
    SHIFT
    IF "!FIND_PYTHON_LOCAL_ROOT!" == "" (
        CALL :error_print /PYTHONLOCALROOT option requires a directory
        ECHO Run %FIND_PYTHON_SELF% /? for usage 1>&2
        EXIT /B 1
    )
) ELSE IF "%ARG%" == "/CONFIGURE" (
    SET FIND_PYTHON_CONFIGURE=1
) ELSE IF "%ARG%" == "/DEBUG" (
    SET FIND_PYTHON_DEBUG=1
) ELSE IF "%ARG%" == "/?" (
    CALL :usage
    EXIT /B 1
) ELSE (
    ECHO.Unrecognized argument %ARG% 1>&2
    ECHO.Run %FIND_PYTHON_SELF% /? for usage 1>&2
    EXIT /B 1
)
GOTO :parse_args
:done_parsing


:: First, see if %FOUND_PYTHON_AT% is already set
CALL :debug_print Looking for Python at explicitly set %%%%FOUND_PYTHON_AT%%%%
IF NOT "%FOUND_PYTHON_AT%" == "" (
    IF NOT EXIST "%FOUND_PYTHON_AT%\python.exe" (
        CALL :error_print %%FOUND_PYTHON_AT%% is set to "%FOUND_PYTHON_AT%", but python.exe was not found there. If it actually exists there, check file permissions. Or, un-set %%FOUND_PYTHON_AT%% to let %FIND_PYTHON_SELF% locate Python elsewhere on your computer.
        EXIT /B 1
    )
    CALL :debug_print Found Python via explictly set %%%%FOUND_PYTHON_AT%%%%, at %FOUND_PYTHON_AT%
    GOTO :return
)


:: Next, look for a python-embed installation under %FIND_PYTHON_LOCAL_ROOT%, possibly put there by a previous run
:: of this script
IF EXIST "%FIND_PYTHON_LOCAL_ROOT%" (
    CALL :debug_print Looking for Python in python-embed installations under %%%%FIND_PYTHON_LOCAL_ROOT%%%%=%FIND_PYTHON_LOCAL_ROOT%
    CALL :search_at %FIND_PYTHON_LOCAL_ROOT%\python-*
    IF EXIST "!FOUND_PYTHON_AT!" (GOTO :return)
    CALL :debug_print No python-embed installations found
) ELSE (
    CALL :debug_print Not looking for Python in python-embed installations, because %%%%FIND_PYTHON_LOCAL_ROOT%%%% is unset
)

:: Next, see if %PYTHONHOME% is set
CALL :debug_print Looking for Python at %%%%PYTHONHOME%%%%
IF NOT "%PYTHONHOME%" == "" (
    IF EXIST "%PYTHONHOME%\python.exe" (
        SET FOUND_PYTHON_AT=%PYTHONHOME%
        CALL :debug_print Found Python via explictly set %%%%PYTHONHOME%%%%, at !FOUND_PYTHON_AT!
        GOTO :return
    )
)


:: Next, see if python is already in PATH
CALL :debug_print Looking for Python in %%%%PATH%%%%
FOR /F "tokens=* USEBACKQ" %%F IN ('python.exe') DO (
    IF EXIST "%%~$PATH:F" (
        SET FOUND_PYTHON_AT=%%~dp$PATH:F
        CALL :debug_print Found Python via %%%%PATH%%%%, at !FOUND_PYTHON_AT!
        GOTO :return
    )
)


:: Now, look in some common places
CALL :search_at C:\Python\python*
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)

CALL :search_at C:\Python*
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)

CALL :search_at D:\Python\python*
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)

CALL :search_at D:\Python*
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)

CALL :search_at %LOCALAPPDATA%\Programs\Python\python*
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)

:: Hmmm...couldn't find it...let's see if we're allowed to download it
CALL :debug_print Failed to find installed Python...checking to see if we can download it.
IF "%FIND_PYTHON_VERSION%" == "" (
    CALL :error_print Not downloading python-embed package because no package versio was specified; run with the /VERSION option or set %%%%FIND_PYTHON_VERSION%%%%
    EXIT /B 1
)
IF "%FIND_PYTHON_LOCAL_ROOT%" =="" (
    CALL :error_print Not downloading python-embed package because no directory was specified to install into; call with the /PYTHONLOCALROOT option or set %%%%FIND_PYTHON_LOCAL_ROOT%%%%
    EXIT /B 1
)

:: Alright, time to download it. cmd.exe isn't so good at network stuff, but we can do it with VBScript.
IF NOT "%FIND_PYTHON_DEBUG%" == "" (SET FIND_PYTHON_DOWNLOAD_DEBUG_ARG=/DEBUG)
IF "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
    SET FIND_PYTHON_ARCH=amd64
) ELSE (
    SET FIND_PYTHON_ARCH=wwin32
)
SET FIND_PYTHON_DOWNLOAD_URL=https://www.python.org/ftp/python/%FIND_PYTHON_VERSION%/python-%FIND_PYTHON_VERSION%-embed-%FIND_PYTHON_ARCH%.zip
SET FIND_PYTHON_EXTRACT_TO=%FIND_PYTHON_LOCAL_ROOT%\python-%FIND_PYTHON_VERSION%
cscript //NoLogo "%FIND_PYTHON_PARENT_PATH%download-and-unzip.vbs" "%FIND_PYTHON_DOWNLOAD_URL%" "%FIND_PYTHON_EXTRACT_TO%" %FIND_PYTHON_DOWNLOAD_DEBUG_ARG%
CALL :search_at %FIND_PYTHON_EXTRACT_TO%
IF EXIST "%FOUND_PYTHON_AT%" (GOTO :return)
CALL :debug_print Failed to install python-embed package %FIND_PYTHON_VERSION% under %FIND_PYTHON_LOCAL_ROOT%
EXIT /B 1


:search_at
CALL :debug_print Looking for Python in %1
FOR /D %%D IN (%1) DO (
    IF EXIST "%%D\python.exe" (
        IF /I "%FOUND_PYTHON_AT%" LSS "%%D" (
            SET FOUND_PYTHON_AT=%%D
            CALL :debug_print Found Python at !FOUND_PYTHON_AT!
        )
    )
)
GOTO :eof


:error_print
ECHO.[ERROR]: %* 1>&2
GOTO :eof


:debug_print
IF "%FIND_PYTHON_DEBUG%" == "1" (ECHO.[DEBUG]: %* 1>&2)
GOTO :eof


:: Return the location of the discovered Python to the caller, either by printing its path to stdout, or (if /CONFIGURE
:: was specified) by setting %FOUND_PYTHON_AT%, %PYTHONPATH% and possibly %PATH% in the calling shell.
:return
CALL :debug_print Using Python at %FOUND_PYTHON_AT%
IF "%FIND_PYTHON_CONFIGURE%" == "" (
    ECHO.%FOUND_PYTHON_AT%
    GOTO :eof
)

:: Configure the environment in the calling shell. Since everyting up through here is inside of SETLOCAL, we need to
:: ENDLOCAL here so that we can modify the outer environment. Environment variables within ( )s are expanded
:: immediately, before executing anything inside, which allows us to pass values out of the SETLOCAL/ENDLOCAL scope.
(
    ENDLOCAL
    SET "FOUND_PYTHON_AT=%FOUND_PYTHON_AT%"
    SET "PYTHONPATH=%FOUND_PYTHON_AT%\DLLs;%FOUND_PYTHON_AT%\lib;%FOUND_PYTHON_AT%\lib\site-packages"
)
:: Skip setting %PATH% if the Python we discovered is already in %PATH%
FOR /F "usebackq" %%F IN ('python.exe') DO (
    IF "%%~$PATH:F" == "%FOUND_PYTHON_AT%\python.exe" (GOTO :eof)
)
SET PATH=%FOUND_PYTHON_AT%;%PATH%
