import SwiftUI

struct PlayerProgressView: View {
    @Binding var progress: Double
    let currentTimeText: String
    let remainingTimeText: String
    let onScrub: (Double) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Slider(value: Binding(
                get: { progress },
                set: { newValue in
                    progress = newValue
                    onScrub(newValue)
                }
            ))
            .tint(.white)

            HStack {
                Text(currentTimeText)
                Spacer()
                Text(remainingTimeText)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct PlayerControlsView: View {
    let isPlaying: Bool
    let onTogglePlayback: () -> Void
    let onSeekBackward: () -> Void
    let onSeekForward: () -> Void
    var playButtonSize: CGFloat = 72
    var skipIconSize: CGFloat = 28
    var use15SecondSkip: Bool = true

    var body: some View {
        HStack(spacing: 48) {
            Button(action: onSeekBackward) {
                Image(systemName: use15SecondSkip ? "gobackward.15" : "backward.fill")
                    .font(.system(size: skipIconSize, weight: .semibold))
            }
            .accessibilityLabel("Go backward 15 seconds")

            Button(action: onTogglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: playButtonSize * 0.38, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: playButtonSize, height: playButtonSize)
                    .background(Color(white: 0.2), in: Circle())
            }
            .accessibilityLabel(isPlaying ? "Pause preview" : "Play preview")

            Button(action: onSeekForward) {
                Image(systemName: use15SecondSkip ? "goforward.15" : "forward.fill")
                    .font(.system(size: skipIconSize, weight: .semibold))
            }
            .accessibilityLabel("Go forward 15 seconds")
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.textPrimary)
    }
}
