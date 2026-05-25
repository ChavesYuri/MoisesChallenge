import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.splashTeal, AppTheme.splashBlack],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("musicalNote")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("Music note logo")
        }
    }
}

#Preview {
    SplashScreen()
}
