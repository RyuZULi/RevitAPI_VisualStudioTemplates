# RevitAPI_VisualStudioTemplates

CEC 內部使用的 Revit 外掛開發樣板（`dotnet new` 專案樣板），基於 [Nice3point/RevitTemplates](https://github.com/Nice3point/RevitTemplates) v6.2.0 修改，加回 Revit 2021 組態並整合公司內部依賴套件。

## 跟官方版本的差異

- **加回 Revit 2021 組態**：官方 6.2.0 版預設組態只有 R23～R27，2021 已被官方拿掉，這裡手動加回 `Debug.R21` / `Release.R21`。
- **內建 CEC 依賴套件**（僅 `revit-addin-self` / `revit-addin-application-self` / `revit-addin-module-self` 三個樣板）：
  - `PackageReference CEC_Common`
  - `PackageReference Microsoft.Office.Interop.Excel`
  - `Resources\CEC.ico` 圖示資源
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

## 安裝方式

跟官方套件短名稱不同，**不需要先移除官方 `Nice3point.Revit.Templates`**，兩邊可以並存：

```
dotnet new install "D:\Revit API\C#\RevitAPI_VisualStudioTemplates\Nice3point.Revit.Templates"
```

安裝後即可用 `dotnet new revit-addin-self -o <輸出路徑>` 等指令建立新專案（注意短名稱都要加 `-self`），或直接在 Visual Studio 的「建立新專案」精靈中選取對應樣板（名稱後面會標示 `(Self)`）。

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
