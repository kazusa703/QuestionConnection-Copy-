import SwiftUI

struct EssayConfirmView: View {
    @Binding var isPresented: Bool
    let onNextTap: () -> Void
    let onSubmitAllTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("記述式問題は出題者が採点するため")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text("正解と仮定して次に進みます。")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            . padding(20)
            . background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: {
                    isPresented = false
                    onNextTap()
                }) {
                    Text("次に進む")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    isPresented = false
                    onSubmitAllTap()
                }) {
                    Text("ここまでで完了する")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .presentationDetents([.fraction(0.4)])
    }
}

#Preview {
    EssayConfirmView(
        isPresented: .constant(true),
        onNextTap: {},
        onSubmitAllTap: {}
    )
}
