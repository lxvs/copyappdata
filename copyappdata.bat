@echo off
setlocal
call:setmetadata
call:setdefaults

:parseargs
if %1. == . (goto endparseargs)
set term=1
if "%~1" == "--from" (
    if "%~2" == "" (
        call:err "error: `%~1' requires a value"
        goto end
    )
    set "from=%~2"
    shift /1
    shift /1
    goto parseargs
)
if "%~1" == "--to" (
    if "%~2" == "" (
        call:err "error: `%~1' requires a value"
        goto end
    )
    set "to=%~2"
    shift /1
    shift /1
    goto parseargs
)
if "%~1" == "--list" (
    if "%~2" == "" (
        call:err "error: `%~1' requires a value"
        goto end
    )
    set "list=%~2"
    shift /1
    shift /1
    goto parseargs
)
if "%~1" == "--reverse" (
    set reverse=1
    shift /1
    goto parseargs
)
if "%~1" == "--no-reverse" (
    set reverse=
    shift /1
    goto parseargs
)
if "%~1" == "--no-backup" (
    set backup=
    shift /1
    goto parseargs
)
if "%~1" == "--backup" (
    set backup=1
    shift /1
    goto parseargs
)
if "%~1" == "--no-term" (
    set term=
    shift /1
    goto parseargs
)
if "%~1" == "--term" (
    set term=1
    shift /1
    goto parseargs
)
if "%~1" == "--version" (
    call:version
    goto end
)
if "%~1" == "/?" (
    call:help
    goto end
)
if "%~1" == "--help" (
    call:help
    goto end
)
if "%~1" == "-?" (
    call:help
    goto end
)
call:err "error: invalid argument `%~1'" "%tryformore%"
goto end
:endparseargs

call:validateargs || exit /b
call:doit || exit /b
goto end

:setmetadata
set _version=0.1.0
set _date=2022-08-18
set "_title=copyappdata %_version%"
title %_title%
set "tryformore=Try `copyappdata --help' for more information."
exit /b
::setmetadata

:setdefaults
set ec=0
set term=
if defined COPYAPPDATA_FROM (set "from=%COPYAPPDATA_FROM%") else (set from=)
if defined COPYAPPDATA_TO (set "to=%COPYAPPDATA_TO%") else (set "to=%USERNAME%")
if defined COPYAPPDATA_LIST (set "list=%COPYAPPDATA_LIST%") else (set "list=%USERPROFILE%\copyappdatalist.txt")
if defined COPYAPPDATA_BACKUP (
    if "%COPYAPPDATA_BACKUP%" == "1" (
        set backup=1
    ) else if "%COPYAPPDATA_BACKUP%" == "0" (
        set backup=
    ) else (
        call:err "error: invalid COPYAPPDATA_BACKUP: `%COPYAPPDATA_BACKUP%'" "%tryformore%"
        goto end
    )
) else (
    set backup=1
)
if defined COPYAPPDATA_REVERSE (
    if "%COPYAPPDATA_REVERSE%" == "1" (
        set reverse=1
    ) else if "%COPYAPPDATA_REVERSE%" == "0" (
        set reverse=
    ) else (
        call:err "error: invalid COPYAPPDATA_REVERSE: `%COPYAPPDATA_REVERSE%'" "%tryformore%"
        goto end
    )
) else (
    set reverse=
)
exit /b
::setdefaults

:validateargs
if not defined from (
    call:err "error: no source speicifed" "%tryformore%"
    goto end
)
if not exist "C:\Users\%from%\" (
    call:err "error: user `%from%' not found"
    goto end
)
if not exist "C:\Users\%to%\" (
    call:err "error: user `%to%' not found"
    goto end
)
if not exist "%list%" (
    call:err "error: file `%list%' not found"
    goto end
)
if defined reverse (call:reverse)
set "pathfrom=C:\Users\%from%\AppData"
set "pathto=C:\Users\%to%\AppData"
exit /b
::validateargs

:reverse
set "reverse_temp=%from%"
set "from=%to%"
set "to=%reverse_temp%"
exit /b
::reverse

:doit
title %_title%: from %from% to %to%
for /f "usebackq delims=" %%i in ("%list%") do (
    if exist "%pathfrom%\%%~i" (
        if exist "%pathto%\%%~i\" (rmdir "%pathto%\%%~i\" 2>nul)
        if exist "%pathto%\%%~i" (
            if defined backup (call:backup "%%~i" || goto end)
            call:status "removing %%~i"
            del /s /q /f "%pathto%\%%~i" 1>nul
            if exist "%pathto%\%%~i" (rmdir /s /q "%pathto%\%%~i")
            if exist "%pathto%\%%~i" (
                call:err "error: failed to remove `%pathto%\%%~i'"
                goto end
            )
        )
        call:status "copying %%~i"
        if exist "%pathfrom%\%%~i\" (
            xcopy /s /y /h /i /q "%pathfrom%\%%~i\" "%pathto%\%%~i\"
        ) else (
            mkdir "%pathto%\%%~i" && rmdir "%pathto%\%%~i" 2>nul
            copy /b /y "%pathfrom%\%%~i" "%pathto%\%%~i" 1>nul
        )
    ) else (
        >&2 echo warning: source `%%~i' does not exist
    )
)
exit /b
::doit

:status
set "status=%~1"
echo %status%
title %_title%: from %from% to %to%: %status%
exit /b
::status

:backup
title %_title%: from %from% to %to%: backing up %~1
pushd "%pathto%"
echo creating a backup for %~1
tar -zcf "%~1.tgz" -- "%~1"
set ec=%errorlevel%
popd
exit /b %ec%
::backup

:version
@echo copyappdata %_version% ^(%_date%^)
@echo https://gitlab.com/lzhh/copyappdata
exit /b 0
::version

:help
call:version
@echo;
@echo usage: copyappdata [OPTIONS]
@echo    or: copyappdata --version
@echo    or: copyappdata --help
@echo;
@echo options:
@echo     --from              Specify source username
@echo     --to                Specify destination username; default is current user
@echo     --list              Specify path to file of directory list; default is file
@echo                           `copyappdatalist.txt' in current user's directory
@echo     --reverse           Switch source and destination
@echo     --no-reverse        Negate previous --reverse
@echo     --backup            Backup destination before copying; this is default
@echo     --no-backup         Do not backup destination before copying
@echo     --no-term           Pause when error, implied when no argument provided
@echo;
@echo Options `--from', `--to', `--list', `--reverse' and `--backup', if not
@echo specified, will read from environment variable `COPYAPPDATA_FROM',
@echo `COPYAPPDATA_TO', `COPYAPPDATA_LIST', `COPYAPPDATA_REVERSE' ^(1 or 0^) and
@echo `COPYAPPDATA_BACKUP' ^(1 or 0^) respectively.
exit /b 0
::help

:err
set ec=1
if %1. == . (exit /b 1)
>&2 echo %~1
shift /1
goto err

:end
if not defined term (if %ec% NEQ 0 (pause))
title %ComSpec%
exit /b %ec%
