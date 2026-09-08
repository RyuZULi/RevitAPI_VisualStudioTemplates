# TODO / 專案交接筆記

這份文件是寫給「接手維護這個 repo 的人或 AI」看的，目的是讓對方不用重新問一輪就能接著做。如果你是被叫來處理這個 repo 的 AI，請先讀完這份，再動手。

## 這個 repo 是什麼

CEC 內部使用的 Revit 外掛開發樣板（`dotnet new` 專案樣板 / Visual Studio「建立新專案」樣板），來源基礎是官方 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates)（clone 自 tag `6.2.0`），在上面做了公司內部客製化。

安裝、樣板清單、基本用法都寫在 [README.md](./README.md)，這份 TODO 只講「為什麼這樣改」跟「還有什麼沒做/要注意」。

## 目前已完成的客製化（照時間順序）

1. **加回 Revit 2021 組態**：官方 6.2.0 版把預設組態拿掉只剩 R23～R27，因為公司目前還有 2021 的維護專案，所以在 `revit-addin` / `revit-addin-application` / `revit-addin-module` / `revit-benchmark` / `revit-tunit` 五個樣板的 `.csproj` 裡手動加回 `Debug.R21` / `Release.R21`。`revit-addin-sln`（企業級完整方案樣板）沒有加，見下方「尚未處理」。

   注意：**只要加進 `<Configurations>` 就好**，不需要寫 `RevitVersion` / `TargetFramework` 的 PropertyGroup，原因見下方「Nice3point.Revit.Sdk 幫你做了什麼」。

2. **內建 CEC 依賴套件**（僅 `revit-addin` / `revit-addin-application` / `revit-addin-module` 三個樣板，因為只有這三個是「單一外掛專案」性質，benchmark/tunit/sln 不需要）：
   - `PackageReference CEC_Common`（目前寫死 `1.0.4`。原本是照抄 `CEC_Detection.csproj` 的 `1.0.2`，後依使用者要求升到 `1.0.3`，順帶解決了舊版在 R26 / R27 無法解析的問題，見下方「已解決」，之後再升到 `1.0.4`）
   - `PackageReference Microsoft.Office.Interop.Excel`（`16.0.18925.20022`，同樣照抄自 `CEC_Detection.csproj`）
   - `Resources\CEC.ico` 圖示資源（二進位檔，來自 `CEC_Detection` 專案的 `Resources\CEC.ico`）。這是 WPF 的 `<Resource Include>`，用 pack URI 存取
   - `Properties\Resources.resx` + `Properties\Resources.Designer.cs`（後補的）。**注意這跟上面的 WPF `Resource` 是兩套不同機制**：前者是 VS 專案屬性「資源」頁籤那一套（`.resx` 強型別資源，程式碼寫 `Properties.Resources.CEC`），後者是 WPF 資源。使用者反映「CEC.ico 在 Resources 資料夾裡，但沒出現在專案屬性→資源中」，就是因為一開始只做了 WPF 那套。兩者 `CEC_Detection.csproj` 都有，所以樣板也都保留。

     實作細節：`.resx` 裡用 `ResXFileRef` 相對路徑指向 `..\Resources\CEC.ico`，型別是 `System.Byte[]`（照抄 `CEC_Detection`，不是 `System.Drawing.Icon`），designer 產生 `public static byte[] CEC`。`Resources.Designer.cs` 的命名空間寫成 `Nice3point.Revit.AddIn._1.Properties`，套用樣板引擎的 `safe_namespace` 形式，產出時會替換成專案名稱。csproj 需要這組接線才會被 VS 認成資源設計工具：

     ```xml
     <ItemGroup>
         <Compile Update="Properties\Resources.Designer.cs">
             <DesignTime>True</DesignTime>
             <AutoGen>True</AutoGen>
             <DependentUpon>Resources.resx</DependentUpon>
         </Compile>
     </ItemGroup>
     <ItemGroup>
         <EmbeddedResource Update="Properties\Resources.resx">
             <Generator>PublicResXFileCodeGenerator</Generator>
             <LastGenOutput>Resources.Designer.cs</LastGenOutput>
         </EmbeddedResource>
     </ItemGroup>
     ```

