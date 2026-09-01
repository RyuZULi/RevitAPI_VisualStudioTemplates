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

---

# 使用者篇：安裝與更新

> 這一段是給「拿到 `.nupkg` 檔的同事」看的。維護者請看下面的「維護者篇」。

## 事前準備

1. **Visual Studio 2026，或 .NET SDK 10 以上**。VS 2022 無法建置這些樣板產生的專案，理由見本文件開頭的環境需求警告。檢查版本：

   ```
   dotnet --version
   ```

   要 `10.x` 以上。

2. **NuGet 要連得到 CEC 內部 Feed**。樣板依賴 `CEC_Common` 與 `Microsoft.Office.Interop.Excel`，連不到的話建立專案沒問題，但一建置就會還原失敗。

## 安裝與更新

你會拿到三個檔案，**請放在同一個資料夾**：

```
Nice3point.Revit.Templates.Self.<版本>.nupkg   ← 樣板本體
install.cmd                                    ← 安裝腳本（雙擊這個）
install.ps1                                    ← 安裝腳本的實作
```

### 方式一：雙擊 `install.cmd`（推薦）

**安裝和更新都是同一個動作，不用區分。** 腳本會自動：

1. 檢查 `dotnet` 是否存在、SDK 版本夠不夠（低於 10 會警告）
2. 找出資料夾裡**版號最新**的 `.nupkg`
3. `dotnet new uninstall` 移除所有舊版（沒裝過也不會出錯）
4. `dotnet new install` 安裝新版
5. 列出安裝結果供你確認

所以之後每次收到新版，就是**把新的 `.nupkg` 丟進同一個資料夾，再雙擊一次 `install.cmd`**。舊的 nupkg 留著也沒關係，腳本只會挑版號最大的。

### 方式二：手動下指令

不想用腳本的話，開 PowerShell 或命令提示字元，**依序**執行這兩行：

```
dotnet new uninstall Nice3point.Revit.Templates.Self
```

```
dotnet new install "C:\下載路徑\Nice3point.Revit.Templates.Self.6.2.3.2.nupkg"
```

**順序不能顛倒，而且第一行不能省略**（原因見下）。第一次安裝的人也照跑就好 —— 沒裝過的話第一行只會印一行「找不到範本套件」，離開代碼 0，不影響第二行。

確認裝好了：

```
dotnet new list revit
```

應該會看到 6 個名稱帶 `(Self)` 的樣板。

> **不需要先移除官方的 `Nice3point.Revit.Templates`**，兩邊可以並存 —— 這份樣板的短名稱都加了 `-self` 後綴（`revit-addin-self`、`revit-addin-application-self`…），刻意設計成不跟官方衝突。

### ⚠ 為什麼不能只跑 install

**新版不會取代舊版，兩個版本會同時留著。** 實測直接安裝新版（沒先移除）的結果：

```
> dotnet new install ...Self.1.0.1.nupkg
將使用來自 'ZZ Probe Template' 的範本。若要解決此衝突，請解除安裝發生衝突的範本套件。
成功: ZZTemplateProbe.Self@1.0.1 已安裝下列範本:

> dotnet new uninstall          # 列出已安裝清單
   ZZTemplateProbe.Self
      版本: 1.0.0               ← 舊版還在
   ZZTemplateProbe.Self
      版本: 1.0.1               ← 新版也在
```

會跳出**衝突警告**，然後兩版並存。實測上這次是新版勝出，但這是由 template engine 自行仲裁的，不保證每次都如此，也讓「你到底裝的是哪一版」變得無法確定。所以請養成**先 uninstall 再 install** 的習慣。

**`--force` 也解決不了。** 它只是把衝突訊息從錯誤降級成警告，兩個版本一樣並存：

```
> dotnet new install ...1.0.1.nupkg --force
警告:
下列範本使用相同的身分識別 'ZZTemplateProbe.Self.Item':
  • 'ZZ Probe Template' 來自 'ZZTemplateProbe.Self@1.0.0'
  • 'ZZ Probe Template' 來自 'ZZTemplateProbe.Self@1.0.1'
```

**`dotnet new` 沒有「更新」這種指令**，只能自己 uninstall + install —— 這也就是 `install.cmd` 存在的原因。

補充兩點（都實測過）：

- `dotnet new uninstall Nice3point.Revit.Templates.Self` 給的是**套件 ID，不是檔案路徑**，而且會**一次移除所有版本**，不用一版一版清。
- 如果你是第一次安裝、根本沒裝過，先跑 uninstall 只會印一行「找不到範本套件」，**離開代碼是 0，不會有任何副作用**。所以上面那兩行可以無腦照跑，不必先確認自己有沒有裝過。

## 建立專案

```
dotnet new revit-addin-self -o "D:\你的路徑\MyAddin" -n MyAddin
```

- `-o`（output）= 專案放在哪個資料夾，不存在會自動建立
- `-n`（name）= 專案名稱 / 根命名空間；省略的話用資料夾名

