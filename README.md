# Tarot App

一個使用 SwiftUI 開發的 iOS 塔羅牌應用程式，包含卡牌抽取互動介面、聲音效果，以及由本地客製化大語言模型驅動的 AI 牌義解讀。

App 透過 ngrok 將本機的 AI 推論服務對外轉發，後端使用基於 **Gemma 9B** 經個人客製化（fine-tune / prompt-tuned）後產生的塔羅專用模型 **`tarot_master`**，負責生成每張牌與整體牌陣的解讀內容。

---

## 主要功能
- **直觀的抽牌互動**：卡片堆疊、翻牌與位移動畫（`Components/CardStackView`、`Components/SmallCardView`）。
- **AI 輔助塔羅解讀**：由客製模型 `tarot_master` 即時生成牌義（`ViewModels/TarotAIViewModel.swift`）。
- **沉浸式音效**：背景與卡片音效（`Utils/` 內的 `.mp3`，如 `Moonlight.mp3`）。
- **完整畫面流程**：首頁、抽牌頁、結果頁、設定頁等（`Views/`）。

---

## 系統需求
- **macOS**：本專案為 iOS 專案，需在 Mac 上以 Xcode 開發與建置。
- **Xcode 14 或以上**（含 SwiftUI 支援）。
- **iOS 模擬器或實機**進行測試。
- 可運行 AI 模型的本機環境（用於跑 `tarot_master`）與 **ngrok**（將本機服務對外轉發）。

---

## 專案結構

```
TarotApp/
├── TarotApp/                 # 主要 App 檔案
│   ├── TarotAppApp.swift     # App 進入點
│   ├── ContentView.swift     # 根畫面
│   └── Assets.xcassets       # 圖片資源
├── Views/                    # 各畫面實作
│   ├── HomeView.swift
│   ├── CardDrawingView.swift
│   ├── ResultView.swift
│   └── SettingsView.swift
├── ViewModels/               # 視圖對應的邏輯層
│   └── TarotAIViewModel.swift
├── Models/                   # 資料模型
│   └── TarotModel.swift
├── Components/               # 可重用元件
│   ├── CardStackView.swift
│   ├── SmallCardView.swift
│   └── MoonBackgroundView.swift
└── Utils/                    # 工具與資源
    ├── AppColors.swift
    ├── AudioManager.swift
    ├── Color+Extension.swift
    └── *.mp3                 # 背景與卡片音效
```

---

## 開發 & 執行步驟
1. 使用 Xcode 開啟專案：開啟 `TarotApp.xcodeproj`。
2. 選擇模擬器或連接實機。
3. 按下 Run（⌘R）建置並執行。

> ⚠️ 本專案僅能在 macOS 上以 Xcode 建置、執行（iOS 專案特性）。

---

## AI 服務架構（tarot_master）

### 架構概覽
```
iOS App (TarotAIViewModel)
        │  HTTPS 請求
        ▼
   ngrok 公開網址
        │  轉發
        ▼
本機 AI 推論服務 (Gemma 9B → 客製模型 tarot_master)
        │
        ▼
    回傳解讀文字
```

App 不直接連到本機，而是呼叫 ngrok 產生的公開網址，由 ngrok 轉發到本機正在運行的 `tarot_master` 模型服務。

### 設定步驟
1. 在本機啟動 `tarot_master` 推論服務（例如以 Ollama 載入客製模型，預設埠 `11434`）。
2. 啟動 ngrok 將該埠對外轉發：
   ```bash
   ngrok http 11434
   ```
3. 取得 ngrok 提供的公開網址（例如 `https://xxxx-xx-xx-xx-xx.ngrok-free.app`）。
4. 將該網址設定到 App 中（建議以環境變數或本地未上傳的設定檔管理，**切勿**硬編碼或提交到版本控制）。

### API 呼叫範例

> 以下以本地 LLM 常見的 Ollama 風格 `/api/generate` 介面為例，請依你實際的服務端點調整路徑與欄位。

**Endpoint**
```
POST https://<your-ngrok-url>/api/generate
```

**cURL 範例**
```bash
curl -X POST "https://<your-ngrok-url>/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tarot_master",
    "prompt": "請以塔羅大師的口吻，解讀「愚者（正位）」在感情面向的牌義。",
    "stream": false
  }'
```

**回應範例**
```json
{
  "model": "tarot_master",
  "created_at": "2026-06-29T00:00:00Z",
  "response": "愚者正位代表全新的開始與純粹的心……",
  "done": true
}
```

**Swift（URLSession）呼叫範例**
```swift
struct TarotRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct TarotResponse: Decodable {
    let response: String
    let done: Bool
}

func fetchReading(prompt: String) async throws -> String {
    // 建議從設定檔 / 環境變數讀取，勿硬編碼
    guard let url = URL(string: "https://<your-ngrok-url>/api/generate") else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = TarotRequest(model: "tarot_master", prompt: prompt, stream: false)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(TarotResponse.self, from: data)
    return decoded.response
}
```

> 💡 若你的服務其實是 OpenAI 相容格式（`/v1/chat/completions`），只需替換 endpoint 路徑與請求/回應欄位即可，呼叫流程相同。

---

## 設定與注意事項
- **ngrok 網址管理**：ngrok 免費版每次重啟網址會變動，請在 App 設定頁或設定檔中保留可更新的入口，避免寫死。
- **金鑰與機敏資訊**：若服務需要 API 金鑰或 token，請以環境變數或本地未上傳的設定檔（如 `.env`、Xcode 環境設定）管理，切勿提交至版本控制。
- **音訊檔案**：`Utils/` 下包含多個 `.mp3`，請確認打包時已被納入 **Build Phases → Copy Bundle Resources**。

---

## 開發建議
- 在修改 ViewModels 時加入單元測試（如有測試框架）。
- 使用 Asset Catalog 管理圖片與音訊，保持專案整潔。
- 針對 AI 請求加入逾時、錯誤處理與重試機制，提升 ngrok 連線不穩時的體驗。

---

## 常見問題（FAQ）

**Q：找不到音效或資源？**
A：確認 `Assets.xcassets` 或 Build Phases 的 Copy Bundle Resources 是否包含該檔案。

**Q：AI 功能呼叫失敗 / 沒有回應？**
A：依序檢查 —— (1) 本機 `tarot_master` 服務是否正在運行；(2) ngrok 是否啟動且網址正確；(3) App 內設定的網址是否為最新的 ngrok 網址；(4) 觀察本機服務與網路請求日誌。

**Q：每次都要重設網址很麻煩？**
A：可考慮使用 ngrok 付費版的固定網域，或自架反向代理 / 內網穿透服務取得固定入口。

---

## 貢獻指南
1. Fork 本專案並建立分支（`feature/描述` 或 `fix/描述`）。
2. 寫明變更內容並提交 PR。請勿提交含敏感金鑰或個人資訊的檔案。

---

## 貢獻者

| 貢獻者 | 負責項目 |
| --- | --- |
| **kevinhuang09** | Code 架構打造、Code 撰寫 |
| **MikeWang1224** | 圖片生成、Code 撰寫 |

感謝以上夥伴對本專案的貢獻 🙌