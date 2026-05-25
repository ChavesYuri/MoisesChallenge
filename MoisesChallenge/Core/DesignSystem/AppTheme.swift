import SwiftUI

enum AppTheme {
    static let background = Color.black
    static let splashBlack = Color(hex: "000000")
    static let splashTeal = Color(hex: "0086A0")
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let elevated = Color(red: 0.17, green: 0.18, blue: 0.22)
    static let accent = Color.white
    static let warm = Color(red: 0.95, green: 0.66, blue: 0.22)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.55)
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
