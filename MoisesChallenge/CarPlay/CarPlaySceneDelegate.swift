import CarPlay
import UIKit

@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var coordinator: CarPlayCoordinator?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        guard let composition = (UIApplication.shared.delegate as? AppDelegate)?.composition else { return }
        let coordinator = CarPlayCoordinator(
            interfaceController: interfaceController,
            repository: composition.repository,
            playback: composition.playback,
            nowPlaying: composition.nowPlaying
        )
        self.coordinator = coordinator
        Task { await coordinator.start() }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        coordinator = nil
    }
}
