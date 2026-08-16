import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class AlertFeatureTests: XCTestCase {
    func test_loadedRestoresOnlyAlarmPreference() async {
        let store = TestStore(initialState: AlertFeature.State()) {
            AlertFeature()
        }

        await store.send(.loaded(alarm: true)) {
            $0.isAlarmOn = true
        }
    }
}
