import SwiftUI
import AVFoundation
import PhotosUI

// --- 画像表示用のRowView ---
struct ImageMessageRowView: View {
    let isMine: Bool
    let imageUrl: String
    
    var body: some View {
        HStack {
            if isMine { Spacer() }
            
            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 150, height: 150)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 300)
                        .cornerRadius(12)
                case .failure:
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .frame(width: 150, height: 150)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                @unknown default:
                    EmptyView()
                }
            }
            
            if !isMine { Spacer() }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// --- テキストメッセージRow ---
private struct MessageRowView: View {
    let isMine: Bool
    let message: Message

    var body: some View {
        HStack {
            if isMine {
                Spacer()
                Text(message.text)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding(10)
                    .background(Color(UIColor.systemGray5))
                    .cornerRadius(10)
                    .frame(maxWidth: 300, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .id(message.id)
    }
}

// --- メッセージリスト ---
// ★★★ Bindingエラーの対策：ここは 'let messages: [Message]' で定義し、Bindingは使いません ★★★
private struct MessageListView: View {
    let messages: [Message]
    let myUserId: String?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        if message.messageType == "voice", let url = message.voiceUrl {
                            VoiceMessageRowView(
                                isMine: message.senderId == myUserId,
                                voiceUrl: url,
                                duration: message.voiceDuration ?? 0,
                                id: message.id,
                                timestamp: message.timestamp
                            )
                        } else if message.messageType == "image", let url = message.imageUrl {
                            ImageMessageRowView(
                                isMine: message.senderId == myUserId,
                                imageUrl: url
                            )
                        } else {
                            MessageRowView(
                                isMine: message.senderId == myUserId,
                                message: message
                            )
                        }
                    }
                }
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onAppear {
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

// --- メインビュー ---
struct ConversationView: View {
    // ★★★ 修正: Thread -> DMThread ★★★
    let thread: DMThread
    @ObservedObject var viewModel: DMViewModel

    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var voiceRecorderViewModel = VoiceRecorderViewModel()

    @State private var messageText = ""
    @State private var recipientNickname: String? = nil

    @State private var showingBlockAlert = false
    @State private var showingBlockSuccessToast = false
    @State private var isProcessingAction = false
    @State private var showingSendErrorAlert = false
    @State private var sendErrorMessage = ""
    
    @State private var lastCompletedQuestionTitle: String = ""
    @State private var showQuestionTitle = false
    
    @State private var previewPlayer: AVAudioPlayer?
    @State private var isPreviewPlaying = false
    
    // 画像選択用ステート
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    private var opponentId: String? {
        guard let myUserId = authViewModel.userSub else { return nil }
        return thread.participants.first(where: { $0 != myUserId })
    }

    private var isOpponentBlocked: Bool {
        guard let opponentId = opponentId else { return false }
        return profileViewModel.isBlocked(userId: opponentId)
    }

    private var navigationTitleNickname: String {
        if showQuestionTitle && !lastCompletedQuestionTitle.isEmpty {
            return lastCompletedQuestionTitle
        } else {
            if let nick = recipientNickname { return nick.isEmpty ? "(未設定)" : nick }
            return "読み込み中..."
        }
    }

    private var toolbarMenuButton: some View {
        Menu {
            if let opponentId = opponentId, authViewModel.userSub != opponentId {
                Button(role: isOpponentBlocked ? .none : .destructive) {
                    if isOpponentBlocked {
                        Task {
                            isProcessingAction = true
                            _ = await profileViewModel.removeBlock(blockedUserId: opponentId)
                            isProcessingAction = false
                        }
                    } else {
                        showingBlockAlert = true
                    }
                } label: {
                    if isOpponentBlocked {
                        Label("ブロックを解除する", systemImage: "hand.thumbsup")
                    } else {
                        Label("このユーザーをブロックする", systemImage: "hand.raised.slash")
                    }
                }
                .disabled(isProcessingAction)
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ★★★ 修正：MessageListViewの定義と使用箇所の型を一致させます ★★★
            MessageListView(messages: viewModel.messages, myUserId: authViewModel.userSub)
            Divider()
            inputAreaView
        }
        .navigationTitle(navigationTitleNickname)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button(action: {
                    if !lastCompletedQuestionTitle.isEmpty {
                        withAnimation {
                            showQuestionTitle.toggle()
                        }
                    }
                }) {
                    VStack(spacing: 2) {
                        Text(navigationTitleNickname)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !lastCompletedQuestionTitle.isEmpty {
                            if showQuestionTitle {
                                Text("タップで相手名に戻す")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("タップで最後に正解した質問を表示")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) { toolbarMenuButton }
        }
        .overlay(alignment: .top) {
            if showingBlockSuccessToast {
                Text("ブロックしました。")
                    .font(.caption)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .padding(.top, 8)
            }
        }
        .alert("ブロックの確認", isPresented: $showingBlockAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("ブロックする", role: .destructive) {
                guard let opponentId = opponentId else { return }
                Task {
                    isProcessingAction = true
                    let success = await profileViewModel.addBlock(blockedUserId: opponentId)
                    isProcessingAction = false
                    if success {
                        withAnimation { showingBlockSuccessToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { showingBlockSuccessToast = false }
                        }
                        dismiss()
                    }
                }
            }
        } message: {
            Text("このユーザーをブロックしますか？\n（相手からのDMが拒否され、一覧からも非表示になります）")
        }
        .alert("送信エラー", isPresented: $showingSendErrorAlert) {
            Button("OK") {}
        } message: {
            Text(sendErrorMessage)
        }
        .task {
            viewModel.setAuthViewModel(authViewModel)
            await viewModel.fetchMessages(threadId: thread.threadId)
            
            if let myUserId = authViewModel.userSub {
                print("✅ [ConversationView] スレッド開封：threadId=\(thread.threadId)")
                ThreadReadTracker.shared.markSeen(userId: myUserId, threadId: thread.threadId, date: Date())
            }
            
            if let opponentId = opponentId {
                self.recipientNickname = await profileViewModel.fetchNickname(userId: opponentId)
            }
            
            self.lastCompletedQuestionTitle = thread.questionTitle
            print("✅ 最後に正解した質問を設定：\(thread.questionTitle)")
        }
        .onDisappear {
            stopPreviewPlayback()
        }
    }

    private var inputAreaView: some View {
        VStack(spacing: 0) {
            // 1. 音声録音中のプレビュー
            if voiceRecorderViewModel.isRecording {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundColor(.red)
                    
                    Text(String(format: "%.1f秒", voiceRecorderViewModel.recordingTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: { voiceRecorderViewModel.cancelRecording() }) {
                        Text("キャンセル")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            // 2. 録音完了後のプレビュー
            else if voiceRecorderViewModel.audioData != nil {
                HStack {
                    Button(action: togglePreviewPlayback) {
                        Image(systemName: isPreviewPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    Text("録音データ (\(String(format: "%.1f", voiceRecorderViewModel.recordingTime))秒)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        stopPreviewPlayback()
                        voiceRecorderViewModel.audioData = nil
                        voiceRecorderViewModel.recordingTime = 0
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(16)
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            // 3. 画像プレビュー
            else if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                HStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            Button(action: {
                                selectedItem = nil
                                selectedImageData = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black))
                            }
                            .padding(4),
                            alignment: .topTrailing
                        )
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // 4. 入力コントロール
            HStack(alignment: .bottom, spacing: 8) {
                if !voiceRecorderViewModel.isRecording {
                    Button(action: {
                        voiceRecorderViewModel.startRecording()
                    }) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 20))
                            .foregroundColor((voiceRecorderViewModel.audioData != nil) ? .blue : .gray)
                            .padding(10)
                            .background(Color(UIColor.systemGray6))
                            .clipShape(Circle())
                    }
                } else {
                    Button(action: {
                        voiceRecorderViewModel.stopRecording()
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(selectedImageData != nil ? .blue : .gray)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .clipShape(Circle())
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data),
                               let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                                await MainActor.run {
                                    selectedImageData = compressed
                                }
                            }
                        }
                    }
                }
                
                TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            (!messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || voiceRecorderViewModel.audioData != nil || selectedImageData != nil)
                            ? Color.blue : Color.gray
                        )
                        .clipShape(Circle())
                }
                .disabled(
                    (messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && voiceRecorderViewModel.audioData == nil && selectedImageData == nil) ||
                    viewModel.isLoading
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    private func togglePreviewPlayback() {
        if isPreviewPlaying {
            stopPreviewPlayback()
        } else {
            guard let data = voiceRecorderViewModel.audioData else { return }
            do {
                stopPreviewPlayback()
                previewPlayer = try AVAudioPlayer(data: data)
                previewPlayer?.prepareToPlay()
                previewPlayer?.play()
                isPreviewPlaying = true
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                    if let p = previewPlayer, !p.isPlaying {
                        isPreviewPlaying = false
                        timer.invalidate()
                    }
                    if previewPlayer == nil {
                        timer.invalidate()
                    }
                }
            } catch {
                print("Preview Playback Error: \(error)")
            }
        }
    }
    
    private func stopPreviewPlayback() {
        previewPlayer?.stop()
        isPreviewPlaying = false
        previewPlayer = nil
    }

    private func sendMessage() {
        stopPreviewPlayback()
        
        guard let senderId = authViewModel.userSub,
              let recipientId = opponentId else {
            return
        }
        
        if let imageData = selectedImageData {
            Task {
                // ★★★ 修正: DMThread に変更 ★★★
                let threadResult: DMThread? = await viewModel.sendInitialDMAndReturnThread(
                    recipientId: recipientId,
                    senderId: senderId,
                    questionTitle: thread.questionTitle,
                    messageText: "（画像メッセージ）",
                    imageData: imageData
                )
                
                if threadResult != nil {
                    selectedItem = nil
                    selectedImageData = nil
                    await viewModel.fetchMessages(threadId: thread.threadId)
                    print("✅ 画像メッセージ送信完了")
                } else {
                    sendErrorMessage = "画像の送信に失敗しました。"
                    showingSendErrorAlert = true
                }
            }
            return
        }
        
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            Task {
                let success = await viewModel.sendMessage(
                    recipientId: recipientId,
                    senderId: senderId,
                    questionTitle: thread.questionTitle,
                    messageText: text
                )
                if success {
                    messageText = ""
                    await viewModel.fetchMessages(threadId: thread.threadId)
                    print("✅ テキストメッセージ送信完了")
                } else {
                    sendErrorMessage = "メッセージの送信に失敗しました。"
                    showingSendErrorAlert = true
                }
            }
        }
        
        if let audioData = voiceRecorderViewModel.audioData {
            Task {
                let duration = voiceRecorderViewModel.recordingTime
                print("✅ ボイスメッセージ送信開始: \(duration)秒")
                
                // ★★★ 修正: DMThread に変更 ★★★
                let threadResult: DMThread? = await viewModel.sendInitialDMAndReturnThread(
                    recipientId: recipientId,
                    senderId: senderId,
                    questionTitle: thread.questionTitle,
                    messageText: "（音声メッセージ）",
                    voiceData: audioData,
                    duration: duration
                )
                
                if threadResult != nil {
                    voiceRecorderViewModel.audioData = nil
                    voiceRecorderViewModel.recordingTime = 0
                    await viewModel.fetchMessages(threadId: self.thread.threadId)
                    print("✅ ボイスメッセージ送信完了")
                } else {
                    print("❌ ボイスメッセージ送信失敗")
                    sendErrorMessage = "音声メッセージの送信に失敗しました。"
                    showingSendErrorAlert = true
                }
            }
        }
    }
}
