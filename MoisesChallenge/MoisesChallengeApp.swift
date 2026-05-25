import SwiftUI

@main
struct MoisesChallengeApp: App {
    @State private var composition = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            AppView(composition: composition)
        }
    }
}
