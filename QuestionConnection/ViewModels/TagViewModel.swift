import Foundation
import Combine

// ★★★ 修正: 名前を TagSuggestion に変更（重複回避） ★★★
struct TagSuggestion: Codable, Identifiable, Hashable {
    var id: String { tagName }
    let tagName: String
    let displayName: String
    let usageCount: Int
    let lastUsedAt: String
}

struct TagsAPIResponse: Codable {
    let tags: [TagSuggestion]
    let total: Int
}

@MainActor
class TagViewModel: ObservableObject {
    @Published var popularTags: [TagSuggestion] = []
    @Published var recentTags: [TagSuggestion] = []
    @Published var searchResults: [TagSuggestion] = []
    @Published var isLoading = false
    @Published var searchQuery = ""
    
    private let tagsEndpoint = URL(string: "https://9mkgg5ufta.execute-api.ap-northeast-1.amazonaws.com/dev/tags")!
    
    private var searchTask: Task<Void, Never>?
    
    // 人気タグを取得
    func fetchPopularTags() async {
        isLoading = true
        defer { isLoading = false }
        
        var components = URLComponents(url: tagsEndpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "sort", value: "popular"),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("TagViewModel: 人気タグ取得エラー")
                return
            }
            
            let decoded = try JSONDecoder().decode(TagsAPIResponse.self, from: data)
            self.popularTags = decoded.tags
            print("TagViewModel: 人気タグ取得成功 \(decoded.tags.count)件")
        } catch {
            print("TagViewModel: 人気タグ取得失敗 \(error)")
        }
    }
    
    // 最近使われたタグを取得
    func fetchRecentTags() async {
        var components = URLComponents(url: tagsEndpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "sort", value: "recent"),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("TagViewModel: 最近のタグ取得エラー")
                return
            }
            
            let decoded = try JSONDecoder().decode(TagsAPIResponse.self, from: data)
            self.recentTags = decoded.tags
            print("TagViewModel: 最近のタグ取得成功 \(decoded.tags.count)件")
        } catch {
            print("TagViewModel: 最近のタグ取得失敗 \(error)")
        }
    }
    
    // タグ検索（デバウンス付き）
    func searchTags(query: String) {
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            searchResults = []
            return
        }
        
        searchTask = Task {
            // 300msのデバウンス
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            if Task.isCancelled { return }
            
            await performSearch(query: trimmed)
        }
    }
    
    private func performSearch(query: String) async {
        var components = URLComponents(url: tagsEndpoint, resolvingAgainstBaseURL: true)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components?.url else { return }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("TagViewModel: タグ検索エラー")
                return
            }
            
            let decoded = try JSONDecoder().decode(TagsAPIResponse.self, from: data)
            
            if !Task.isCancelled {
                self.searchResults = decoded.tags
                print("TagViewModel: タグ検索成功 '\(query)' → \(decoded.tags.count)件")
            }
        } catch {
            print("TagViewModel: タグ検索失敗 \(error)")
        }
    }
}
