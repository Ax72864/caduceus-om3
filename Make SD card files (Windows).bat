@echo off
rem Double-click: makes the OM-3 colour editor update file from OM's official OM-3 firmware 1.1.
cd /d "%~dp0"
where py >nul 2>nul && (py -3 firmware\patch.py %*) || (python firmware\patch.py %*)
echo.
pause
