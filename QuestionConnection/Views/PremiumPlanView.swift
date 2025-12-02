import SwiftUI
import StoreKit

struct PremiumPlanView: View {
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        Text("プレミアムプラン")
                            .font(.largeTitle).bold()
                        Text("広告なしで快適に。\n記述式問題の作成も自由に。")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // 商品リストの表示
                    if subscriptionManager.isLoading {
                        ProgressView("商品情報を読み込み中...")
                    } else if subscriptionManager.products.isEmpty {
                        Text("販売可能な商品が見つかりませんでした。\n(StoreKit設定を確認してください)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        ForEach(subscriptionManager.products) { product in
                            ProductRow(product: product)
                        }
                    }
                    
                    // リストア（復元）ボタン
                    Button("購入を復元する") {
                        Task {
                            await subscriptionManager.restorePurchases()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("アップグレード")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
        .alert("メッセージ", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") { subscriptionManager.errorMessage = nil }
        } message: {
            Text(subscriptionManager.errorMessage ?? "")
        }
    }
}

// 商品ごとの行デザイン
struct ProductRow: View {
    let product: Product
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await subscriptionManager.purchase(product)
                }
            } label: {
                // サブスクなら価格 + 期間、買い切りなら価格のみ
                Text(product.displayPrice)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
