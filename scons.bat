@ECHO OFF

:: If we've not already located SCons and Python, go find them now
IF "%FOUND_SCONS_AT%" == "" (
    CALL %~dp0\find_scons.bat /CONFIGURE
    IF ERRORLEVEL 1 EXIT /B %ERRORLEVEL%
)
IF "%FOUND_PYTHON_AT%" == "" (
    ECHO.Calling find_scons.bat did not result in setting %%FOUND_PYTHON_AT%%. 1>&2
    ECHO.find_scons.bat should return an error code in this case! 1>&2
    EXIT /B 1
) ELSE IF NOT EXIST "%FOUND_PYTHON_AT%\python.exe" (
    ECHO %%FOUND_PYTHON_AT%% is set ^(%FOUND_PYTHON_AT%^), but python.exe was not found there...unset it and re-run 1>&2
    EXIT /B 1
)
IF "%FOUND_SCONS_AT%" == "" (
    ECHO.Calling find_scons.bat did not result in setting %%FOUND_SCONS_AT%%. 1>&2
    ECHO.find_scons.bat should return an error code in this case! 1>&2
    EXIT /B 1
) ELSE IF NOT EXIST "%FOUND_SCONS_AT%\SCons.py" (
    ECHO %%FOUND_SCONS_AT%% is set ^(%FOUND_SCONS_AT%^), but SCons.py was not found there...unset it and re-run 1>&2
    EXIT /B 1
)

"%FOUND_PYTHON_AT%\python.exe" "%FOUND_SCONS_AT%\SCons.py" %*