3. **所有 6 個樣板的短名稱/識別碼都加上 `-self` 後綴**（例如 `revit-addin` → `revit-addin-self`，`identity` 從 `Nice3point.Revit.AddIn` → `Nice3point.Revit.AddIn.Self`，`dotnetcli.host.json` 的 `usageExamples` 也同步改了）。**原因**：這樣才能跟官方 `Nice3point.Revit.Templates` NuGet 套件同時安裝、不衝突——因為我們是直接複製官方原始碼改的，如果不改名，短名稱和 identity 會完全一樣，兩邊都裝著時 `dotnet new revit-addin` 這種指令會判斷不出要用哪一個。

4. **把 `Sdk="Nice3point.Revit.Sdk"` 補上版本號變成 `Sdk="Nice3point.Revit.Sdk/6.2.3"`**（僅 `revit-addin` / `revit-addin-application` / `revit-addin-module` / `revit-benchmark` / `revit-tunit` 五個樣板；`revit-addin-sln` 內部沒有直接引用這個 Sdk，見下方「尚未處理」）。

   **原因**：官方樣板的 `.csproj` 沒有帶版本號，會導致 Visual Studio 建立新專案時失敗：

   ```
   MSB4236: 找不到指定的 SDK 'Nice3point.Revit.Sdk'。
   The NuGetSdkResolver did not resolve this SDK because there was no version specified in the project or global.json.
   ```

   這是官方樣板本身就有的坑——官方 wiki 的範例程式碼都有寫版本號，只有 `dotnet new` 樣板漏帶。`6.2.3` 是配合使用者當時安裝的官方 `Nice3point.Revit.Templates` 6.2.3 版對齊的，**如果之後升級官方套件版本，這裡也要跟著改**（見下方 SOP 第 4 點）。

5. **調整專案預設設定**（僅 `revit-addin` / `revit-addin-application` / `revit-addin-module` 三個樣板），依使用者要求對齊公司既有專案 `CEC_Detection.csproj` 的行為：
   - `UseWindowsForms=true`（官方樣板只開 `UseWPF`，CEC 專案會用到 WinForms）
   - `PlatformTarget=x64`（官方新樣板不設，等同 AnyCPU；因為有 Excel COM interop，釘死 x64）
   - `DeployAddin=false`、`IsRepackable=false`（只有 `revit-addin` / `revit-addin-application` 有這兩個屬性；原本 `IsRepackable` 是 `addinLogging || useDi` 的條件式，現在改成無條件 `false`）。**使用者明確表示不需要自動建置/部署。**
   - **副作用提醒**：`IsRepackable=false` 之後，若建立專案時選了 logging 或 DI 選項，`ILRepack` 的 `PackageReference` 還在但不會作用，Serilog 等相依 DLL 不會被合併進單一組件，部署時要自己確保它們跟著走。要恢復合併就把 `IsRepackable` 改回 `true`。

