# CEC Revit 外掛樣板 - 安裝 / 更新腳本
#
# 用法：把這個檔案跟 .nupkg 放在同一個資料夾，然後執行 install.cmd（或直接跑這個 .ps1）。
# 它會自動找出資料夾裡版號最新的 nupkg，移除所有舊版之後再安裝。

$ErrorActionPreference = 'Stop'
$PackageId = 'Nice3point.Revit.Templates.Self'
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Windows PowerShell 5.1 預設用系統 ANSI 字碼頁輸出，中文會變亂碼。
# dotnet CLI 自己會設成 UTF-8，這裡跟它一致，訊息才不會一半正常一半亂碼。
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-Step($n, $text) {
    Write-Host ""
    Write-Host "[$n] $text" -ForegroundColor Cyan
}

Write-Host "=== CEC Revit 外掛樣板 安裝 / 更新 ===" -ForegroundColor White

# --- 檢查 dotnet ---
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) {
    Write-Host ""
    Write-Host "找不到 dotnet 指令。請先安裝 Visual Studio 2026 或 .NET SDK 10 以上。" -ForegroundColor Red
    Write-Host "下載： https://dotnet.microsoft.com/download"
    exit 1
}

$sdkVersion = (& dotnet --version).Trim()
Write-Host "偵測到 .NET SDK $sdkVersion"

$major = 0
[void][int]::TryParse(($sdkVersion -split '\.')[0], [ref]$major)
if ($major -lt 10) {
    Write-Host ""
    Write-Host "警告：偵測到的 SDK 是 $sdkVersion，低於需要的 10.x。" -ForegroundColor Yellow
    Write-Host "      樣板可以裝，但產生的專案「建置時」會失敗（Polyfill 套件用了 C# 14 語法）。" -ForegroundColor Yellow
    Write-Host "      請改用 Visual Studio 2026，VS 2022 不支援。" -ForegroundColor Yellow
}

# --- 找出版號最新的 nupkg ---
$candidates = Get-ChildItem -Path $Here -Filter "$PackageId.*.nupkg" -ErrorAction SilentlyContinue
if (-not $candidates) {
    Write-Host ""
    Write-Host "在下列資料夾找不到 $PackageId.*.nupkg：" -ForegroundColor Red
    Write-Host "  $Here"
    Write-Host "請確認這個腳本跟 .nupkg 檔放在同一個資料夾。"
    exit 1
}

$prefix = [regex]::Escape("$PackageId.")
$nupkg = $candidates |
    Sort-Object {
        $v = $_.BaseName -replace "^$prefix", ''
        try { [version]$v } catch { [version]'0.0.0.0' }
    } |
    Select-Object -Last 1

Write-Host "找到套件檔： $($nupkg.Name)"

# --- 移除舊版 ---
# dotnet new uninstall 吃的是「套件 ID」，而且會一次移除所有版本。
# 沒安裝過的話只會印一行「找不到範本套件」，離開代碼 0，不影響後續。
Write-Step '1/3' '移除已安裝的舊版...'
& dotnet new uninstall $PackageId

# --- 安裝新版 ---
# 必須先移除再安裝。直接安裝新版不會取代舊版，兩個版本會並存並跳出衝突警告，
# 之後就無法確定實際生效的是哪一版。
Write-Step '2/3' "安裝 $($nupkg.Name) ..."
& dotnet new install $nupkg.FullName
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "安裝失敗（離開代碼 $LASTEXITCODE）。" -ForegroundColor Red
    exit $LASTEXITCODE
}

# --- 驗證 ---
Write-Step '3/3' '確認安裝結果...'
& dotnet new list revit

Write-Host ""
Write-Host "完成。" -ForegroundColor Green
Write-Host ""
Write-Host "建立新專案的方式（二選一）："
Write-Host "  1. Visual Studio 2026 -> 建立新專案 -> 搜尋 Revit -> 選名稱帶 (Self) 的樣板"
Write-Host '  2. dotnet new revit-addin-self -o "D:\你的路徑\MyAddin" -n MyAddin'
Write-Host ""
Write-Host '     注意 -o 不要省略，否則會在目前工作目錄建立專案。' -ForegroundColor Yellow
