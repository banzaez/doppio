import Foundation
import IOKit.pwr_mgt
import os

/// Протокол управления утверждениями сна (Power Management Assertions)
public protocol SleepAssertionManaging: Actor, Sendable {
    var isHoldingAssertion: Bool { get async }
    var activeType: SleepAssertionType? { get async }
    @discardableResult
    func activate(type: SleepAssertionType, reason: String) async -> Bool
    func release() async
}

/// Сервис управления IOKit утверждениями сна (Power Management Assertions)
/// Реализован как Swift Actor для гарантии потокобезопасности и отсутствия race conditions
public actor SleepAssertionService: SleepAssertionManaging {
    private var assertionID: IOPMAssertionID = 0
    private var currentType: SleepAssertionType?
    private let logger = Logger(subsystem: "com.doppio.app", category: "SleepAssertion")

    public init() {}

    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }

    /// Активно ли утверждение
    public var isHoldingAssertion: Bool {
        assertionID != 0
    }

    /// Текущий активный тип
    public var activeType: SleepAssertionType? {
        currentType
    }

    /// Активировать утверждение бодрствования
    /// - Parameters:
    ///   - type: Экран + система или только система
    ///   - reason: Описание причины для IOKit (отображается в pmset -g assertions)
    @discardableResult
    public func activate(
        type: SleepAssertionType,
        reason: String = "Doppio Keep-Awake Session"
    ) -> Bool {
        // Если уже держим утверждение того же типа, ничего менять не нужно
        if assertionID != 0 && currentType == type {
            return true
        }

        // Если тип изменился или уже было утверждение, освобождаем старое
        release()

        let assertionTypeString: CFString
        switch type {
        case .systemAndDisplay:
            assertionTypeString = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        case .systemOnly:
            assertionTypeString = kIOPMAssertionTypePreventUserIdleSystemSleep as CFString
        }

        var newAssertionID: IOPMAssertionID = 0
        let cfReason = reason as CFString

        let result = IOPMAssertionCreateWithName(
            assertionTypeString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            cfReason,
            &newAssertionID
        )

        if result == kIOReturnSuccess {
            self.assertionID = newAssertionID
            self.currentType = type
            logger.info("Утверждение успешно создано: ID=\(newAssertionID), тип=\(type.rawValue)")
            return true
        } else {
            logger.error("Не удалось создать утверждение сна, код ошибки: \(result)")
            self.assertionID = 0
            self.currentType = nil
            return false
        }
    }

    /// Освободить текущее утверждение
    public func release() {
        guard assertionID != 0 else { return }
        let idToRelease = assertionID
        let result = IOPMAssertionRelease(idToRelease)
        logger.info("Освобождение утверждения ID=\(idToRelease), результат: \(result)")
        self.assertionID = 0
        self.currentType = nil
    }
}