6. **修好打包用的 `Nice3point.Revit.Templates.csproj`**，讓 `dotnet pack` 能產出可發佈的 nupkg（為了把樣板發給其他同事）。原本這個檔案是壞的，有兩個問題：

   - **`PackageId` 跟官方完全同名**（`Nice3point.Revit.Templates`）。這會讓收件人安裝時**覆蓋掉他自己的官方套件**，整個 `-self` 後綴設計（第 3 點）就白做了。已改成 `Nice3point.Revit.Templates.Self`，並加上 `<Version>6.2.3.1</Version>`（前三碼對齊官方基底版本，第四碼是我們的修訂序號；**每次發佈給同事前要記得遞增**）。
   - **相對路徑指向不存在的檔案**：原本引用 `..\..\.nuget\PackageIcon.png` / `..\..\License.md` / `..\..\Readme.md`。官方 repo 的版面是 `source\Nice3point.Revit.Templates\`，所以 `..\..\` 是 repo 根目錄；**這個 repo 少一層**，`..\` 才是根目錄，而且官方那三個檔案也沒 clone 進來。`dotnet pack` 會直接失敗（`error : Could not find a part of the path 'D:\Revit API\C#\.nuget'`）。已改成只包 `..\README.md`，並移除 `PackageIcon` / `PackageLicenseFile` 屬性。

   另外補了 repo 根目錄的 `.gitignore`（`bin/`、`obj/`、`*.nupkg`）——`dotnet pack` 會在 `Nice3point.Revit.Templates\` 底下產生 `bin` / `obj`，而**那個資料夾同時是 `dotnet new` 的即時掛載點**，不清掉會污染樣板來源。實測 pack 出來的 nupkg 內容乾淨，6 個樣板齊全，沒有誤包 bin/obj。

   發佈流程和收件人的安裝指令都寫在 `README.md` 的「使用者篇」與「維護者篇」章節。

   **`dotnet new install` 的更新語意（實測結果，README 早期版本寫錯過，已更正）**：用一個拋棄式測試樣板套件實測（1.0.0 → 1.0.1），結論是——

   - **新版不會取代舊版**。直接 `dotnet new install <新版>` 會印出衝突警告「將使用來自 'X' 的範本。若要解決此衝突，請解除安裝發生衝突的範本套件。」，然後**兩個版本同時留在安裝清單裡**。實測該次是新版勝出，但那是 template engine 自行仲裁的結果，不保證穩定，也讓「到底裝的是哪一版」變得無法確認。
   - 所以**正確的更新流程是先 uninstall 再 install**。
   - `dotnet new uninstall <PackageId>` 會**一次移除該套件的所有版本**，不需要逐版清理。
   - 對沒安裝過的套件跑 uninstall，只會印「找不到範本套件」，**離開代碼 0，無副作用**，所以那兩行可以無腦照跑。
   - 注意 `uninstall` 的參數：**nupkg 安裝的用「套件 ID」，資料夾安裝的用「資料夾路徑」**，兩者不同。`dotnet new uninstall`（不帶參數）會列出清單並直接告訴你每一筆正確的解除安裝指令。
   - **`--force` 解決不了這件事**（也實測過）。它只是把衝突訊息從錯誤降級成警告（`警告: 下列範本使用相同的身分識別 ...`），兩個版本一樣並存。`dotnet new` **沒有「更新」指令**。

   因此在 `dist\` 底下放了 **`install.cmd` + `install.ps1`** 兩個腳本，要跟 nupkg 一起發給同事。腳本會自動找出資料夾裡版號最新的 nupkg，先 uninstall 再 install，並檢查 SDK 版本。**腳本是版本無關的**（只寫死套件 ID），改版時不用跟著改，同事之後收到新版只要把 nupkg 丟進同資料夾再雙擊一次。

   ⚠️ **`install.ps1` 必須存成 UTF-8 with BOM + CRLF**。Windows PowerShell 5.1（`powershell.exe`）讀 `.ps1` 沒有 BOM 就會用系統 ANSI 字碼頁解讀，中文全變亂碼並直接噴語法錯誤（`字串缺少結束字元`、`遺漏 '}'`）。這在開發時實際踩到兩次——第一次是腳本本身，第二次是我寫來檢查腳本的檢查腳本。另外腳本開頭的 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` 與 `install.cmd` 的 `chcp 65001` 也不能拿掉，否則會出現「dotnet 的中文正常、腳本自己印的中文是亂碼」這種很怪的畫面。`install.cmd` 同樣用 CRLF。

