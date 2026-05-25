import SwiftUI

struct WatchSplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Image(systemName: "music.note")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.gray)
        }
    }
}
