@ECHO OFF
REM = """
SETLOCAL EnableDelayedExpansion
GOTO :start


:usage
ECHO.%FIND_SCONS_SELF%: Find or download SCons.                                                   1>&2
ECHO.                                                                                             1>&2
ECHO.Usage:                                                                                       1>&2
ECHO.                                                                                             1>&2
ECHO.   %FIND_SCONS_SELF% [/VERSION ^<version^>] [/SCONSLOCALROOT ^<dir^>] [/CONFIGURE] [/DEBUG]  1>&2
ECHO.                                                                                             1>&2
ECHO.   /VERSION ^<version^>      or      %%FIND_SCONS_VERSION%%=^<version^>                      1>&2
ECHO.      The version of SCons to download and install ^(e.g., /VERSION 3.0.1^), if an already-  1>&2
ECHO.      installed version cannot be found. The downloaded package will be a "scons-local"      1>&2
ECHO.      package. See http://scons.org/pages/download.html for more information.                1>&2
ECHO.                                                                                             1>&2
ECHO.   /SCONSLOCALROOT ^<dir^>   or      %%FIND_SCONS_LOCAL_ROOT%%=^<dir^>                       1>&2
ECHO.      The parent directory in which to look for scons-local installations ^(e.g.,            1>&2
ECHO.      /SCONSLOCALROOT D:\tools^). Also, if /VERSION is specified, this is where the          1>&2
ECHO.      downloaded scons-local package will be installed.                                      1>&2
ECHO.                                                                                             1>&2
ECHO.   /CONFIGURE              or      %%FIND_SCONS_CONFIGURE%%=1                                1>&2
ECHO.      Rather than printing the full path to SCons on stdout, set the %%FOUND_SCONS_AT%%      1>&2
ECHO.      environment variable in the calling shell.                                             1>&2
ECHO.                                                                                             1>&2
ECHO.   /DEBUG                  or      %%FIND_SCONS_DEBUG%%=1                                    1>&2
ECHO.      Causes this script to print detaled information about what it is doing ^(useful for    1>&2
ECHO.      diagnosing why it's not finding your installed copy of SCons^).                        1>&2
ECHO.                                                                                             1>&2
ECHO.   /?   Show this help.                                                                      1>&2
ECHO.                                                                                             1>&2
ECHO.This script searches for an installed version of the SCons build system ^(www.scons.org^),   1>&2
ECHO.looking in a number of places, and can optionally download SCons from the Internet if none   1>&2
ECHO.is found. If SCons is successfully found and/or downloaded, the path to the directory in     1>&2
ECHO.which SCons.py is located is printed to stdout, or alternately ^(if /CONFIGURE is specified^), 1>&2
ECHO.%%FOUND_SCONS_AT%% is set to this path in the calling shell's environment, and this script   1>&2
ECHO.exits with a return code of 0; otherwise, it exits with a non-zero return code indicating    1>&2
ECHO.failure. It requires Python to be installed already, which it locates using the sibling      1>&2
ECHO.script find_python.bat ^(run find_python /? for more information^).                          1>&2
ECHO.                                                                                             1>&2
ECHO.%FIND_SCONS_SELF% searches the following locations, in order:                                1>&2
ECHO.   1. The path pointed to by %%FOUND_SCONS_AT%%, if set. This allows %FIND_SCONS_SELF% to    1>&2
ECHO.      quit immediately if it has already been run previously in the current shell. If        1>&2
ECHO.      %%FOUND_SCONS_AT%% is set, but SCons.py is not found there, %FIND_SCONS_SELF% exits    1>&2
ECHO.      with an error.                                                                         1>&2
ECHO.   2. Subdirectories beginning with 'scons-' located underneath the directory specified with 1>&2
ECHO.      /SCONSLOCALROOT. These are expected to be scons-local installations ^(i.e., not MSI    1>&2
ECHO.      installed^), and this is also where %FIND_SCONS_SELF% will download SCons to, if       1>&2
ECHO.      necessary.                                                                             1>&2
ECHO.   3. The 'scripts' directory under the Python installation discovered by find_python.bat.   1>&2
ECHO.If all of these fail, and /VERSION and /SCONSLOCALROOT are specified, then %FIND_SCONS_SELF% 1>&2
ECHO.will attempt to download the specified version of SCons and use that. Else, %FIND_SCONS_SELF% 1>&2
ECHO.exits with a error                                                                           1>&2
ECHO.                                                                                             1>&2
ECHO.Each command-line parameter has an equivalent environment variable which may be set in order 1>&2
ECHO.to pass this information to %FIND_SCONS_SELF%. If both a command-line parameter and its      1>&2
ECHO.corresponding environment variable are specified, the value specified on the the command-line 1>&2
ECHO.takes precedence.                                                                            1>&2
ECHO.                                                                                             1>&2
GOTO :eof


:start

:: Where to send bug reports
SET REPORT_LINK=saunders@aggienetwork.com


:: The argument parsing logic below will alter %*, so grab the path to this script and parent directory now
SET FIND_SCONS_SELF=%~n0
SET FIND_SCONS_PATH=%~f0
SET FIND_SCONS_PARENT_PATH=%~dp0


:: Process command-line arguments to set script-local environment variables:
::    /VERSION         ->   FIND_SCONS_VERSION
::    /SCONSLOCALROOT  ->   FIND_SCONS_LOCAL_ROOT
::    /CONFIGURE       ->   FIND_SCONS_CONFIGURE
::    /DEBUG           ->   FIND_SCONS_DEBUG
:: Note that we don't initialize these variables beforehand so, in addition to specifying these command-line arguments
:: (which will set these variables only locally to this script), the caller may also opt to explicitly set these
:: variables in its environment, in which case this script will inherit them.
:parse_args
SET ARG=%1
SHIFT
IF "%ARG%" == "" (
    GOTO :done_parsing
) ELSE IF "%ARG%" == "/VERSION" (
    SET FIND_SCONS_VERSION=%1
    SHIFT
    IF "!FIND_SCONS_VERSION!" == "" (
        CALL :error_print /VERSION option requires a version number
        ECHO Run %FIND_SCONS_SELF% /? for usage 1>&2
        EXIT /B 1
    )
) ELSE IF "%ARG%" == "/SCONSLOCALROOT" (
    SET FIND_SCONS_LOCAL_ROOT=%1
    SHIFT
    IF "!FIND_SCONS_LOCAL_ROOT!" == "" (
        CALL :error_print /SCONSLOCALROOT option requires a directory
        ECHO Run %FIND_SCONS_SELF% /? for usage 1>&2
        EXIT /B 1
    )
) ELSE IF "%ARG%" == "/CONFIGURE" (
    SET FIND_SCONS_CONFIGURE=1
) ELSE IF "%ARG%" == "/DEBUG" (
    SET FIND_SCONS_DEBUG=1
) ELSE IF "%ARG%" == "/?" (
    CALL :usage
    EXIT /B 1
) ELSE (
    ECHO.Unrecognized argument %ARG% 1>&2
    ECHO.Run %FIND_SCONS_SELF% /? for usage 1>&2
    EXIT /B 1
)
GOTO :parse_args
:done_parsing


:: Make sure we have Python
CALL %FIND_SCONS_PARENT_PATH%\find_python.bat /CONFIGURE
IF ERRORLEVEL 1 EXIT /B %ERRORLEVEL%
IF NOT EXIST "%FOUND_PYTHON_AT%" (
    CALL :report_bug %%FOUND_PYTHON_AT%% is invalid, but should've been set by find_python.bat
    EXIT /B 1
)

:: First, if %FOUND_SCONS_AT% is set, we expect to find SCons there, and we abort with an error if it's not. This should
:: only happen if the caller explicitly set %FOUND_SCONS_AT% to an invalid value, or else deleted SCons after a previous
:: run of this script located it.
CALL :debug_print Looking for SCons at explicitly set %%%%FOUND_SCONS_AT%%%%
IF NOT "%FOUND_SCONS_AT%" == "" (
    IF NOT EXIST "%FOUND_SCONS_AT%\SCons.py" (
        CALL :error_print %%FOUND_SCONS_AT%% is set to "%FOUND_SCONS_AT%", but SCons.py was not found there. If it actually exists there, check file permissions. Or, un-set %%FOUND_SCONS_AT%% to let %FIND_SCONS_SELF% locate SCons elsewhere on your computer.
        EXIT /B 1
    )
    CALL :debug_print Found SCons at existing %%FOUND_SCONS_AT%%=%FOUND_SCONS_AT%
    GOTO :return
)

:: Next, look for a scons-local installation under %FIND_SCONS_LOCAL_ROOT%, possibly put there by a previous run
:: of this script
IF EXIST "%FIND_SCONS_LOCAL_ROOT%" (
    CALL :debug_print Looking for SCons in scons-local installations under %%%%FIND_SCONS_LOCAL_ROOT%%%%=%FIND_SCONS_LOCAL_ROOT%
    FOR /D %%D IN ("%FIND_SCONS_LOCAL_ROOT%\scons-*") DO (
        IF EXIST "%%D\SCons.py" (
            IF "!FOUND_SCONS_AT!" == "" (
                SET FOUND_SCONS_AT=%%D
                CALL :debug_print Found SCons at scons-local installation !FOUND_SCONS_AT!
            ) ELSE IF "%%D" GTR "!FOUND_SCONS_AT!" (
                SET FOUND_SCONS_AT=%%D
                CALL :debug_print Found newer SCons at scons-local installation !FOUND_SCONS_AT!
            ) ELSE (
                CALL :debug_print Ignoring unrecognized directory %%D...does not appear to contain SCons
            )
        )
    )
    IF NOT "!FOUND_SCONS_AT!" == "" (
        GOTO :return
    ) ELSE (
        CALL :debug_print No scons-local installations found
    )
) ELSE (
    CALL :debug_print Not looking for SCons in scons-local installations, because %%%%FIND_SCONS_LOCAL_ROOT%%%% is unset
)

:: Next, look in the "scripts" subdirectory of the version of Python we discovered
CALL :debug_print Looking for SCons under Python scripts directory
IF EXIST "%FOUND_PYTHON_AT%\Scripts\Scons.py" (
    SET FOUND_SCONS_AT=%FOUND_PYTHON_AT%\Scripts
    CALL :debug_print Found SCons in Python script directory !FOUND_SCONS_AT!
    GOTO :return
)

:: Hmmm...couldn't find it...let's see if we're allowed to download it
CALL :debug_print Failed to find installed SCons...checking to see if we can download it.
IF "%FIND_SCONS_VERSION%" == "" (
    CALL :error_print Not downloading scons-local package because no package version was specified; run with the /VERSION option or set %%%%FIND_SCONS_VERSION%%%%
    EXIT /B 1
)
IF "%FIND_SCONS_LOCAL_ROOT%" =="" (
    CALL :error_print Not downloading scons-local package because no directory was specified to install into; call with the /SCONSLOCALROOT option or set %%%%FIND_SCONS_LOCAL_ROOT%%%%
    EXIT /B 1
)

:: Alright, time to download it. cmd.exe isn't so good at network stuff, but we know we have Python
:: at this point, so we'll do the download in Python code.
python -x "%FIND_SCONS_PATH%" "%FIND_SCONS_LOCAL_ROOT%" "%FIND_SCONS_VERSION%"
IF ERRORLEVEL 1 EXIT /B %ERRORLEVEL%
IF EXIST "%FIND_SCONS_LOCAL_ROOT%\scons-%FIND_SCONS_VERSION%\SCons.py" (
    SET FOUND_SCONS_AT=%FIND_SCONS_LOCAL_ROOT%\scons-%FIND_SCONS_VERSION%
    CALL :debug_print Successfully installed scons-local package at !FOUND_SCONS_AT!
    GOTO :return
) ELSE (
    CALL :debug_print Failed to install scons-local package %FIND_SCONS_VERSION% under %FIND_SCONS_LOCAL_ROOT%
    EXIT /B 1
)


:report_bug
ECHO.%* 1>&2
ECHO.Please report this to %REPORT_LINK%, and include the full path to your installations of Python and SCons ^(if any^) 1>&2
GOTO :eof


:error_print
ECHO.[ERROR]: %* 1>&2
GOTO :eof


:debug_print
IF "%FIND_SCONS_DEBUG%" == "1" (ECHO.[DEBUG]: %* 1>&2)
GOTO :eof


:: Return the location of the discovered SCons to the caller, either by printing its path to stdout, or (if /CONFIGURE
:: was specified) by setting %FOUND_SCONS_AT% in the calling shell.
:return
IF "%FIND_SCONS_CONFIGURE%" == "" (
    ECHO.%FOUND_SCONS_AT%
    GOTO :eof
)

:: Configure the environment in the calling shell. Since everyting up through here is inside of SETLOCAL, we need to
:: ENDLOCAL here so that we can modify the outer environment. Environment variables within ( )s are expanded
:: immediately, before executing anything inside, which allows us to pass values out of the SETLOCAL/ENDLOCAL scope.
(
    ENDLOCAL
    SET "FOUND_SCONS_AT=%FOUND_SCONS_AT%"
    SET "FOUND_PYTHON_AT=%FOUND_PYTHON_AT%"
    SET "PYTHONPATH=%PYTHONPATH%"
    SET "PATH=%PATH%"
)

GOTO endofPython """


import os
import sys
import io
import urllib.request
import zipfile

find_scons_debug = os.getenv('FIND_SCONS_DEBUG', "") == "1"
scons_version = os.environ['FIND_SCONS_VERSION']
scons_local_root = os.environ['FIND_SCONS_LOCAL_ROOT']
scons_root = scons_local_root + "\scons-" + scons_version

if not os.path.isfile(scons_root + "\Scons.py"):
    if find_scons_debug:
        print("[DEBUG]: Downloading scons " + scons_version + " to " + scons_root, file=sys.stderr)

    scons_url = "http://prdownloads.sourceforge.net/scons/scons-local-" + scons_version + ".zip"
    response = urllib.request.urlopen(scons_url)
    bytestream = io.BytesIO(response.read())
    zip = zipfile.ZipFile(bytestream)
    zip.extractall(scons_root)

elif find_scons_debug:
    print("[DEBUG]: Found scons at " + scons_root, file=sys.stderr)

REM = """
:endofPython """