7. **Excel COM interop 相關的兩項調整**（僅 `revit-addin` / `revit-addin-application` / `revit-addin-module` 三個樣板），依使用者要求加入：

   - **`.NET Framework 組態顯式參考 `Microsoft.CSharp`**。net48 用 `dynamic` 需要這顆組件，少了它編譯會報 `CS0656: 遺漏編譯器必要成員 'Microsoft.CSharp.RuntimeBinder.CSharpArgumentInfo.Create'`（已實測確認）。Excel COM 的晚期繫結大量用到 `dynamic`，所以這是必須的。.NET 5+ 已內建於執行階段（`Microsoft.NETCore.App.Ref` 裡就有），不需要也不該再手動參考，因此用 `TargetFrameworkIdentifier` 條件隔開：

     ```xml
     <ItemGroup Condition="'$(TargetFrameworkIdentifier)' == '.NETFramework'">
         <Reference Include="Microsoft.CSharp"/>
     </ItemGroup>
     ```

   - **`EmbedExcelInterop` target：把 `Microsoft.Office.Interop.Excel` 改成內嵌 Interop 型別**（NoPIA，也就是 csc 的 `/link:` 而非 `/reference:`）。好處是輸出不必帶那顆 1.7 MB 的 Interop DLL，也不會跟同一個 Revit 行程裡其他外掛帶的 Interop 版本互撞。

     **關鍵：不能寫成 `<PackageReference Include="..."><EmbedInteropTypes>true</EmbedInteropTypes></PackageReference>`。** 這是很多人會踩的坑——語法合法、建置成功、零警告，但**完全沒有作用**。原因是 `EmbedInteropTypes` 只有 `Csc` 工作項目會讀，而且是從 `ReferencePath`（組件層級）上讀；`PackageReference` 是套件層級宣告，NuGet 的 metadata 傳遞白名單裡沒有這一項（實測：`Microsoft.NET.Build.Tasks.dll` 裡根本不存在 `EmbedInteropTypes` 這個字串，但有 `Aliases`）。所以必須等 `ResolveReferences` 把套件展開成一顆顆組件之後，直接在 `ReferencePath` 上補 metadata。

     實測對照（同樣的程式碼，只差參考寫法，抓 `csc.exe` 實際收到的命令列）：

     | 寫法 | csc 收到 |
     |---|---|
     | 什麼都不寫 | `/reference:...Interop.Excel.dll` |
     | `EmbedInteropTypes` 寫在 `PackageReference` 上 | `/reference:...`（跟沒寫一樣） |
     | 本 target | `/link:...` ✅ |

     ⚠️ **另一個大坑：組件名稱一定要透過屬性間接引用，不可以寫字面值。** `dotnet new` 的模板引擎會去評估 XML 元素的 `Condition` 屬性，**只要是它看得懂的純字面比較、且結果為 false，就會把整個元素從產出的檔案裡刪掉**。實測探針結果：

     | Condition | 產出結果 |
     |---|---|
     | `'$(Foo)' == 'Bar'` | ✅ 保留（含 `$(...)`，引擎解析不了就放行） |
     | `'%(FileName)' == 'Bar'` | ❌ **整個元素被刪掉** |
     | `'x' == 'y'` | ❌ **整個元素被刪掉** |
     | `'%(FileName)' == '$(SomeProperty)'` | ✅ 保留 |

     第一版就是踩到這個——樣板檔裡寫得好好的，`dotnet new` 產出的 csproj 裡卻變成空的 `<ItemGroup></ItemGroup>`，target 形同虛設。所以最終寫法把組件名稱抽成 target 內的屬性：

     ```xml
     <Target Name="EmbedExcelInterop" AfterTargets="ResolveReferences">
         <PropertyGroup>
             <ExcelInteropAssembly>Microsoft.Office.Interop.Excel</ExcelInteropAssembly>
         </PropertyGroup>
         <ItemGroup>
             <ReferencePath Condition="'%(FileName)' == '$(ExcelInteropAssembly)'">
                 <EmbedInteropTypes>true</EmbedInteropTypes>
             </ReferencePath>
         </ItemGroup>
     </Target>
     ```

     **這個模板引擎行為對整個 repo 都適用**：以後在樣板 `.csproj` 裡新增任何帶 `Condition` 的元素，都要確認條件式裡含有 `$(...)`，否則可能被靜默刪除。改完務必實際跑一次 `dotnet new` 檢查產出，不要只看樣板原始檔。

## Nice3point.Revit.Sdk 幫你做了什麼（很重要，避免誤判「設定有缺」）

樣板用的是 `<Project Sdk="Nice3point.Revit.Sdk/6.2.3">`，這是**自訂 MSBuild Project SDK**，不是普通 NuGet 套件。它的 `Sdk.props` 會在 `.csproj` 內容之前先跑。舊世代寫法（`Microsoft.NET.Sdk` + `PackageReference Nice3point.Revit.Build.Tasks`，例如公司現有的 `CEC_Detection.csproj`）要手寫的東西，現在都由 SDK 注入。**拿舊專案逐行比對樣板會產生大量假警報。**

SDK 自動提供以下項目（可在 `~/.nuget/packages/nice3point.revit.sdk/<版本>/Sdk/` 底下查證）：

- `Nice3point.Revit.Common.props`：`Nullable=enable`、`LangVersion=latest`、`ImplicitUsings=true`、`ImplicitRevitUsings=true`、`AppendTargetFrameworkToOutputPath=false`，以及 Debug/Release 的 `DebugType` 與 `DefineConstants`
- **`RevitVersion` 與 `TargetFramework` 自動推導**：用正則 `(\d+)(?!.*\d)` 從 `Configuration` 名稱抓最後一串數字（`Debug.R21` → `21` → 長度 2 → `2021`），再查 TFM 對照表（`>=2021` net48、`>=2025` net8.0-windows7.0、`>=2027` net10.0-windows7.0）。所以**完全不需要**寫 `<PropertyGroup Condition="$(Configuration.Contains('R21'))">` 那種區塊
- `Nice3point.Revit.Common.targets`：Launch 設定 `StartAction` / `StartProgram`（指向 `Revit $(RevitVersion)\Revit.exe`）/ `StartArguments`，條件是 `LaunchRevit=true`；另有 `ValidateRevitVersion` 防呆，組態名稱沒帶版號會直接建置失敗
- `Nice3point.Revit.Publish.targets`：`DeployAddin`（預設 `false`）、`PublishAddin`、`AddinDeployDir`（預設 `$(AppData)\Autodesk\Revit\Addins\$(RevitVersion)`）
- `Nice3point.Revit.Repack.targets`：`IsRepackable=true` 時才跑 ILRepack
- 另有 `PatchManifest` / `ImplicitUsings` / `GenerateCompatibleDefineConstants` 等 targets

**屬性改名對照（舊 `Build.Tasks` 3.0.1 → 新 `Revit.Sdk` 6.x）**，遷移舊專案時最容易踩：

| 舊 | 新 |
|---|---|
| `DeployRevitAddin` | `DeployAddin` |
| `PublishRevitAddin` | `PublishAddin` |
| Target `DeployRevitAddinFiles` | Target `DeployAddin` |
| `IsRepackable` | `IsRepackable`（沒改） |

寫舊名字**不會報錯也不會警告**，MSBuild 只當成沒人讀的自訂屬性靜默忽略。若舊專案原本是 `DeployRevitAddin=true`，遷移到新 SDK 後會變成不部署，但建置全綠，極難查。

## 尚未處理 / 已知限制

- **⚠ 這些樣板產生的專案「不能用 Visual Studio 2022 建置」，必須用 VS 2026（或 `dotnet build`）**。這是最容易被誤判成樣板壞掉的問題，實測確認過：

  症狀是建置時冒出一堆來自 `Polyfill` 套件的編譯錯誤，例如 `EnvironmentPolyfill.cs` 的 **CS0721「'Environment': 靜態類型不可用做為參數」**，還有 `BinaryPrimitivesPolyfill.cs` 的 `CS1001` / `CS0106` 等等。這些檔案**不在 repo 裡**——`Polyfill` 是 source-only 套件，建置時才把 `.cs` 從 `~/.nuget/packages/polyfill/<版本>/contentFiles/` 注入專案，所以在方案總管裡找不到。

  根因：Polyfill 的程式碼用了 **C# 14 的 extension members 語法**（`extension(Environment) { ... }`，.NET 10 才有）。舊編譯器看不懂 `extension(...)`，會把它誤判成「一個叫 extension、參數型別是 Environment 的方法」，於是報 CS0721。

  | | Roslyn | 最高 C# | 結果 |
  |---|---|---|---|
  | VS 2026 (v18) | 5.6.0 | C# 14 | ✅ R21 / R24 / R25 全部建置成功，零警告 |
  | VS 2022 (v17) | 4.14.0 | C# 13 | ❌ 大量 Polyfill 編譯錯誤 |
  | `dotnet build`（SDK 10.0.300） | — | C# 14 | ✅ 正常 |

  已排除的作法：
  - **升級 `Polyfill` 到官方 6.2.3 用的 11.0.1 沒有用**——10.0.0 和 11.0.1 都用 `extension(...)`。
  - **`LangVersion=preview` 沒有用**——在 VS 2022 上會讓 `csc.exe` 直接崩潰（回傳碼 `0xE0434352`），比原本更糟。

  如果將來真的非得支援 VS 2022，唯一實測可行的辦法是**把 `Polyfill` 的 `PackageReference` 從樣板拿掉**（已驗證拿掉後 VS 2022 可以正常建置 Debug.R21）。Polyfill 是 `PrivateAssets="all"` 的開發期便利套件，把新 BCL API 補到 net48，樣板預設產生的程式碼並沒有用到它。但這樣就跟官方樣板分歧了，目前**沒有做**，因為使用者改用 VS 2026。

- **`revit-addin-sln`（企業級完整方案樣板）完全沒有客製化**：目前維持官方原樣，只有步驟 3 的改名（`revit-addin-sln` → `revit-addin-sln-self`）。沒有 2021 組態、沒有 CEC 依賴。這是使用者明確說「先不用」暫緩的項目，不是遺漏。這個樣板本身是空殼（`source/` 下只有一個 `keep.folder`），實際的外掛專案是使用者事後自己用 `revit-addin-application-self` / `revit-addin-module-self` 樣板在裡面建立，所以理論上不會直接踩到 SDK 版本號的坑，但如果之後真的要客製化這個樣板，記得一併檢查。
- **樣板內容還停在官方 6.2.0，但 SDK 版本號寫的是 6.2.3**。把官方 `Nice3point.Revit.Templates.6.2.3.nupkg`（在 `~/.templateengine/packages/`）解開比對後，發現套件版本全面落後官方 6.2.3，**尚未對齊**：`Microsoft.Extensions.DependencyInjection` / `Hosting` 10.0.5→10.0.10、`Serilog` 4.3.1→4.4.0、`ILRepack` 2.0.44→2.0.46、`JetBrains.Annotations` 2025.2.4→2026.2.0、`Polyfill` 10.0.0→11.0.1。另外 `revit-addin` 的 `UseWPF` 條件官方 6.2.3 已從 `(!isDbApplicationAddin)` 改成 `(isApplicationAddin || useUi)`。
- **`Properties\Settings.settings` / `Settings.Designer.cs` 沒有加進樣板**（專案屬性的「設定」頁籤）。`CEC_Detection.csproj` 有這組 `None Update` + `SettingsSingleFileGenerator` 接線，官方樣板從來沒有，**使用者只要求了「資源」那一套，「設定」這套還沒問過**。如果之後要補，作法跟「已完成的客製化」第 2 點的 `Resources.resx` 一樣。
- **`Clipper2` 套件沒有加進樣板**，判斷是 `CEC_Detection` 幾何運算專屬，不是通用依賴。
- **`CEC_Common` 目前釘在 `1.0.4`，之後仍要定期去 CEC 內部 NuGet Feed 確認有沒有更新版**（尤其是 Revit 出新版時）。
  （`1.0.4` 已檢查過 `build\CEC_Common.targets` 與 `lib\` 結構，支援清單、framework 對照表、`ValidateCECCommonReference` target 都與 `1.0.3` 相同，樣板不需要跟著改其他設定。）
- **✅ 已解決：`CEC_Common` 在 R26 / R27 無法解析的問題（升到 1.0.3 後消失）**。保留紀錄是因為這個坑很典型，之後升 Revit 版本時可能再遇到類似狀況。

  舊版 `1.0.2` 的問題：這個套件用非標準佈局，DLL 放在 `lib\<TFM>\revit<版本>\CEC_Common.dll`（`revit<版本>` 那一層 NuGet 根本看不懂，只認得 `lib\<TFM>\`），所以套件自帶 `build\CEC_Common.targets` 依 `RevitVersion` 手工組出 `HintPath`。但 1.0.2 只有 `revit2019/2020/2021/2023/2024` 和 `lib\net8.0-windows\revit2025`，**沒有 2026、2027**，而且 targets 的 net8.0 分支寫死 `== '2025'`，其他一律落到 net48 分支去找不存在的 `lib\net48\revit2026`。結果是 **`warning MSB3245: 找不到組件 "CEC_Common"`，但建置仍然「成功」**——產出的 DLL 其實沒有 CEC_Common，要到執行期才炸，極易忽略。

  `1.0.3` 已修好：新增 `lib\net8.0-windows7.0\revit2026` 與 `lib\net10.0-windows7.0\revit2027`，framework 對照表改成完整的三段映射，並加了 `ValidateCECCommonReference` target，遇到不支援的版本會直接 **`Error` 中止建置**而不是靜默警告。已實測 R21 / R23 / R24 / R25 / R26 / R27 全部正確解析到對應的 `revit<版本>` 資料夾，0 警告 0 錯誤。

  注意：**1.0.4 仍然不支援 Revit 2022**（支援清單是 2019, 2020, 2021, 2023, 2024, 2025, 2026, 2027）。目前樣板沒有 R22 組態，所以不影響；若之後要加回 2022，得先請套件維護者補。
- **這份 repo 的早期修改是在一個沒有 `dotnet` CLI 的雲端沙盒環境裡完成的**，那批修改只做了「文字/檔案層級」的正確性檢查（讀 `.template.config/template.json`、`.csproj` 內容比對），**沒有實際跑過 `dotnet new` 或建置驗證**。那個階段的驗證都是請使用者在自己的 Windows 機器上實際用 Visual Studio 建立測試專案來確認（例如上面第 4 點的 SDK 版本號問題，就是這樣測出來的）。如果你是接手的 AI 且沒有能操作使用者機器的管道，記得明確告知使用者「這個改動需要你在本機測試」，不要假設它一定沒問題。

  **第 5 點的修改已經在使用者機器上實測過**（dotnet 10.0.300）：`dotnet new revit-addin-self` 產出的專案含新設定；`dotnet msbuild -getProperty` 確認各組態的 `RevitVersion` / `TargetFramework` / `PlatformTarget` 推導正確；`dotnet build` 在 R21 / R23 / R24 / R25 / R26 / R27 全部建置成功（當時 R26 / R27 有 `CEC_Common` 1.0.2 的警告，升到 1.0.3 後已消失）。

  **第 7 點的修改也已在本機實測**（dotnet 10.0.300）：`dotnet new revit-addin-self` 產出的 csproj 確認 target 完整未被模板引擎刪除；`dotnet build` 在 Debug.R21 / R23 / R24 / R25 / R26 / R27 六個組態全部 **0 警告 0 錯誤**；逐一檢查 `csc.exe` 的實際命令列，確認 `Microsoft.Office.Interop.Excel` 一律是 `/link:`、`Microsoft.CSharp.dll` 有進參考（net48 來自本 repo 加的 `<Reference>`，net8/net10 來自框架內建）、`CEC_Common` 解析到正確的 `1.0.3\lib\<TFM>\revit<版本>`。

  **更正（2026-09-08 實測）**：早期紀錄寫「`bin` 底下沒有 `Microsoft.Office.Interop.Excel.dll`」是錯的。實際重測六個組態，`csc` 確實一律用 `/link:`（內嵌有生效），但那顆 1.77 MB 的 Interop DLL **仍然會被複製到 `bin`**。原因是「要不要複製到輸出」是由 `ReferenceCopyLocalPaths` 決定，而這個項目清單在 `ResolveReferences` 內部就算好了；`EmbedExcelInterop` 是 `AfterTargets="ResolveReferences"` 才跑，來不及影響它。
  若要連複製也一併擋掉，在 target 的 `<ItemGroup>` 裡補一行即可（已在暫存專案實測，R21 / R27 均 0 警告 0 錯誤，且 `bin` 不再出現該 DLL）：

  ```xml
  <ReferenceCopyLocalPaths Remove="@(ReferenceCopyLocalPaths)" Condition="'%(FileName)' == '$(ExcelInteropAssembly)'"/>
  ```

  這一行**尚未**套用到樣板，等使用者決定。

- **樣板是以「資料夾」形式註冊給 template engine 的**（`~/.templateengine/packages.json` 裡這個 repo 的 `MountPointUri` 直接指向 `D:\Revit API\C#\RevitAPI_VisualStudioTemplates\Nice3point.Revit.Templates`，不是複製成 nupkg）。**所以改完 `.csproj` 不需要重跑 `dotnet new install`**，下次 `dotnet new` 會直接讀資料夾裡的新內容（已實測確認）。但如果改的是 `.template.config/template.json`（選項、名稱、identity 那些中繼資料），就可能要重裝一次讓快取更新。

