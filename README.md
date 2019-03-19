# bootstrap-scons
Zero-dependency scripts to simplify acquiring and running SCons on Windows machines

## What is this for?
SCons is a powerful build tool, but using it to build a project on a Windows computer requires several manual steps: first, one must install Python, and then SCons. Only then can one type "scons" to build the project. On UNIX-derived systems, this is not such a problem, because SCons and Python can usually be installed via the system's native package manager (e.g., apt, rpm).

The goal of bootstrap-scons is to make SCons-based projects effortless to build on Windows. By using bootstrap-scons, a SCons-based project may be cloned from source control, and then built by running a single command:

    D:\> git clone <my-project-url.git> my-project
    D:\> cd my-project
    D:\my-project\> build

The "build" command first locates or installs Python, then locates or installs SCons, and finally invokes SCons to build the project.

## How do I use it?
To use this in your project, do the following:
1. Drop a copy of bootstrap-scons as a subdirectory of your project, or better yet add bootstrap-scons as a submodule of your project. E.g.:

       D:\my-project\> git submodule add git@github.com:jediry/bootstrap-scons.git

   By adding bootstrap-scons as a submodule, you can easily pick up updates and bugfixes, just by updating your submodule version. (Alternately, if you want to make significant customizations to your copy of bootstrap-scons, consider forking it on GitHub, and then adding _your fork_ as the submodule.)

2. Copy `bootstrap-scons/build.bat.example` and modify it to your liking. E.g.:

       D:\my-project\> copy bootstrap-scons\build.bat.example build.bat

## Things that you can customize
The main things that you might want to customize are:
* Which versions of Python/SCons are downloaded, if none can be found
* Where the downloaded Python/SCons are installed
* Whether the detected Python/SCons are cached in environment variables

Take a look at `build.bat.example` included with bootstrap-scons to see how to alter these things, or invoke `find_python.bat` or `find_scons.bat` with the /? parameter to see all the things that can be customized.

## How does it work?
A primary goal of bootstrap-scons is to be _zero dependency_: it does what it does without requiring any software that isn't already available on any Windows machine. This is fairly limiting: no wget/curl, no PowerShell...however, once Python has been found, pretty much anything can be done with relative ease.

When you run `build.bat`, here's what happens:

* `build.bat` sets default configuration values, as chosen by the project authors (see above). However, the user may override these defaults by explicitly setting the appropriate environment variables.
* `build.bat` invokes `bootstrap-scons/scons.bat`. Most of the logic (but none of the configuration) lives inside of `scons.bat`, since `build.bat` is intended to be copied and modified by project authors. This split is advantageous because it allows the core of bootstrap-scons to be updated (e.g., for bugfixes or new features) without stomping on your project's customizations.
  * `scons.bat` checks the `%FOUND_SCONS_AT%` environment variable to see whether it has already located and/or installed scons. If this variable is unset, it invokes `find_scons.bat`.
    * But before we can worry about SCons, we need Python. `find_scons.bat` checks the `%FOUND_PYTHON_AT%` environment variable to see whether it has already located and/or installed Python. If this variable is unset, it invokes `find_python.bat`.
      * `find_python.bat` searches in a number of places for an already-installed copy of Python, including the %PATH%, %PYTHONHOME%, and several places that Python is typically placed by installers, and %FIND_PYTHON_LOCAL_ROOT%, where any auto-downloaded copy of Python will be unpacked.
      * If no copy of Python is discovered, and if configured to download/install Python, `find_python.bat` constructs the download URL for the python-embed package of the specified version, and then invokes download-and-unzip.vbs to do the actual download and unpacking of the .zip archive (cmd.exe itself cannot do either of these things, but VBScript can, with a litle help from some COM objects).
      * Else, if not configured to download/install Python, `find_python.bat` aborts with an error message.
      * If Python was found or installed, `%FOUND_PYTHON_AT%` is set to point to it. This tells `find_scons.bat` and `scons.bat` where to find it, and also lets `find_python.bat` avoid re-doing this search in the future.
    * Now `find_scons.bat` knows where Python is. `find_scons.bat` searches in a few places for an already-installed copy of SCons, including the "scripts" directory of the version of Python selected, and `%FIND_SCONS_LOCAL_ROOT%`, where any auto-downloaded copy of SCons will be unpacked.
    * If no copy of SCons is discovered, and if configured to download/install SCons, `find_scons.bat` invokes itself as a Python script, and then uses Python to download and unpack SCons under `%FIND_SCONS_LOCAL_ROOT%`.
    * Else, if not configured to download/install SCons, `find_scons.bat` aborts with an error message.
    * If SCons was successfully found/installed, `%FOUND_SCONS_AT%` is set to point to it. This tells scons.bta where to find it, and also lets `find_scons.bat` avoid re-doing this search in the future.
  * If Python & SCons were successfully located/installed, `scons.bat` now launches SCons to build the project.
* Finally, `build.bat` propagates the values of `%FOUND_SCONS_AT%` and `%FOUND_PYTHON_AT%` into the calling shell's environment, so that future runs of `build.bat` can avoid re-doing all this work. (If this behavior is not desired, `build.bat` can be easily modified to avoid any changes to the shell environment; see comments in `build.bat.example`.)
