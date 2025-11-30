import SwiftUI
import AVFoundation

struct VoiceMessageRowView: View {
    let isMine: Bool
    let voiceUrl: String
    let duration: Double
    let id: String
    let timestamp: String
    
    // 音声再生用の状態変数
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentProgress: Double = 0.0
    
    // タイマー（進捗バー更新用）
    @State private var timer: Timer?

    var body: some View {
        HStack {
            if isMine { Spacer() }
            
            HStack(spacing: 12) {
                // 再生/停止ボタン
                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(isMine ? .white : .blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 進捗バー（スライダー）
                    ProgressView(value: currentProgress, total: duration > 0 ? duration : 1)
                        .accentColor(isMine ? .white : .blue)
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                    
                    HStack {
                        // 時間表示 (例: 0:05)
                        // ★ ここでエラーが出ていた箇所です
                        Text(formatTime(seconds: currentProgress))
                        Spacer()
                        Text(formatTime(seconds: duration))
                    }
                    .font(.caption2)
                    .foregroundColor(isMine ? .white.opacity(0.8) : .secondary)
                }
                .frame(width: 120) // バーの幅を固定
            }
            .padding(12)
            .background(isMine ? Color.blue : Color(UIColor.systemGray5))
            .cornerRadius(16)
            
            if !isMine { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onDisappear {
            stopPlayback() // 画面から消えたら停止
        }
    }
    
    // MARK: - Actions
    
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let url = URL(string: voiceUrl) else { return }
        
        // プレイヤーがなければ作成
        if player == nil {
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            
            // 再生終了時の通知を受け取る
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { _ in
                self.isPlaying = false
                self.currentProgress = 0
                self.player?.seek(to: .zero)
                self.timer?.invalidate()
            }
        }
        
        player?.play()
        isPlaying = true
        
        // 0.1秒ごとに進捗バーを更新
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let currentTime = player?.currentTime().seconds {
                self.currentProgress = currentTime
            }
        }
    }
    
    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    private func stopPlayback() {
        player?.pause()
        player = nil
        isPlaying = false
        currentProgress = 0
        timer?.invalidate()
    }
    
    // ★★★ この関数が必要です！ struct の閉じカッコ } の内側にあるか確認してください ★★★
    private func formatTime(seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let s = Int(seconds)
        let m = s / 60
        let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}

// プレビュー用
#Preview {
    VStack {
        VoiceMessageRowView(
            isMine: true,
            voiceUrl: "https://example.com/test.m4a",
            duration: 15.0,
            id: "1",
            timestamp: "12:00"
        )
    }
}
