import SwiftUI

struct QuestionCreationGuideView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 1 // 1: 入力項目の説明, 2: 投稿後の流れ
    
    var body: some View {
        NavigationStack {
            VStack {
                if currentPage == 1 {
                    pageOne
                        .transition(.move(edge: .leading))
                } else {
                    pageTwo
                        .transition(.move(edge: .trailing))
                }
            }
            .navigationTitle("作成ガイド")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 右上の×ボタン
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .animation(.easeInOut, value: currentPage)
        }
        .presentationDetents([.medium, .large]) // シートの高さ
    }
    
    // --- 1ページ目 ---
    private var pageOne: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    guideItem(
                        icon: "tag.fill", color: .blue,
                        title: "題名 / 目的 / タグ",
                        text: "掲示板での検索や絞り込みに使われます。興味を持ってもらいやすい言葉を選びましょう。"
                    )
                    
                    guideItem(
                        icon: "text.bubble.fill", color: .green,
                        title: "備考・説明",
                        text: "回答者が迷わないよう、前提条件やメッセージを書いておくと親切です。"
                    )
                    
                    guideItem(
                        icon: "envelope.fill", color: .orange,
                        title: "全問正解者へのメッセージ",
                        text: "全問正解者とのDMルームが作成された瞬間に、自動送信する「第一声」です。"
                    )
                }
                .padding()
            }
            
            // 右下の「＞」ボタン
            HStack {
                Spacer()
                Button(action: { currentPage = 2 }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white)) // 背景透過防止
                }
                .padding()
            }
        }
    }
    
    // --- 2ページ目 ---
    private var pageTwo: some View {
        VStack(alignment: .leading, spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("■ 投稿後の流れ")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    HStack(alignment: .top, spacing: 12) {
                        numberBadge(1)
                        Text("掲示板から他のユーザーがあなたのクイズを見つけ、挑戦します。")
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        numberBadge(2)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("全問正解されると通知が届き、そのユーザーとのDMが可能になります。")
                            Text("(記述式問題が含まれる場合は、プロフィールタブの「自分が作成した質問」からあなたが採点をした後に判定されます)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            // 左下の「＜」ボタン（戻る用・任意）
            HStack {
                Button(action: { currentPage = 1 }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white))
                }
                .padding()
                Spacer()
            }
        }
    }
    
    // デザイン部品
    private func guideItem(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func numberBadge(_ num: Int) -> some View {
        Text("\(num)")
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(width: 24, height: 24)
            .background(Circle().fill(Color.blue))
    }
}

#Preview {
    QuestionCreationGuideView()
}
