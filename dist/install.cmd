@echo off
REM 雙擊這個檔案即可安裝 / 更新 CEC Revit 外掛樣板。
REM chcp 65001 把主控台切成 UTF-8，中文訊息才不會變亂碼。
REM -ExecutionPolicy Bypass 用來避開預設執行原則對 .ps1 的封鎖。
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
pause
