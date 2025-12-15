import SwiftUI

struct BioDisplaySheet: View {
    let userId: String
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isPresented: Bool
    
    @State private var bio: String? = nil
    @State private var isLoading = true
    @State private var cacheBuster = UUID().uuidString
    
    private var nickname: String {
        profileViewModel.getDisplayName(userId: userId)
    }
    
    private var profileImageUrl: String? {
        profileViewModel.userProfileImages[userId]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // プロフィール画像
                profileImageView
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                
                // ニックネーム
                Text(nickname)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Divider()
                    .padding(.horizontal)
                
                // 自己紹介
                VStack(alignment: .leading, spacing: 8) {
                    Text("自己紹介")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 60)
                    } else if let bio = bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    } else {
                        Text("自己紹介はありません")
                            .font(.body)
                            .foregroundColor(.gray)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }
            }
            .task {
                await loadBio()
            }
        }
        .presentationDetents([.fraction(0.5)])
    }
    
    private var profileImageView: some View {
        Group {
            if let imageUrl = profileImageUrl,
               let url = URL(string: "\(imageUrl)?v=\(cacheBuster)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        defaultIcon
                    case .empty:
                        ProgressView()
                    @unknown default:
                        defaultIcon
                    }
                }
            } else {
                defaultIcon
            }
        }
    }
    
    private var defaultIcon: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .foregroundColor(.gray)
    }
    
    private func loadBio() async {
        isLoading = true
        bio = await profileViewModel.fetchBio(userId: userId)
        isLoading = false
    }
}
