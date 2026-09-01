# RevitAPI_VisualStudioTemplates

CEC 內部使用的 Revit 外掛開發樣板（`dotnet new` 專案樣板），基於 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates) v6.2.0 修改，加回 Revit 2021 組態並整合公司內部依賴套件。

## ⚠ 環境需求：請用 Visual Studio 2026

**這些樣板產生的專案不能用 VS 2022 建置。** 相依的 `Polyfill` 套件使用 C# 14 語法（`extension(...)`），VS 2022 內建的編譯器（Roslyn 4.14 / 最高 C# 13）看不懂，會噴一堆看似莫名其妙的錯誤，例如：

```
EnvironmentPolyfill.cs: error CS0721: 'Environment': 靜態類型不可用做為參數
BinaryPrimitivesPolyfill.cs: error CS1001: 必須是識別項
```

這些檔案不在專案裡，是 `Polyfill` 這個 source-only 套件在建置時注入的，所以在方案總管找不到。**改用 VS 2026（Roslyn 5.6 / C# 14）即可正常建置**，用 `dotnet build` 也可以。註：`LangVersion=preview` 不是解法，在 VS 2022 上會讓編譯器直接崩潰。

## 跟官方版本的差異

- **加回 Revit 2021 組態**：官方 6.2.0 版預設組態只有 R23～R27，2021 已被官方拿掉，這裡手動加回 `Debug.R21` / `Release.R21`。
- **內建 CEC 依賴套件**（僅 `revit-addin-self` / `revit-addin-application-self` / `revit-addin-module-self` 三個樣板）：
  - `PackageReference CEC_Common`（`1.0.3`，支援 Revit 2019/2020/2021/2023～2027，不支援 2022）
  - `PackageReference Microsoft.Office.Interop.Excel`，並以 `EmbedExcelInterop` target 開啟**內嵌 Interop 型別**（NoPIA）。這樣輸出不必帶那顆 1.7 MB 的 Interop DLL，也不會跟同一個 Revit 行程裡其他外掛帶的版本互撞。注意這件事**不能**寫成 `<PackageReference><EmbedInteropTypes>true</EmbedInteropTypes></PackageReference>` —— NuGet 不會傳遞這個 metadata，寫了會被靜默忽略，細節見 [TODO.md](./TODO.md)
  - `Resources\CEC.ico` 圖示資源（WPF `Resource`，可用 pack URI 存取）
  - `Properties\Resources.resx` + `Resources.Designer.cs` — 把 `CEC.ico` 也註冊進 VS 專案屬性的**「資源」頁籤**，程式碼裡用 `Properties.Resources.CEC` 取得（型別 `byte[]`）。這跟上面的 WPF `Resource` 是兩套不同機制，CEC 既有專案兩者都有，所以樣板也都保留
- **調整專案預設設定**（同上三個樣板）：
  - `UseWindowsForms=true` — 官方樣板只開 `UseWPF`，CEC 專案會用到 WinForms
  - `PlatformTarget=x64` — 配合 Excel COM interop，釘死 x64 而非 AnyCPU
  - `<Reference Include="Microsoft.CSharp"/>`（僅 `.NET Framework` 組態，即 R21～R24）— net48 用 `dynamic` 需要這顆組件，少了它會編譯失敗（`CS0656`）；Excel COM 的晚期繫結會用到。.NET 5+ 已內建，所以用 `TargetFrameworkIdentifier` 條件隔開
  - `DeployAddin=false` / `IsRepackable=false`（僅 `revit-addin-self` / `revit-addin-application-self`）— 不自動部署到 `%AppData%\Autodesk\Revit\Addins\<版本>`、也不用 ILRepack 合併組件，維持跟公司既有專案一致的建置行為。注意屬性名是 `DeployAddin`，舊版 `Nice3point.Revit.Build.Tasks` 時代叫 `DeployRevitAddin`，在 v6 SDK 上寫舊名字會被**靜默忽略**。`revit-addin-module-self` 本來就沒有這兩個屬性，SDK 預設即為 `false`
- `revit-addin-sln-self`（企業級完整方案樣板）目前**尚未客製化**，內容維持官方原樣，暫不支援 2021 組態與 CEC 依賴。
- **所有樣板短名稱都加上 `-self` 後綴**（例如 `revit-addin` → `revit-addin-self`），連同 `identity` 也一併改名。這是刻意設計：讓這份 repo 可以跟官方 `Nice3point.Revit.Templates` 套件**同時安裝、互不衝突**，不需要先移除官方套件。

