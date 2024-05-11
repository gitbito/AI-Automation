@echo off
setlocal enabledelayedexpansion

rem Setting some required variables
for /f %%i in ('where bito') do set BITO_CMD=%%i
for /f "delims=" %%i in ('%BITO_CMD% -v') do set BITO_VERSION=%%i
set BITO_CMD_VEP=

rem Compare BITO_VERSION to check if it's greater than 3.7
echo %BITO_VERSION% | findstr /r /c:"^[4-9]\." >nul || echo %BITO_VERSION% | findstr /r /c:"^3\.[789]" >nul
if not errorlevel 1 set BITO_CMD_VEP=--agent create_code_doc

rem Check if folder name is provided as command line argument
if "%~1"=="" (
    echo Please provide folder name as command line argument
    exit /b 1
)

rem Get folder name from command line argument
set "folder=%~f1"  ; Use full path

rem Remove trailing backslash or forward slash if present
if "%folder:~-1%"=="\" set "folder=%folder:~0,-1%"
if "%folder:~-1%"=="/" set "folder=%folder:~0,-1%"
echo folder provided= %folder%

rem Check if folder exists
if not exist "%folder%\" (
    echo Folder %folder% does not exist
    exit /b 1
)

rem Extract the folder name from the cleaned path
for %%i in ("%folder%") do set "folder_name=%%~nxi"

rem Create document folder by prepending "doc" to the cleaned folder name
set "doc_folder=doc_%folder_name%"
if not exist "%doc_folder%\" (
    echo Creating directory: %doc_folder%
    mkdir "%doc_folder%"
)

rem Create documentation for each file in folder and subfolders
for /r "%folder%" %%f in (*.sh, *.py, *.php, *.js) do (
    rem Get relative path of file from folder
    set "file=%%f"
    set "rel_path=!file:%folder%=!"
    set "rel_path=!rel_path:~1!"  ; Remove leading backslash

    rem Get directory path of file in document folder
    set "doc_dir=%doc_folder%/!rel_path!"
    for %%d in ("!doc_dir!") do set "doc_dir=%%~dpd"

    rem Ensure directory exists
    if not exist "!doc_dir!" (
        mkdir "!doc_dir!"
    )

    rem Create documentation using bito and save it in document folder
    set "file2write=!doc_dir!%%~nf.md"
    echo Creating documentation in: !file2write!
    type "%%f" | %BITO_CMD% -p ./prompts/structured_doc.txt %BITO_CMD_VEP% > "!file2write!"
)

echo Documentation created in %doc_folder%
endlocal