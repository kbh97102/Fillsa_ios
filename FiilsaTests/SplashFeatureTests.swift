import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class SplashFeatureTests: XCTestCase {
    func testReturningLoggedOutUserGoesToLogin() async {
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = { false }
            $0.sessionClient.isLoggedIn = { false }
        }

        await store.send(.permissionChecked) {
            $0.hasCheckedPermission = true
        }
        await store.send(.animationCompleted) {
            $0.hasPlayedAnimation = true
            $0.isResolvingDestination = true
        }
        await store.receive(.ready(.login(isOnboarding: false))) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.login(isOnboarding: false))))
    }

    func testFirstOpenLoggedOutUserGoesToLoginAndMarksVisit() async {
        let visits = FirstOpenVisits()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = { true }
            $0.sessionClient.setFirstOpen = { value in await visits.record(value) }
            $0.sessionClient.isLoggedIn = { false }
        }

        await store.send(.permissionChecked) { $0.hasCheckedPermission = true }
        await store.send(.animationCompleted) {
            $0.hasPlayedAnimation = true
            $0.isResolvingDestination = true
        }
        await store.receive(.ready(.login(isOnboarding: false))) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.login(isOnboarding: false))))
        let recordedVisits = await visits.values
        XCTAssertEqual(recordedVisits, [false])
    }

    func testFirstOpenMemberGoesHomeAndMarksVisit() async {
        let visits = FirstOpenVisits()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = { true }
            $0.sessionClient.setFirstOpen = { value in await visits.record(value) }
            $0.sessionClient.isLoggedIn = { true }
        }

        await store.send(.permissionChecked) { $0.hasCheckedPermission = true }
        await store.send(.animationCompleted) {
            $0.hasPlayedAnimation = true
            $0.isResolvingDestination = true
        }
        await store.receive(.ready(.home)) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.home)))
        let recordedVisits = await visits.values
        XCTAssertEqual(recordedVisits, [false])
    }

    func testReturningMemberGoesHome() async {
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = { false }
            $0.sessionClient.isLoggedIn = { true }
        }

        await store.send(.animationCompleted) { $0.hasPlayedAnimation = true }
        await store.send(.permissionChecked) {
            $0.hasCheckedPermission = true
            $0.isResolvingDestination = true
        }
        await store.receive(.ready(.home)) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.home)))
    }

    func testLoginStatusReadFailureGoesToLogin() async {
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = { false }
            $0.sessionClient.isLoggedIn = { throw SplashTestError.failed }
        }

        await store.send(.permissionChecked) { $0.hasCheckedPermission = true }
        await store.send(.animationCompleted) {
            $0.hasPlayedAnimation = true
            $0.isResolvingDestination = true
        }
        await store.receive(.ready(.login(isOnboarding: false))) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.login(isOnboarding: false))))
    }

    func testRepeatedCompletionDoesNotChooseDestinationTwice() async {
        let gate = AsyncStream<Void>.makeStream()
        let store = TestStore(initialState: SplashFeature.State()) {
            SplashFeature()
        } withDependencies: {
            $0.sessionClient.isFirstOpen = {
                for await _ in gate.stream {}
                return false
            }
            $0.sessionClient.isLoggedIn = { false }
        }

        await store.send(.permissionChecked) { $0.hasCheckedPermission = true }
        await store.send(.animationCompleted) {
            $0.hasPlayedAnimation = true
            $0.isResolvingDestination = true
        }
        await store.send(.permissionChecked)
        gate.continuation.finish()
        await store.receive(.ready(.login(isOnboarding: false))) {
            $0.isReady = true
            $0.isResolvingDestination = false
        }
        await store.receive(.delegate(.move(.login(isOnboarding: false))))
        await store.finish()
    }
}

private actor FirstOpenVisits {
    private(set) var values: [Bool] = []

    func record(_ value: Bool) {
        values.append(value)
    }
}

private enum SplashTestError: Error {
    case failed
}
