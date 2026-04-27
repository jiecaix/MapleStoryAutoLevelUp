@echo off
setlocal enabledelayedexpansion

#############################################
# MapleStory AutoBot Performance Profiler
# Uses py-spy to generate flame graph
#############################################

REM Default values
set CONFIG_FILE=config/config_custom.yaml
set DURATION=30

REM Parse arguments
:parse_args
if "%~1"=="" goto :end_parse
if /i "%~1"=="--config" (
    set CONFIG_FILE=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--duration" (
    set DURATION=%~2
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="-h" goto :usage
if /i "%~1"=="--help" goto :usage
echo [ERROR] Unknown option: %~1
echo Use --help for usage information
exit /b 1

:end_parse
echo ========================================
echo MapleStory AutoBot Performance Profiler
echo ========================================
echo.

REM Check if py-spy is installed
python -c "import py_spy" 2>nul
if errorlevel 1 (
    echo [INFO] Installing py-spy...
    pip install py-spy
    if errorlevel 1 (
        echo [ERROR] Failed to install py-spy
        exit /b 1
    )
)

REM Check if config file exists
if not exist "%CONFIG_FILE%" (
    echo [ERROR] Config file not found: %CONFIG_FILE%
    exit /b 1
)

echo [1/3] Starting MapleStory AutoBot...
echo     Config: %CONFIG_FILE%
start /B python -m src.main --config "%CONFIG_FILE%"

REM Wait for process to start
echo Waiting for program to start...
timeout /t 5 /nobreak >nul

echo.
echo [2/3] Finding Python process...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq python.exe" /FO CSV ^| findstr /r "python.exe"') do (
    set PYTHON_PID=%%~a
    goto :found_pid
)

echo [ERROR] Could not find Python process
exit /b 1

:found_pid
echo     PID: !PYTHON_PID!
echo.
echo [3/3] Starting py-spy profiling...
echo     Duration: %DURATION%s
echo     Output: profile.svg
echo.

REM Run py-spy
py-spy record --pid !PYTHON_PID! --output profile.svg --duration %DURATION%

if exist profile.svg (
    echo.
    echo ========================================
    echo SUCCESS! Profile saved to profile.svg
    echo ========================================
    echo.
    echo Open profile.svg in your browser to see:
    echo   - Which functions consume the most CPU
    echo   - The complete call stack
    echo   - Performance bottlenecks
    echo.
    start profile.svg
) else (
    echo [ERROR] Failed to generate profile.svg
    exit /b 1
)

REM Cleanup
echo.
echo Stopping MapleStory AutoBot...
taskkill /F /IM python.exe >nul 2>&1

goto :eof

:usage
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --config FILE     Configuration file (default: config/config_custom.yaml)
echo   --duration SECONDS Sampling duration in seconds (default: 30)
echo   -h, --help        Show this help message
echo.
echo Example:
echo   %~nx0 --config config/config_default.yaml --duration 60
exit /b 0
