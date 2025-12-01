import Foundation
import StoreKit
import Combine

// 商品IDの定義
enum ProductID: String, CaseIterable {
    case monthly = "com.imai.QuestionConnection.plan.monthly"
    case yearly  = "com.imai.QuestionConnection.plan.yearly"
    case lifetime = "com.imai.QuestionConnection.plan.lifetime"
}

// ★★★ 名前変更: StoreManager -> SubscriptionManager ★★★
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

    init() {
        Task {
            await updatePurchasedProducts()
            await loadProducts()
        }
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
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                    print("購入成功: \(transaction.productID)")
                case .unverified:
                    print("購入検証失敗")
                    errorMessage = "購入の検証に失敗しました"
                }
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
    
    // リストア
    func restorePurchases() async {
        isLoading = true
        try? await AppStore.sync()
        await updatePurchasedProducts()
        isLoading = false
    }
}
