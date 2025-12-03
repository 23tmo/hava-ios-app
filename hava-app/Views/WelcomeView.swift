import SwiftUI

struct WelcomeView: View {
    var onFinish: () -> Void
    @State private var isVisible = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("hava")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("A place to give and get recommendations with friends.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    isVisible = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onFinish()
                }
            }
        }
    }
} 