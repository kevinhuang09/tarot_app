import SwiftUI
import Foundation
import Combine

// --- 1. 大腦：TarotAIViewModel ---
class TarotAIViewModel: ObservableObject {
    @Published var aiResponse: String = "等待占卜啟動..."
    @Published var isAnalyzing: Bool = false
    
    let apiKey = "AIzaSyD9KV607ZZuHv1GaVs3iH5h5ClNmHbis9g"
    let modelName = "gemini-2.5-flash"
    
    @MainActor
    func fetchTarotReading(question: String, cards: [String]) {
        
        guard cards.count >= 3 else {
            aiResponse = "牌數不足"
            return
        }
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
        
        isAnalyzing = true
        aiResponse = "🔮 占卜中..."
        
        let prompt = """
        你是一位專業的塔羅牌占卜大師。
        
        使用者問題：
        「\(question)」
        
        抽到的牌：
        1. 過去：\(cards[0])
        2. 現在：\(cards[1])
        3. 未來：\(cards[2])
        
        請提供約200字分析，語氣神秘、具啟發性，並給具體建議。
        使用繁體中文。
        """
        
        let json: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                
                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = jsonObject["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    
                    self.aiResponse = text
                } else {
                    self.aiResponse = "解析失敗"
                }
                
            } catch {
                self.aiResponse = "連線錯誤"
            }
            
            self.isAnalyzing = false
        }
    }
}

// --- 2. 畫面：ContentView ---

