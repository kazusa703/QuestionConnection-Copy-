import SwiftUI

struct DMGuideView: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundColor(. blue)
            
            Text("DMを後から送る場合")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Text("1.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("画面下の「DM」タブを開く")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(alignment:  .top, spacing: 12) {
                    Text("2.")
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("右上の「未送信」ボタンをタップ")
                        . frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(alignment: . top, spacing: 12) {
                    Text("3.")
                        .fontWeight(.bold)
                        .foregroundColor(. blue)
                    Text("DMを送りたい相手を選んで送信")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            
            Spacer()
            
            Button(action: {
                isPresented = false
                onDismiss()
            }) {
                Text("OK")
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(24)
        .presentationDetents([.fraction(0.55)])
    }
}
