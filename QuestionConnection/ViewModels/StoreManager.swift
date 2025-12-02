import Foundation
import StoreKit
import Combine

// 商品IDの定義
enum ProductID: String, CaseIterable {
    case monthly = "com.imai.QuestionConnection.plan.monthly"
    case yearly  = "com.imai.QuestionConnection.plan.yearly"
    case lifetime = "com.imai.QuestionConnection.plan.lifetime"
}

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 有料会員かどうか
    var isPremium: Bool {
        !purchasedProductIDs.isEmpty
    }
    
    // トランザクション監視用のタスク保持
    private var updateListenerTask: Task<Void, Error>? = nil

    init() {
        // ★★★ 修正: 起動時にトランザクションの更新を監視するリスナーを開始 ★★★
        updateListenerTask = Task {
            for await result in Transaction.updates {
                await handle(updatedTransaction: result)
            }
        }
        
        // 初期データの読み込み
        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
    }
    
    deinit {
        // メモリ解放時に監視を停止
        updateListenerTask?.cancel()
    }
    
    // ★★★ 追加: トランザクション更新のハンドリング ★★★
    private func handle(updatedTransaction result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            // 改ざんされたトランザクションは無視
            return
        }
        
        // 購入済み状態を更新
        await updatePurchasedProducts()
        
        // トランザクションを完了（Finish）させる
        await transaction.finish()
    }

    // 商品情報を取得
    func loadProducts() async {
        isLoading = true
        do {
            let productIds = ProductID.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIds)
            self.products = products.sorted { productA, productB in
                productA.price < productB.price
            }
        } catch {
            print("商品の読み込み失敗: \(error)")
            errorMessage = "商品情報の取得に失敗しました"
        }
        isLoading = false
    }

    // 購入処理
    func purchase(_ product: Product) async {
        isLoading = true
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // 購入成功時はハンドラーに任せる
                await handle(updatedTransaction: verification)
                print("購入処理成功")
                
            case .userCancelled:
                print("キャンセル")
            case .pending:
                print("承認待ち")
            @unknown default:
                break
            }
        } catch {
            print("購入エラー: \(error)")
            errorMessage = "購入処理中にエラーが発生しました"
        }
        isLoading = false
    }
    
    // 購入情報の更新
    func updatePurchasedProducts() async {
        var purchased = Set<String>()
        // 現在有効な権利を確認
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                purchased.insert(transaction.productID)
            case .unverified:
                break
            }
        }
        self.purchasedProductIDs = purchased
    }
    
    // リストア（復元）
    func restorePurchases() async {
        isLoading = true
        try? await AppStore.sync()
        await updatePurchasedProducts()
        isLoading = false
    }
}
