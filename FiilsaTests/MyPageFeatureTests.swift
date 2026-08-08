import ComposableArchitecture
import XCTest
@testable import Fiilsa

@MainActor
final class MyPageFeatureTests: XCTestCase {
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

private actor SavedThemes {
    var values: [DarkModeType] = []

    func append(_ theme: DarkModeType) {
        values.append(theme)
    }
}
