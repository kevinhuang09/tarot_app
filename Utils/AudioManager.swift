import AVFoundation
import SwiftUI

class AudioManager { // 👈 這裡把 : ObservableObject 刪掉
    static let shared = AudioManager()
    var player: AVAudioPlayer?

    func playSound(named name: String) {
        // 從 UserDefaults 讀取設定
        let isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled")
        
        // 取得音量，如果從未設定過（值為0），預設給 0.5
        var volumeLevel = UserDefaults.standard.double(forKey: "volumeLevel")
        if UserDefaults.standard.object(forKey: "volumeLevel") == nil {
            volumeLevel = 0.5
        }

        guard isSoundEnabled,
              let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = Float(volumeLevel)
            player?.play()
        } catch {
            print("音效播放失敗: \(error)")
        }
    }
}
