@echo off
rem NetWriath launcher for PowerShell and cmd: runs netwriath.sh with Git Bash.
rem Results are still saved in the project's outputs folder.
setlocal
for %%I in ("%~dp0..") do set "NW_ROOT=%%~fI"
set "NW_BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "NW_BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined NW_BASH if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "NW_BASH=%LocalAppData%\Programs\Git\bin\bash.exe"
if not defined NW_BASH for /f "delims=" %%G in ('where git.exe 2^>nul') do if not defined NW_BASH if exist "%%~dpG..\bin\bash.exe" set "NW_BASH=%%~dpG..\bin\bash.exe"
if not defined NW_BASH (
    echo [x] Git Bash was not found. Install Git for Windows: https://git-scm.com/downloads
    exit /b 1
)
if not defined TERM set "TERM=xterm-256color"
"%NW_BASH%" "%NW_ROOT:\=/%/netwriath.sh" %*
exit /b %errorlevel%
