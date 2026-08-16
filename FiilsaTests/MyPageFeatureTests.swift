import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class MyPageFeatureTests: XCTestCase {
    func test_resignConfirmationDeletesAccountThenEmitsSuccessDelegate() async {
        let counts = ResignEffectCounts()
        let store = TestStore(
            initialState: MyPageFeature.State(
                isLoggedIn: true,
                userName: "필사",
                imagePath: "profile"
            )
        ) {
            MyPageFeature()
        } withDependencies: {
            $0.commonClient.deleteResign = {
                await counts.recordDelete()
                return 1
            }
            $0.sessionClient.logout = {
                await counts.recordLogout()
            }
        }

        await store.send(.resignTapped) {
            $0.isResignDialogPresented = true
        }
        await store.send(.resignConfirmed) {
            $0.isResignDialogPresented = false
            $0.isProcessing = true
        }
        await store.receive(.resignCompleted(.success(true))) {
            $0.isProcessing = false
            $0.isLoggedIn = false
            $0.userName = ""
            $0.imagePath = ""
        }
        await store.receive(.delegate(.resignCompleted))

        let deleteCount = await counts.deleteCount
        let logoutCount = await counts.logoutCount
        XCTAssertEqual(deleteCount, 1)
        XCTAssertEqual(logoutCount, 1)
    }

    func test_resignDialogDismissalOnlyClosesDialog() async {
        let store = TestStore(
            initialState: MyPageFeature.State(
                isLoggedIn: true,
                isResignDialogPresented: true
            )
        ) {
            MyPageFeature()
        }

        await store.send(.resignDialogDismissed) {
            $0.isResignDialogPresented = false
        }
    }

    func test_resignFailureKeepsMemberStateAndShowsToast() async {
        let store = TestStore(
            initialState: MyPageFeature.State(isLoggedIn: true, userName: "필사")
        ) {
            MyPageFeature()
        } withDependencies: {
            $0.commonClient.deleteResign = { throw TestResignError.failed }
        }

        await store.send(.resignConfirmed) {
            $0.isProcessing = true
        }
        await store.receive(.resignCompleted(.failure(.failed))) {
            $0.isProcessing = false
            $0.toastMessage = "탈퇴 처리에 실패했습니다."
        }
        await store.send(.toastDismissed) {
            $0.toastMessage = nil
        }
    }

    func test_resignConfirmationDoesNothingWhileAlreadyProcessing() async {
        let store = TestStore(
            initialState: MyPageFeature.State(isLoggedIn: true, isProcessing: true)
        ) {
            MyPageFeature()
        }

        await store.send(.resignConfirmed)
    }

    func test_themeSelectionPersistsImmediatelyAndConfirmOnlyDismissesDialog() async {
        let savedThemes = SavedThemes()
        let store = TestStore(initialState: MyPageFeature.State()) {
            MyPageFeature()
        } withDependencies: {
            $0.settingsClient = SettingsClient(
                getAlarm: { false },
                setAlarm: { _ in },
                isAlarmPermissionRequestedBefore: { false },
                setAlarmPermissionRequestedBefore: { _ in },
                getDarkModeType: { .system },
                setDarkModeType: { theme in await savedThemes.append(theme) },
                getUserName: { "" },
                setUserName: { _ in },
                getImageURI: { "" },
                getShareDescriptionVisible: { true },
                setShareDescriptionVisible: { _ in },
                getTokenExpired: { "" },
                emitTokenExpired: { _ in }
            )
        }

        await store.send(.themeTapped) {
            $0.isThemeDialogPresented = true
        }
        await store.send(.themeSelected(.dark)) {
            $0.selectedTheme = .dark
        }

        let savedThemeValues = await savedThemes.values
        XCTAssertEqual(savedThemeValues, [.dark])

        await store.send(.themeDialogConfirmed) {
            $0.isThemeDialogPresented = false
        }
    }
}

private actor ResignEffectCounts {
    private(set) var deleteCount = 0
    private(set) var logoutCount = 0

    func recordDelete() {
        deleteCount += 1
    }

    func recordLogout() {
        logoutCount += 1
    }
}

private enum TestResignError: Error {
    case failed
}

private actor SavedThemes {
    var values: [DarkModeType] = []

    func append(_ theme: DarkModeType) {
        values.append(theme)
    }
}