## 樣板清單

| 樣板 | 短名稱 | 說明 |
|---|---|---|
| Revit AddIn | `revit-addin-self` | 單一專案外掛，含 CEC 依賴 |
| Revit AddIn Application | `revit-addin-application-self` | 多專案架構主程式，含 CEC 依賴 |
| Revit AddIn Module | `revit-addin-module-self` | 多專案架構模組元件，含 CEC 依賴 |
| Revit AddIn Solution | `revit-addin-sln-self` | 企業級完整方案（未客製化） |
| Revit Benchmark | `revit-benchmark-self` | BenchmarkDotNet 效能測試 |
| Revit Test (TUnit) | `revit-tunit-self` | TUnit 單元測試 |

## 安裝方式（維護者：從原始碼資料夾安裝）

跟官方套件短名稱不同，**不需要先移除官方 `Nice3point.Revit.Templates`**，兩邊可以並存：

```
dotnet new install "D:\Revit API\C#\RevitAPI_VisualStudioTemplates\Nice3point.Revit.Templates"
```

安裝後即可用 `dotnet new revit-addin-self -o <輸出路徑>` 等指令建立新專案（注意短名稱都要加 `-self`），或直接在 Visual Studio 的「建立新專案」精靈中選取對應樣板（名稱後面會標示 `(Self)`）。

以資料夾安裝時，template engine 是**即時讀取那個資料夾**（不會複製一份），所以改完 `.csproj` 不必重新安裝，但**資料夾不能搬走或刪掉**，否則樣板就壞了。

## 發佈給其他同事

推薦打包成單一 `.nupkg` 檔再給人，不要直接壓縮資料夾（見下方說明）。在 repo 根目錄執行：

```
dotnet pack "Nice3point.Revit.Templates\Nice3point.Revit.Templates.csproj" -o dist
```

會產出 `dist\Nice3point.Revit.Templates.Self.<版本>.nupkg`。把這個檔案給同事，請他在 PowerShell 執行：

```
dotnet new install "C:\下載路徑\Nice3point.Revit.Templates.Self.6.2.3.1.nupkg"
```

之後就能用 `dotnet new revit-addin-self`，或在 Visual Studio「建立新專案」裡選帶 `(Self)` 的樣板。要移除：

```
dotnet new uninstall Nice3point.Revit.Templates.Self
```

**改版後要重發**：把 `Nice3point.Revit.Templates.csproj` 裡的 `<Version>` 加上去，重新 `dotnet pack`，同事再 `dotnet new install` 一次新的 nupkg 即可（會直接覆蓋舊版，不必先 uninstall）。

### 為什麼不建議直接壓縮資料夾

也可以壓縮 `Nice3point.Revit.Templates\` 給對方解壓縮後 `dotnet new install <資料夾路徑>`，但有幾個缺點：

- 對方**必須把資料夾永久放在固定位置**，因為是即時掛載，資料夾一搬走或刪掉，樣板就失效
- 沒有版本概念，之後更新不好管理，也看不出對方裝的是哪一版
- 會連 `.git` 之類不必要的東西一起帶過去（除非手動排除）

nupkg 則是安裝時複製到 `%USERPROFILE%\.templateengine\packages\`，自成一份，跟來源檔案脫鉤。

### 收件人的環境需求

**對方必須有 Visual Studio 2026 或 .NET SDK 10 以上**，理由見本文件開頭的環境需求警告。另外 `CEC_Common` / `Microsoft.Office.Interop.Excel` 這兩個依賴需要對方的 NuGet 設定能連到 CEC 內部 Feed，否則建置時會還原失敗。

若之前已經按舊版說明移除過官方套件，想裝回來的話：

```
dotnet new install Nice3point.Revit.Templates
```

## 更新官方樣板時的處理方式

官方樣板改版後，若要同步更新這個 repo：

1. 重新 clone/下載對應版本的 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates)
2. 對照 `source/Nice3point.Revit.Templates/` 底下各樣板的 `.csproj`，把上面「跟官方版本的差異」列的項目重新套用一次
3. 別忘了把每個樣板 `.template.config/template.json` 的 `name` / `shortName` / `identity` 補上 `-self`（或 `(Self)`）後綴，`dotnetcli.host.json` 裡的 `usageExamples` 也一併更新，才能維持跟官方套件不衝突
4. 更新前建議用 `git diff` 比對官方新舊版本差異，確認有沒有新增/移除其他組態或套件
