import Foundation

enum ScanFlowOrigin: Equatable {
    case onboarding
    case addProduct
}

extension Notification.Name {
    static let returnToDashboard = Notification.Name("returnToDashboard")
}