## 之後官方樣板改版時的標準流程（SOP）

1. 重新 clone/下載對應版本的 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates)。也可以直接把官方 `Nice3point.Revit.Templates.<版本>.nupkg` 解壓縮來比對（`dotnet new install` 過的話會在 `~/.templateengine/packages/`），比 clone 快。
2. 對照 `source/Nice3point.Revit.Templates/` 底下各樣板的 `.csproj`，把上面「已完成的客製化」1、2、5、7 點重新套用一次（2021 組態、CEC 依賴/圖示、WinForms/x64/deploy 設定、Microsoft.CSharp 與 `EmbedExcelInterop` target）。
3. 把每個樣板 `.template.config/template.json` 的 `name` / `shortName` / `identity` 補上 `-self`（或 `(Self)`）後綴，`dotnetcli.host.json` 裡的 `usageExamples` 也一併更新（對應「已完成的客製化」3 點）。
4. **檢查新版官方 `Nice3point.Revit.Sdk` 的版本號，把 `.csproj` 裡 `Sdk="Nice3point.Revit.Sdk/x.y.z"` 的版本號同步更新**（對應第 4 點）——這點很容易忘記，忘了就會在使用者端重現 MSB4236 錯誤。
5. 順便去 `~/.nuget/packages/nice3point.revit.sdk/<新版本>/Sdk/` 掃一次 props/targets，確認有沒有屬性改名或預設值變動（v6 就發生過 `DeployRevitAddin` → `DeployAddin` 這種靜默失效的改名）。
6. 更新前後都建議用 `diff` 比對官方新舊版本差異，確認有沒有新增/移除其他組態、套件或樣板結構。
7. 改完後同步更新 `README.md`（使用者看的安裝/差異說明）跟這份 `TODO.md`（如果又有新的已知限制或待辦事項）。

