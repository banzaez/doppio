import Foundation
import AppKit
import Observation
import Sparkle
import os

/// Результат проверки обновлений
public enum UpdateCheckResult: Equatable, Sendable {
    case idle
    case checking
    case upToDate(version: String)
    case updateAvailable(version: String, releaseNotes: String, releaseURL: URL, downloadURL: URL?)
    case failed(message: String)
}

/// Протокол сервиса проверки обновлений приложения
@MainActor
public protocol AppUpdateManaging: AnyObject {
    var status: UpdateCheckResult { get }
    var isChecking: Bool { get }
    var currentVersion: String { get }
    func setAutoCheckEnabled(_ enabled: Bool)
    @discardableResult
    func checkForUpdates(isUserInitiated: Bool, l10n: L10n?) async -> UpdateCheckResult
}

public extension AppUpdateManaging {
    func setAutoCheckEnabled(_ enabled: Bool) {}
}

/// Сервис проверки и установки обновлений Doppio на базе Sparkle
@Observable
@MainActor
public final class AppUpdateService: NSObject, AppUpdateManaging, SPUUpdaterDelegate {
    public static let shared = AppUpdateService()

    private let logger = Logger(subsystem: "com.doppio.app", category: "AppUpdateService")

    public private(set) var status: UpdateCheckResult = .idle
    public private(set) var isChecking: Bool = false

    @ObservationIgnored
    private var updaterController: SPUStandardUpdaterController?
    @ObservationIgnored
    private var activeL10n: L10n?

    override public init() {
        super.init()

        // Инициализируем Sparkle только внутри полноценного .app бандла с настроенным SUFeedURL,
        // чтобы модульные тесты (swift test) не падали из-за отсутствия Info.plist.
        if Bundle.main.bundleIdentifier != nil,
           Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil {
            self.updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: self,
                userDriverDelegate: nil
            )
        }
    }

    /// Текущая версия приложения
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.2"
    }

    /// Синхронизация настройки автоматической проверки обновлений со Sparkle
    public func setAutoCheckEnabled(_ enabled: Bool) {
        updaterController?.updater.automaticallyChecksForUpdates = enabled
    }

    /// Проверка обновлений через Sparkle
    @discardableResult
    public func checkForUpdates(isUserInitiated: Bool = true, l10n: L10n? = nil) async -> UpdateCheckResult {
        guard !isChecking else { return status }
        guard let updaterController else {
            logger.warning("Sparkle не инициализирован (запуск вне .app бандла).")
            return .idle
        }

        isChecking = true
        status = .checking
        activeL10n = l10n
        logger.info("Проверка обновлений через Sparkle (пользовательский запрос: \(isUserInitiated))...")

        if isUserInitiated {
            NSApp.activate(ignoringOtherApps: true)
            updaterController.checkForUpdates(nil)
        } else {
            updaterController.updater.checkForUpdatesInBackground()
        }

        return status
    }

    // MARK: - SPUUpdaterDelegate

    public nonisolated func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        Task { @MainActor in
            self.isChecking = false
            let releaseURL = item.infoURL ?? URL(string: "https://github.com/banzaez/doppio/releases")!
            self.status = .updateAvailable(
                version: item.displayVersionString,
                releaseNotes: item.itemDescription ?? "",
                releaseURL: releaseURL,
                downloadURL: item.fileURL
            )
        }
    }

    public nonisolated func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        Task { @MainActor in
            self.isChecking = false
            self.status = .upToDate(version: self.currentVersion)
        }
    }

    public nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        let nsError = error as NSError
        Task { @MainActor in
            self.isChecking = false
            if nsError.domain == SUSparkleErrorDomain {
                // 1001 = SUNoUpdateError, 4002 = SUInstallationCanceledError
                if nsError.code == 1001 {
                    self.status = .upToDate(version: self.currentVersion)
                    return
                }
                if nsError.code == 4002 {
                    self.status = .idle
                    return
                }
            }
            self.logger.error("Sparkle прервал проверку обновлений: \(error.localizedDescription)")
            self.status = .failed(message: error.localizedDescription)
        }
    }

    public nonisolated func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: (any Error)?) {
        Task { @MainActor in
            self.isChecking = false
        }
    }

    /// Сравнение версий по стандарту SemVer (например 1.4.1 > 1.4.0)
    public func isVersion(_ v1: String, greaterThan v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0.prefix(while: { $0.isNumber })) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0.prefix(while: { $0.isNumber })) }

        let count = max(parts1.count, parts2.count)
        for i in 0..<count {
            let num1 = i < parts1.count ? parts1[i] : 0
            let num2 = i < parts2.count ? parts2[i] : 0
            if num1 > num2 { return true }
            if num1 < num2 { return false }
        }
        return false
    }
}
