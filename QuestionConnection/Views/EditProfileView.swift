import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var cacheBuster = UUID().uuidString
    
    // ニックネーム編集用
    @State private var showNicknameEdit = false
    @State private var editingNickname = ""
    
    // 自己紹介編集用
    @State private var showBioEdit = false
    @State private var editingBio = ""
    
    private var userId: String {
        authViewModel.userSub ?? ""
    }
    
    var body: some View {
        NavigationStack {
            List {
                // プロフィール画像セクション
                Section {
                    VStack(spacing: 12) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            VStack(spacing: 8) {
                                profileImageView
                                Text("写真を編集")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    await profileViewModel.uploadProfileImage(userId: userId, image: uiImage)
                                    cacheBuster = UUID().uuidString
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                // プロフィール情報セクション
                Section {
                    // ニックネーム
                    Button(action: {
                        editingNickname = profileViewModel.userNicknames[userId] ?? ""
                        showNicknameEdit = true
                    }) {
                        HStack {
                            Text("ニックネーム")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(profileViewModel.userNicknames[userId] ?? "未設定")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 自己紹介
                    Button(action: {
                        editingBio = profileViewModel.userBio ?? ""
                        showBioEdit = true
                    }) {
                        HStack {
                            Text("自己紹介")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(profileViewModel.userBio?.isEmpty == false ? profileViewModel.userBio! : "未設定")
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("プロフィールを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showNicknameEdit) {
                EditNicknameSheet(
                    nickname: $editingNickname,
                    isPresented: $showNicknameEdit,
                    onSave: {
                        Task {
                            // ProfileViewModel の nickname プロパティを更新してから保存
                            profileViewModel.nickname = editingNickname
                            await profileViewModel.updateNickname(userId: userId)  // ✅ 修正
                        }
                    }
                )
            }
            .sheet(isPresented: $showBioEdit) {
                EditBioSheet(
                    bio: $editingBio,
                    isPresented: $showBioEdit,
                    onSave: {
                        Task {
                            await profileViewModel.updateBio(userId: userId, newBio: editingBio)
                        }
                    }
                )
            }
            .alert("プロフィール画像", isPresented: $profileViewModel.showProfileImageAlert) {
                Button("OK") {}
            } message: {
                Text(profileViewModel.profileImageAlertMessage ?? "")
            }
        }
    }
    
    private var profileImageView: some View {
        Group {
            if profileViewModel.isUploadingProfileImage {
                ProgressView()
                    .frame(width: 100, height: 100)
            } else if let imageUrl = profileViewModel.userProfileImages[userId],
                      let url = URL(string: "\(imageUrl)?v=\(cacheBuster)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        defaultIcon
                    @unknown default:
                        defaultIcon
                    }
                }
            } else {
                defaultIcon
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.accentColor, lineWidth: 2)
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "camera.fill")
                .foregroundColor(.white)
                .padding(6)
                .background(Color.blue)
                .clipShape(Circle())
                .offset(x: 5, y: 5)
        }
    }
    
    private var defaultIcon: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundColor(.gray)
    }
}

// MARK: - ニックネーム編集シート

struct EditNicknameSheet: View {
    @Binding var nickname: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ニックネーム")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("ニックネームを入力", text: $nickname)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("ニックネーム変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave()
                        isPresented = false
                    }
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.fraction(0.35)])
    }
}

// MARK: - 自己紹介編集シート

struct EditBioSheet: View {
    @Binding var bio: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    
    @FocusState private var isFocused: Bool
    
    private let maxLength = 150
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("自己紹介")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(bio.count)/\(maxLength)")
                            .font(.caption)
                            .foregroundColor(bio.count > maxLength ? .red : .secondary)
                    }
                    
                    TextEditor(text: $bio)
                        .frame(height: 120)
                        .padding(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .onChange(of: bio) { _, newValue in
                            if newValue.count > maxLength {
                                bio = String(newValue.prefix(maxLength))
                            }
                        }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("自己紹介を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave()
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.fraction(0.45)])
    }
}
