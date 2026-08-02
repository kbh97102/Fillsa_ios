import ComposableArchitecture
import Foundation
import UserNotifications

struct PushRegistrationClient {
    var synchronize: @Sendable (_ updatedToken: String?) async -> Void
    var synchronizeIfNeeded: @Sendable () async -> Void
}

extension PushRegistrationClient: DependencyKey {
    static let liveValue: PushRegistrationClient = {
        let service = PushRegistrationService(
            repository: LiveRepositories.pushRegistration,
            localRepository: LiveRepositories.local,
            pushTokenClient: PushTokenClient.liveValue,
            notificationPermissionClient: NotificationPermissionClient.liveValue
        )

        return PushRegistrationClient(
            synchronize: { updatedToken in
                await service.synchronize(updatedToken: updatedToken, force: true)
            },
            synchronizeIfNeeded: {
                await service.synchronize(updatedToken: nil, force: false)
            }
        )
    }()
}

extension DependencyValues {
    var pushRegistrationClient: PushRegistrationClient {
        get { self[PushRegistrationClient.self] }
        set { self[PushRegistrationClient.self] = newValue }
    }
}

private struct PushRegistrationService {
    let repository: PushRegistrationRepository
    let localRepository: LocalRepository
    let pushTokenClient: PushTokenClient
    let notificationPermissionClient: NotificationPermissionClient

    func synchronize(updatedToken: String?, force: Bool) async {
        guard force || PushRegistrationSyncState.needsSynchronization else { return }
        guard (try? await localRepository.isLoggedIn()) == true else { return }

        let pushToken: String?
        if let updatedToken {
            pushToken = updatedToken
        } else {
            pushToken = await pushTokenClient.currentToken()
        }
        guard let pushToken, !pushToken.isEmpty else { return }

        let alarmEnabled = (try? await localRepository.getAlarm()) ?? false
        let authorizationStatus = await notificationPermissionClient.authorizationStatus()
        let agreed = alarmEnabled && authorizationStatus.isPushPermissionGranted

        do {
            try await repository.registerPushDevice(
                PushRegistrationRequest(
                    deviceId: DeviceIDProvider.current(),
                    pushToken: pushToken,
                    agreed: agreed
                )
            )
            PushRegistrationSyncState.markSynchronized()
        } catch {
            PushRegistrationSyncState.markPending()
        }
    }
}

private enum PushRegistrationSyncState {
    private static let key = "push_registration_needs_sync"

    static var needsSynchronization: Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func markPending() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func markSynchronized() {
        UserDefaults.standard.set(false, forKey: key)
    }
}

extension UNAuthorizationStatus {
    var isPushPermissionGranted: Bool {
        switch self {
        case .authorized, .provisional, .ephemeral:
            true
        case .notDetermined, .denied:
            false
        @unknown default:
            false
        }
    }
}
