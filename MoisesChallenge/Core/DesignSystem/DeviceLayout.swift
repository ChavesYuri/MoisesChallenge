import SwiftUI

enum DeviceLayout {
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    static func isRegularWidth(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }
}
