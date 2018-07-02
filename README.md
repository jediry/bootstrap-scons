# bootstrap-scons
Scripts to simplify acquiring and running SCons on Windows machines

## What is this for?
SCons is a powerful build tool, but using it to build a project on a Windows computer requires several manual steps: first, one must install Python, and then SCons. Only then can one type "scons" to build the project. On UNIX-derived systems, this is not such a problem, because SCons and Python can usually be installed via the system's native package manager (e.g., apt).

The goal of bootstrap-scons is to make SCons-based projects effortless to build on Windows. By using bootstrap-scons, a SCons-based project may be cloned from source control, and then built by running a single command:

    D:\> git clone <my-project-url.git> my-project
    D:\> cd my-project
    D:\my-project\> build

The "build" command first locates or installs Python, then locates or installs SCons, and finally invokes SCons to build the project.

## How do I use it?
To use this in your project, do the following:
1. Drop a copy of bootstrap-scons as a subdirectory of your project, or better yet add bootstrap-scons as a submodule of your project. E.g.:

       D:\my-project\> git add submodule git@github.com:jediry/bootstrap-scons.git

   By adding bootstrap-scons as a submodule, you can easily pick up updates and bugfixes, just by updating your submodule version.

2. Copy bootstrap-scons/build.bat.example and modify it to your liking. E.g.:

       D:\my-project\> copy bootstrap-scons\build.bat.example build.bat

## Things that you can customize
The main things that you might want to customize are:
* Which versions of Python/SCons are downloaded, if none can be found
* Where the downloaded Python/SCons are installed
* Whether the detected Python/SCons are cached in environment variables

Take a look at the example build.bat included with bootstrap-scons to see how to alter these things, or invoke find_python.bat or find_scons.bat with the /? parameter to see all the things that can be customized.