## 給接手 AI 的提醒

- 不要憑印象猜測 Nice3point 套件的行為，實際 clone 原始碼、解開 NuGet 套件看 props/targets，或查官方 GitHub Wiki / Changelog 驗證（這份 repo 目前的每一個結論都是這樣查出來的，包括 SDK 版本號的坑跟 `DeployAddin` 改名）。
- **改完樣板 `.csproj` 一定要實際跑 `dotnet new` 產生一次專案，比對產出檔案的內容，再 `dotnet build` 跑過各組態。** 光看樣板原始檔不夠——模板引擎會刪掉 `Condition` 為 false 的元素（見「已完成的客製化」第 7 點），而 MSBuild 對不認識的屬性/metadata 一律靜默忽略（見上方 `DeployRevitAddin` 改名、以及 `PackageReference` 上的 `EmbedInteropTypes`）。這個 repo 已經踩過三次同一類型的坑：**改了、建置成功、零警告，但完全沒有生效。** 驗證方式是抓 `csc.exe` 的實際命令列：`dotnet build -c <組態> -v:n -t:Rebuild` 然後 grep `/reference:` 或 `/link:`。
- 使用者習慣自己 review/push git commit，不要自作主張直接推上使用者的 GitHub，只需要準備好改動並給一行式的 commit 訊息。
- 使用者要求 commit 訊息「一行就好」，方便之後用 `git log --oneline` 辨識。
- 這個檔案請務必存成 **UTF-8（無 BOM）**。曾經發生過寫入時編碼損毀，導致第 4 點整段變成亂碼、且夾帶一個非法 byte，讓後續工具無法讀取。
