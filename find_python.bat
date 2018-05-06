@ECHO OFF
SETLOCAL EnableDelayedExpansion
GOTO :start


:usage
ECHO.%FIND_PYTHON_SELF%: Find Python.exe, and optionally configure environment to run it.         1>&2
ECHO.                                                                                             1>&2
ECHO.Usage:                                                                                       1>&2
ECHO.                                                                                             1>&2
ECHO.   %FIND_PYTHON_SELF% [/CONFIGURE] [/DEBUG]                                                  1>&2
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


:: Process command-line arguments to set script-local environment variables:
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

CALL :error_print Unable to locate Python. If it's installed, set %%PYTHONHOME%% pointing to it.
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
