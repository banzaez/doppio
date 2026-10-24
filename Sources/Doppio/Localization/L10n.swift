import Foundation

/// Менеджер локализации и перевода текстов Doppio
public struct L10n: Sendable {
    public let language: AppLanguage

    public init(language: AppLanguage) {
        self.language = language
    }

    private var code: String {
        language.effectiveCode
    }

    // MARK: - Состояния Doppio
    public var statusAwakeIndefinitely: String {
        switch code {
        case "uk": return "Бадьорий безстроково"
        case "ru": return "Бодрствует бессрочно"
        case "de": return "Dauerhaft aktiv"
        case "fr": return "Éveillé indéfiniment"
        case "es": return "Despierto indefinidamente"
        default:   return "Awake indefinitely"
        }
    }

    public func statusRemaining(_ timeString: String) -> String {
        switch code {
        case "uk": return "Залишилося: \(timeString)"
        case "ru": return "Осталось: \(timeString)"
        case "de": return "Verbleibend: \(timeString)"
        case "fr": return "Restant : \(timeString)"
        case "es": return "Restante: \(timeString)"
        default:   return "Remaining: \(timeString)"
        }
    }

    public var statusSleepAllowed: String {
        switch code {
        case "uk": return "Сон дозволено"
        case "ru": return "Сон разрешён"
        case "de": return "Ruhezustand erlaubt"
        case "fr": return "Veille autorisée"
        case "es": return "Reposo permitido"
        default:   return "Sleep allowed"
        }
    }

    // MARK: - Таймер и пресеты
    public var sectionTimer: String {
        switch code {
        case "uk": return "ТАЙМЕР БАДЬОРОСТІ"
        case "ru": return "ТАЙМЕР БОДРСТВОВАНИЯ"
        case "de": return "AKTIVITÄTS-TIMER"
        case "fr": return "MINUTERIE D'ÉVEIL"
        case "es": return "TEMPORIZADOR"
        default:   return "KEEP-AWAKE TIMER"
        }
    }

    public var presetIndefinite: String {
        switch code {
        case "uk": return "Безстроково"
        case "ru": return "Бессрочно"
        case "de": return "Unbegrenzt"
        case "fr": return "Indéfini"
        case "es": return "Indefinido"
        default:   return "Indefinite"
        }
    }

    public func presetMinutes(_ min: Int) -> String {
        switch code {
        case "uk": return "\(min) хв"
        case "ru": return "\(min) мин"
        case "de": return "\(min) Min"
        case "fr": return "\(min) min"
        case "es": return "\(min) min"
        default:   return "\(min) min"
        }
    }

