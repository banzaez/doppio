import Foundation
import AppKit
import os

/// Результат проверки обновлений
public enum UpdateCheckResult: Equatable, Sendable {
    case idle
    case checking
    case upToDate(version: String)
    case updateAvailable(version: String, releaseNotes: String, releaseURL: URL, downloadURL: URL?)
    case failed(message: String)
}

/// Сервис проверки и загрузки обновлений Doppio через GitHub Releases API
@MainActor
public final class AppUpdateService: ObservableObject {
    public static let shared = AppUpdateService()

    private let logger = Logger(subsystem: "com.doppio.app", category: "AppUpdateService")
    private let repoOwner = "banzaez"
    private let repoName = "doppio"

    @Published public private(set) var status: UpdateCheckResult = .idle
    @Published public private(set) var isChecking: Bool = false

    public init() {}

    /// Текущая версия приложения
    public var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.0"
    }

    /// Проверка обновлений на GitHub
    @discardableResult
    public func checkForUpdates(isUserInitiated: Bool = true, l10n: L10n? = nil) async -> UpdateCheckResult {
        guard !isChecking else { return status }

        isChecking = true
        status = .checking
        logger.info("Проверка обновлений (пользовательский запрос: \(isUserInitiated))...")

        do {
            let result = try await fetchLatestRelease()
            isChecking = false
            status = result

            if isUserInitiated, let l10n = l10n {
                presentUpdateAlert(for: result, l10n: l10n)
            }

            return result
        } catch {
            isChecking = false
            let errorResult = UpdateCheckResult.failed(message: error.localizedDescription)
            status = errorResult
            logger.error("Ошибка при проверке обновлений: \(error.localizedDescription)")

            if isUserInitiated, let l10n = l10n {
                presentUpdateAlert(for: errorResult, l10n: l10n)
            }

            return errorResult
        }
    }

    /// Запрос данных последнего релиза с GitHub API
    private func fetchLatestRelease() async throws -> UpdateCheckResult {
        guard let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Doppio-App/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 12

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct GitHubRelease: Decodable {
            let tag_name: String
            let name: String?
            let body: String?
            let html_url: String
            struct Asset: Decodable {
                let name: String
                let browser_download_url: String
            }
            let assets: [Asset]?
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        let remoteVersion = release.tag_name.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let current = currentVersion.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))

        if isVersion(remoteVersion, greaterThan: current) {
            let releaseURL = URL(string: release.html_url) ?? URL(string: "https://github.com/\(repoOwner)/\(repoName)/releases")!
            let downloadAsset = release.assets?.first(where: {
                $0.name.hasSuffix(".zip") || $0.name.hasSuffix(".dmg") || $0.name.hasSuffix(".tar.gz")
            })
            let downloadURL = downloadAsset.flatMap { URL(string: $0.browser_download_url) }

            logger.info("Найдена новая версия: \(remoteVersion) (текущая: \(current))")
            return .updateAvailable(
                version: remoteVersion,
                releaseNotes: release.body ?? "",
                releaseURL: releaseURL,
                downloadURL: downloadURL
            )
        } else {
            logger.info("Установлена актуальная версия: \(current)")
            return .upToDate(version: current)
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

    /// Показ нативного системного диалога обновления пользователю
    public func presentUpdateAlert(for result: UpdateCheckResult, l10n: L10n) {
        let alert = NSAlert()

        switch result {
        case .updateAvailable(let version, let notes, let releaseURL, let downloadURL):
            alert.alertStyle = .informational
            alert.messageText = l10n.updateAvailableTitle
            let baseMessage = l10n.updateAvailableDesc(version)
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            alert.informativeText = trimmedNotes.isEmpty
                ? baseMessage
                : "\(baseMessage)\n\n\(trimmedNotes.prefix(350))\(trimmedNotes.count > 350 ? "..." : "")"

            alert.addButton(withTitle: l10n.updateDownloadButton)
            alert.addButton(withTitle: l10n.updateLaterButton)

            NSApp.activate(ignoringOtherApps: true)
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let targetURL = downloadURL ?? releaseURL
                NSWorkspace.shared.open(targetURL)
            }

        case .upToDate(let version):
            alert.alertStyle = .informational
            alert.messageText = l10n.updateUpToDateTitle
            alert.informativeText = l10n.updateUpToDateMessage(version)
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()

        case .failed(let message):
            alert.alertStyle = .warning
            alert.messageText = l10n.updateCheckFailedTitle
            alert.informativeText = message
            alert.addButton(withTitle: "OK")
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()

        case .idle, .checking:
            break
        }
    }
}