> ⚠ **`-o` 不要省略。** 省略時 `dotnet new` 會直接在**目前工作目錄**建立專案。命令提示字元預設停在 `C:\Windows`，在那裡裸跑會撞到系統資料夾、噴 `Access to the path is denied`；用系統管理員權限硬跑更糟，會真的把檔案散落到 `C:\Windows`。

或者更簡單 —— 直接開 **Visual Studio 2026 →「建立新專案」**，搜尋 `Revit`，選名稱後面標 `(Self)` 的那個。精靈會要你指定存放位置，就不會有目錄站錯的問題。

## 完全移除

```
dotnet new uninstall Nice3point.Revit.Templates.Self
```

---

# 維護者篇

## 從原始碼資料夾安裝（開發時用）

```
dotnet new install "D:\Revit API\C#\RevitAPI_VisualStudioTemplates\Nice3point.Revit.Templates"
```

以資料夾安裝時，template engine 是**即時讀取那個資料夾**（不會複製一份），所以：

- **改完 `.csproj` 不必重新安裝**，下次 `dotnet new` 直接拿到新內容（已實測確認）
- 改 `.template.config/template.json`（選項、名稱、identity 這類中繼資料）**可能**要重裝一次讓快取更新
- **資料夾不能搬走或刪掉**，否則樣板直接失效

## 發佈給其他同事

打包成單一 `.nupkg` 再給人，不要直接壓縮資料夾（理由見下）。流程：

1. **先把 `Nice3point.Revit.Templates.csproj` 的 `<Version>` 遞增。** 內容改了就一定要換版號 —— 同版號不同內容會讓「誰裝的是哪一版」完全無法追查。目前是 `6.2.3.2`（前三碼對齊官方基底版本 6.2.3，第四碼是我們的修訂序號）。

2. 在 repo 根目錄執行：

   ```
   dotnet pack "Nice3point.Revit.Templates\Nice3point.Revit.Templates.csproj" -o dist
   ```

   產出 `dist\Nice3point.Revit.Templates.Self.<版本>.nupkg`。

3. **把三個檔案一起給同事**（壓成一個 zip 最省事）：

   ```
   dist\Nice3point.Revit.Templates.Self.<版本>.nupkg
   dist\install.cmd
   dist\install.ps1
   ```

   `install.cmd` / `install.ps1` 是版本無關的，寫死的只有套件 ID，**改版時不用跟著改**。腳本會自動抓資料夾裡版號最新的 nupkg。

   > ⚠ **`install.ps1` 必須存成 UTF-8 with BOM，換行用 CRLF。** Windows PowerShell 5.1（也就是 `powershell.exe`，Windows 內建那個）讀 `.ps1` 時，沒有 BOM 就會用系統 ANSI 字碼頁解讀，中文註解和字串全部變亂碼，直接噴語法錯誤跑不起來。編輯這個檔案時務必確認編碼有保住（VS Code 右下角會顯示 `UTF-8 with BOM`）。
   >
   > 同理，腳本開頭那行 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` 和 `install.cmd` 裡的 `chcp 65001` 也不要拿掉，否則腳本自己印的中文訊息會是亂碼（dotnet CLI 的輸出正常，只有腳本自己的會壞，看起來會很怪）。

打包後建議快速驗一下內容有沒有問題：

```
cd <暫存資料夾>
unzip -q "<repo>\dist\Nice3point.Revit.Templates.Self.<版本>.nupkg"
```

檢查：6 個 `template.json`、3 份 `Properties\Resources.resx`、3 個 `CEC.ico`、**0 個 bin/obj 檔案**。

### 為什麼不建議直接壓縮資料夾

也可以壓縮 `Nice3point.Revit.Templates\` 給對方解壓縮後 `dotnet new install <資料夾路徑>`，但有幾個缺點：

- 對方**必須把資料夾永久放在固定位置**，因為是即時掛載，資料夾一搬走或刪掉，樣板就失效
- 沒有版本概念，之後更新不好管理，也看不出對方裝的是哪一版
- 會連 `.git` 之類不必要的東西一起帶過去（除非手動排除）

nupkg 則是安裝時複製到 `%USERPROFILE%\.templateengine\packages\`，自成一份，跟來源檔案脫鉤。

### 想把官方套件裝回來

若之前曾經移除過官方套件（早期版本的說明要求這樣做，現在不需要了）：

```
dotnet new install Nice3point.Revit.Templates
```

## 官方樣板改版時的同步方式

官方樣板改版後，若要同步更新這個 repo：

1. 重新 clone/下載對應版本的 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates)
2. 對照 `source/Nice3point.Revit.Templates/` 底下各樣板的 `.csproj`，把上面「跟官方版本的差異」列的項目重新套用一次
3. 別忘了把每個樣板 `.template.config/template.json` 的 `name` / `shortName` / `identity` 補上 `-self`（或 `(Self)`）後綴，`dotnetcli.host.json` 裡的 `usageExamples` 也一併更新，才能維持跟官方套件不衝突
4. 更新前建議用 `git diff` 比對官方新舊版本差異，確認有沒有新增/移除其他組態或套件