    public func presetHours(_ hours: Int) -> String {
        switch code {
        case "uk": return hours == 1 ? "1 год" : "\(hours) год"
        case "ru": return hours == 1 ? "1 час" : "\(hours) часа"
        case "de": return "\(hours) Std"
        case "fr": return "\(hours) h"
        case "es": return "\(hours) h"
        default:   return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }

    public var minuteSuffix: String {
        switch code {
        case "uk": return "хв"
        case "ru": return "мин"
        case "de": return "Min"
        case "fr": return "min"
        case "es": return "min"
        default:   return "min"
        }
    }

    public var presetCustom: String {
        switch code {
        case "uk": return "Власний таймер"
        case "ru": return "Свой таймер"
        case "de": return "Eigener Timer"
        case "fr": return "Minuteur personnalisé"
        case "es": return "Temporizador propio"
        default:   return "Custom timer"
        }
    }

    // MARK: - Режимы бодрствования
    public var sectionMode: String {
        switch code {
        case "uk": return "РЕЖИМ БАДЬОРОСТІ"
        case "ru": return "РЕЖИМ БОДРСТВОВАНИЯ"
        case "de": return "AKTIVITÄTSMODUS"
        case "fr": return "MODE D'ÉVEIL"
        case "es": return "MODO DE ACTIVIDAD"
        default:   return "KEEP-AWAKE MODE"
        }
    }

    public var modeDisplayAndMac: String {
        switch code {
        case "uk": return "Екран і Mac"
        case "ru": return "Экран и Mac"
        case "de": return "Bildschirm & Mac"
        case "fr": return "Écran et Mac"
        case "es": return "Pantalla y Mac"
        default:   return "Screen & Mac"
        }
    }

    public var modeDisplayDesc: String {
        switch code {
        case "uk": return "Екран не згасне, блокування не ввімкнеться"
        case "ru": return "Дисплей не погаснет, блокировка не включится"
        case "de": return "Bildschirm bleibt an, Sperre deaktiviert"
        case "fr": return "L'écran reste allumé, pas de verrouillage"
        case "es": return "La pantalla sigue encendida, sin bloqueo"
        default:   return "Display stays on, screen lock disabled"
        }
    }

    public var modeMacOnly: String {
        switch code {
        case "uk": return "Тільки Mac"
        case "ru": return "Только Mac"
        case "de": return "Nur Mac"
        case "fr": return "Mac uniquement"
        case "es": return "Solo Mac"
        default:   return "Mac only"
        }
    }

    public var modeMacOnlyDesc: String {
        switch code {
        case "uk": return "Екран може спати, фонові процеси продовжать роботу"
        case "ru": return "Дисплей может спать, фоновые задачи продолжат работу"
        case "de": return "Bildschirm darf schlafen, Hintergrundaufgaben laufen"
        case "fr": return "L'écran peut s'éteindre, les tâches continuent"
        case "es": return "La pantalla puede apagarse, tareas continúan"
        default:   return "Display may sleep, background tasks continue"
        }
    }

    // MARK: - Батарея и питание
    public var batteryCharging: String {
        switch code {
        case "uk": return "Заряджання"
        case "ru": return "Зарядка"
        case "de": return "Wird geladen"
        case "fr": return "En charge"
        case "es": return "Cargando"
        default:   return "Charging"
        }
    }

    public var batteryAC: String {
        switch code {
        case "uk": return "Мережа"
        case "ru": return "Сеть"
        case "de": return "Netzteil"
        case "fr": return "Secteur"
        case "es": return "Adaptador"
        default:   return "AC Power"
        }
    }

    public var batteryOnBattery: String {
        switch code {
        case "uk": return "Батарея"
        case "ru": return "Батарея"
        case "de": return "Batterie"
        case "fr": return "Batterie"
        case "es": return "Batería"
        default:   return "Battery"
        }
    }

    // MARK: - Настройки
    public var settingsTitle: String {
        switch code {
        case "uk": return "Налаштування"
        case "ru": return "Настройки"
        case "de": return "Einstellungen"
        case "fr": return "Paramètres"
        case "es": return "Ajustes"
        default:   return "Settings"
        }
    }

    public var backButton: String {
        switch code {
        case "uk": return "Назад"
        case "ru": return "Назад"
        case "de": return "Zurück"
        case "fr": return "Retour"
        case "es": return "Atrás"
        default:   return "Back"
        }
    }

    public var settingsLanguage: String {
        switch code {
        case "uk": return "Мова інтерфейсу"
        case "ru": return "Язык интерфейса"
        case "de": return "Sprache"
        case "fr": return "Langue"
        case "es": return "Idioma"
        default:   return "Language"
        }
    }

    public var settingsLaunchAtLogin: String {
        switch code {
        case "uk": return "Запуск під час входу в систему"
        case "ru": return "Запуск при входе в систему"
        case "de": return "Beim Anmelden starten"
        case "fr": return "Lancer à la connexion"
        case "es": return "Iniciar al arrancar el sistema"
        default:   return "Launch at login"
        }
    }

    public var settingsTimerInMenuBar: String {
        switch code {
        case "uk": return "Показувати таймер у рядку меню"
        case "ru": return "Отображать таймер в строке меню"
        case "de": return "Timer in Menüleiste anzeigen"
        case "fr": return "Afficher la minuterie dans la barre"
        case "es": return "Mostrar temporizador en la barra"
        default:   return "Show timer in menu bar"
        }
    }

    public var settingsSound: String {
        switch code {
        case "uk": return "Звукові сигнали"
        case "ru": return "Звуковые сигналы"
        case "de": return "Tonsignale"
        case "fr": return "Effets sonores"
        case "es": return "Efectos de sonido"
        default:   return "Sound effects"
        }
    }

    public var settingsBatteryProtection: String {
        switch code {
        case "uk": return "Захист батареї"
        case "ru": return "Защита батареи"
        case "de": return "Batterieschutz"
        case "fr": return "Protection de la batterie"
        case "es": return "Protección de batería"
        default:   return "Battery protection"
        }
    }

    public var settingsBatteryThresholdDesc: String {
        switch code {
        case "uk": return "Вимикати бадьорість при заряді нижче:"
        case "ru": return "Выключать бодрствование при заряде ниже:"
        case "de": return "Deaktivieren wenn Akku unter:"
        case "fr": return "Désactiver si batterie sous :"
        case "es": return "Desactivar si la batería baja de:"
        default:   return "Turn off keep-awake below:"
        }
    }

    public var closeButton: String {
        switch code {
        case "uk": return "Закрити"
        case "ru": return "Закрыть"
        case "de": return "Schließen"
        case "fr": return "Fermer"
        case "es": return "Cerrar"
        default:   return "Close"
        }
    }

    public var quitButton: String {
        switch code {
        case "uk": return "Закрити Doppio"
        case "ru": return "Закрыть Doppio"
        case "de": return "Doppio beenden"
        case "fr": return "Quitter Doppio"
        case "es": return "Salir de Doppio"
        default:   return "Quit Doppio"
        }
    }
}
