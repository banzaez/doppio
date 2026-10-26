import Foundation
@preconcurrency import UserNotifications
import os

/// Доступные быстрые действия из баннера уведомления
public enum NotificationPreExpiryAction: Sendable {
    case extend15Minutes
    case makeIndefinite
}

/// Протокол службы системных уведомлений
@MainActor
public protocol AppNotificationManaging: AnyObject {
    var onActionReceived: (@MainActor (NotificationPreExpiryAction) -> Void)? { get set }
    @discardableResult
    func requestAuthorization() async -> Bool
    func schedulePreExpiryNotification(title: String, body: String, l10n: L10n) async
    func cancelPendingNotifications() async
}

/// Сервис нативных системных уведомлений macOS (UserNotifications framework)
@MainActor
public final class AppNotificationService: NSObject, AppNotificationManaging, UNUserNotificationCenterDelegate {
    public static let shared = AppNotificationService()

    private var center: UNUserNotificationCenter? {
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    private let logger = Logger(subsystem: "com.doppio.app", category: "NotificationService")

    private static let categoryId = "com.doppio.notification.expiring"
    private static let actionExtend15Id = "com.doppio.action.extend15"
    private static let actionIndefiniteId = "com.doppio.action.indefinite"
    private static let notificationId = "com.doppio.pre_expiry_alert"

    /// Коллбэк при нажатии кнопки действия пользователем
    public var onActionReceived: (@MainActor (NotificationPreExpiryAction) -> Void)?

    public override init() {
        super.init()
        // В среде swift test у процесса нет bundleIdentifier, поэтому UNUserNotificationCenter не инициализируется
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().delegate = self
        }
    }

    /// Запрос прав на показ уведомлений
    @discardableResult
    public func requestAuthorization() async -> Bool {
        guard let center = center else { return false }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            logger.info("Разрешение на уведомления: \(granted)")
            return granted
        } catch {
            logger.error("Ошибка запроса разрешения на уведомления: \(error.localizedDescription)")
            return false
        }
    }

    /// Регистрация категорий и отправка предупреждения о скором засыпании
    public func schedulePreExpiryNotification(title: String, body: String, l10n: L10n) async {
        guard let center = center else { return }

        let extendAction = UNNotificationAction(
            identifier: Self.actionExtend15Id,
            title: l10n.notificationActionExtend15,
            options: []
        )

        let indefiniteAction = UNNotificationAction(
            identifier: Self.actionIndefiniteId,
            title: l10n.notificationActionIndefinite,
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryId,
            actions: [extendAction, indefiniteAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = Self.categoryId
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: Self.notificationId,
            content: content,
            trigger: nil // Мгновенный показ
        )

        do {
            try await center.add(request)
            logger.info("Предупреждающее уведомление отправлено")
        } catch {
            logger.error("Не удалось отправить уведомление: \(error.localizedDescription)")
        }
    }

    /// Снять запланированные уведомления
    public func cancelPendingNotifications() async {
        guard let center = center else { return }
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationId])
        center.removeDeliveredNotifications(withIdentifiers: [Self.notificationId])
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Показ баннера даже когда приложение активно
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    /// Обработка нажатий на кнопки в уведомлении
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier

        await MainActor.run {
            switch actionId {
            case Self.actionExtend15Id:
                self.logger.info("Нажато действие: +15 минут")
                self.onActionReceived?(.extend15Minutes)
            case Self.actionIndefiniteId:
                self.logger.info("Нажато действие: Бессрочно")
                self.onActionReceived?(.makeIndefinite)
            default:
                break
            }
        }
    }
}
