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
        case "uk":
            return "\(hours) год"
        case "ru":
            let mod10 = hours % 10
            let mod100 = hours % 100
            if mod10 == 1 && mod100 != 11 {
                return "\(hours) час"
            } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
                return "\(hours) часа"
            } else {
                return "\(hours) часов"
            }
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

    /// Текст бейджа для строки меню (например: 45м, 45хв, 45m, 1ч 15м)
    public func menuBarBadgeText(hours: Int, minutes: Int) -> String {
        let hSuffix: String
        let mSuffix: String

        switch code {
        case "uk":
            hSuffix = "г"
            mSuffix = "хв"
        case "ru":
            hSuffix = "ч"
            mSuffix = "м"
        case "de":
            hSuffix = "Std"
            mSuffix = "Min"
        default:
            hSuffix = "h"
            mSuffix = "m"
        }

        if hours > 0 {
            return "\(hours)\(hSuffix)\(minutes > 0 ? " \(minutes)\(mSuffix)" : "")"
        } else if minutes > 0 {
            return "\(minutes)\(mSuffix)"
        } else {
            return "<1\(mSuffix)"
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

    public var desktopMacNoBattery: String {
        switch code {
        case "uk": return "Живлення від мережі (без акумулятора)"
        case "ru": return "Питание от сети (без аккумулятора)"
        case "de": return "Netzbetrieb (keine Batterie)"
        case "fr": return "Alimentation secteur (sans batterie)"
        case "es": return "Alimentación de CA (sin batería)"
        default:   return "AC Power (no battery)"
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

    // MARK: - Причины отключения (Deactivation Reasons)
    public var reasonUserDisabled: String {
        switch code {
        case "uk": return "Вимкнено користувачем"
        case "ru": return "Отключено пользователем"
        case "de": return "Vom Benutzer deaktiviert"
        case "fr": return "Désactivé par l'utilisateur"
        case "es": return "Desactivado por el usuario"
        default:   return "Disabled by user"
        }
    }

    public var reasonSessionCompleted: String {
        switch code {
        case "uk": return "Сесію завершено"
        case "ru": return "Сессия завершена"
        case "de": return "Sitzung beendet"
        case "fr": return "Session terminée"
        case "es": return "Sesión finalizada"
        default:   return "Session completed"
        }
    }

    public var reasonTimerExpired: String {
        switch code {
        case "uk": return "Час таймера вичерпано"
        case "ru": return "Время таймера истекло"
        case "de": return "Timer abgelaufen"
        case "fr": return "Minuterie écoulée"
        case "es": return "Temporizador finalizado"
        default:   return "Timer expired"
        }
    }

    public func reasonBatteryLow(_ pct: Int) -> String {
        switch code {
        case "uk": return "Низький заряд батареї (\(pct)%)"
        case "ru": return "Низкий заряд батареи (\(pct)%)"
        case "de": return "Niedriger Akkustand (\(pct)%)"
        case "fr": return "Batterie faible (\(pct)%)"
        case "es": return "Batería baja (\(pct)%)"
        default:   return "Low battery (\(pct)%)"
        }
    }

    public var reasonQuitApp: String {
        switch code {
        case "uk": return "Завершення роботи"
        case "ru": return "Завершение работы"
        case "de": return "Programm beendet"
        case "fr": return "Fermeture de l'application"
        case "es": return "Cierre de la app"
        default:   return "Application quitting"
        }
    }

    public func reasonAppTerminated(_ appName: String) -> String {
        switch code {
        case "uk": return "Закрито: \(appName)"
        case "ru": return "Закрыто: \(appName)"
        case "de": return "Beendet: \(appName)"
        case "fr": return "Fermé : \(appName)"
        case "es": return "Cerrado: \(appName)"
        default:   return "Closed: \(appName)"
        }
    }

    public var reasonPowerDisconnected: String {
        switch code {
        case "uk": return "Живлення від мережі вимкнено"
        case "ru": return "Отключено питание от сети"
        case "de": return "Netzteil getrennt"
        case "fr": return "Alimentation secteur débranchée"
        case "es": return "Adaptador de corriente desconectado"
        default:   return "AC power disconnected"
        }
    }

    public var reasonExternalDisplayDisconnected: String {
        switch code {
        case "uk": return "Зовнішній дисплей від'єднано"
        case "ru": return "Внешний дисплей отключен"
        case "de": return "Externer Bildschirm getrennt"
        case "fr": return "Écran externe déconnecté"
        case "es": return "Pantalla externa desconectada"
        default:   return "External display disconnected"
        }
    }

    // MARK: - Стили строки меню (Menu Bar Display Style)
    public var menuBarStyleTitle: String {
        switch code {
        case "uk": return "Стиль у рядку меню"
        case "ru": return "Стиль в строке меню"
        case "de": return "Menüleisten-Stil"
        case "fr": return "Style de la barre des menus"
        case "es": return "Estilo en la barra de menú"
        default:   return "Menu Bar Style"
        }
    }

    public var menuBarStyleStandard: String {
        switch code {
        case "uk": return "Стандартний"
        case "ru": return "Стандартный"
        case "de": return "Standard"
        case "fr": return "Standard"
        case "es": return "Estándar"
        default:   return "Standard"
        }
    }

    public var menuBarStyleIconOnly: String {
        switch code {
        case "uk": return "Тільки іконка"
        case "ru": return "Только иконка"
        case "de": return "Nur Symbol"
        case "fr": return "Icône seule"
        case "es": return "Solo icono"
        default:   return "Icon only"
        }
    }

    public var menuBarStyleDesc: String {
        switch code {
        case "uk": return "Приховує час для заощадження місця під вирізом MacBook Pro"
        case "ru": return "Скрывает время для экономии места под вырезом MacBook Pro"
        case "de": return "Verbirgt die Zeit, um Platz unter der MacBook Pro Notch zu sparen"
        case "fr": return "Masque l'heure pour économiser l'espace sous l'encoche du MacBook Pro"
        case "es": return "Oculta el tiempo para ahorrar espacio bajo el notch de MacBook Pro"
        default:   return "Hides timer text to save space under the MacBook Pro notch"
        }
    }

    // MARK: - Быстрый клик (Quick Click)
    public var settingsQuickToggle: String {
        switch code {
        case "uk": return "Швидкий ⌥-клік для перемикання"
        case "ru": return "Быстрый ⌥-клик для переключения"
        case "de": return "Schneller ⌥-Klick zum Umschalten"
        case "fr": return "Basculement rapide avec ⌥-clic"
        case "es": return "Cambio rápido con ⌥-clic"
        default:   return "Quick toggle via ⌥-click"
        }
    }

    public var settingsQuickToggleDesc: String {
        switch code {
        case "uk": return "Option-клік або правий клік по іконці миттєво перемикає бадьорість"
        case "ru": return "Option-клик или правый клик по иконке мгновенно переключает бодрствование"
        case "de": return "Option-Klick oder Rechtsklick schaltet den Modus sofort um"
        case "fr": return "Un clic avec Option ou clic droit bascule l'état sans ouvrir le menu"
        case "es": return "Un clic con Option o clic derecho activa/desactiva sin abrir el menú"
        default:   return "Option-click or right-click instantly toggles state without opening popover"
        }
    }

    // MARK: - Уведомления перед окончанием таймера
    public var settingsNotifyBeforeSleep: String {
        switch code {
        case "uk": return "Попереджати за 1 хв до засинання"
        case "ru": return "Предупреждать за 1 мин до сна"
        case "de": return "1 Min vor Ruhezustand warnen"
        case "fr": return "Prévenir 1 min avant la veille"
        case "es": return "Avisar 1 min antes de reposo"
        default:   return "Notify 1 min before sleep"
        }
    }

    public var notificationSessionEndingTitle: String {
        switch code {
        case "uk": return "Doppio — Сесія закінчується"
        case "ru": return "Doppio — Сессия завершается"
        case "de": return "Doppio — Sitzung endet bald"
        case "fr": return "Doppio — La session se termine"
        case "es": return "Doppio — La sesión está por terminar"
        default:   return "Doppio — Session Ending Soon"
        }
    }

    public var notificationSessionEndingBody: String {
        switch code {
        case "uk": return "До засинання системи залишилася 1 хвилина."
        case "ru": return "До засыпания системы осталась 1 минута."
        case "de": return "Das System wechselt in 1 Minute in den Ruhezustand."
        case "fr": return "Le système se mettra en veille dans 1 minute."
        case "es": return "El sistema entrará en reposo en 1 minuto."
        default:   return "Your Mac will be allowed to sleep in 1 minute."
        }
    }

    public var notificationActionExtend15: String {
        switch code {
        case "uk": return "+15 хв"
        case "ru": return "+15 мин"
        case "de": return "+15 Min"
        case "fr": return "+15 min"
        case "es": return "+15 min"
        default:   return "+15 min"
        }
    }

    public var notificationActionIndefinite: String {
        switch code {
        case "uk": return "∞ Безстроково"
        case "ru": return "∞ Бессрочно"
        case "de": return "∞ Unbegrenzt"
        case "fr": return "∞ Indéfini"
        case "es": return "∞ Indefinido"
        default:   return "∞ Indefinite"
        }
    }

    // MARK: - Умные триггеры (Smart Triggers)
    public var settingsSmartTriggersSection: String {
        switch code {
        case "uk": return "РОЗУМНІ ТРИГЕРИ"
        case "ru": return "УМНЫЕ ТРИГГЕРЫ"
        case "de": return "INTELLIGENTE TRIGGER"
        case "fr": return "DÉCLENCHEURS INTELLIGENTS"
        case "es": return "DISPARADORES INTELIGENTES"
        default:   return "SMART TRIGGERS"
        }
    }

    public var settingsAppTriggers: String {
        switch code {
        case "uk": return "Тригери додатків"
        case "ru": return "Триггеры приложений"
        case "de": return "App-Trigger"
        case "fr": return "Déclencheurs d'apps"
        case "es": return "Disparadores de apps"
        default:   return "App Triggers"
        }
    }

    public var settingsAppTriggersDesc: String {
        switch code {
        case "uk": return "Тримати Mac бадьорим, поки працює будь-яка з цих програм"
        case "ru": return "Держать Mac активным, пока работает любая из этих программ"
        case "de": return "Mac aktiv halten, solange eine dieser Apps läuft"
        case "fr": return "Garder le Mac éveillé tant que l'une de ces apps est active"
        case "es": return "Mantener el Mac despierto mientras alguna de estas apps esté abierta"
        default:   return "Keep Mac awake while any of these apps are running"
        }
    }

    public var settingsAddAppButton: String {
        switch code {
        case "uk": return "Додати програму"
        case "ru": return "Добавить приложение"
        case "de": return "App hinzufügen"
        case "fr": return "Ajouter une app"
        case "es": return "Añadir app"
        default:   return "Add Application"
        }
    }

    public var settingsChooseFromDisk: String {
        switch code {
        case "uk": return "Обрати з диска (.app)..."
        case "ru": return "Выбрать с диска (.app)..."
        case "de": return "Vom Mac auswählen (.app)..."
        case "fr": return "Choisir sur le disque (.app)..."
        case "es": return "Elegir desde el disco (.app)..."
        default:   return "Choose from disk (.app)..."
        }
    }

    public var settingsRunningAppsSection: String {
        switch code {
        case "uk": return "Запущені програми"
        case "ru": return "Запущенные программы"
        case "de": return "Laufende Apps"
        case "fr": return "Apps en cours d'exécution"
        case "es": return "Apps en ejecución"
        default:   return "Running Applications"
        }
    }

    public var settingsNoTargetApps: String {
        switch code {
        case "uk": return "Немає доданих програм"
        case "ru": return "Нет добавленных приложений"
        case "de": return "Keine Apps hinzugefügt"
        case "fr": return "Aucune app ajoutée"
        case "es": return "No hay apps añadidas"
        default:   return "No apps configured"
        }
    }

    public var settingsAcPowerTrigger: String {
        switch code {
        case "uk": return "Вмикати при живленні від мережі"
        case "ru": return "Включать при питании от сети"
        case "de": return "Bei Netzstrom aktivieren"
        case "fr": return "Activer sur alimentation secteur"
        case "es": return "Activar con corriente CA"
        default:   return "Activate on AC power"
        }
    }

    public var settingsBatteryDeactivateTrigger: String {
        switch code {
        case "uk": return "Вимикати при роботі від батареї"
        case "ru": return "Выключать при работе от батареи"
        case "de": return "Bei Akkubetrieb deaktivieren"
        case "fr": return "Désactiver sur batterie"
        case "es": return "Desactivar al usar batería"
        default:   return "Deactivate on battery power"
        }
    }

    public var settingsExternalDisplayTrigger: String {
        switch code {
        case "uk": return "Вмикати при зовнішньому моніторі"
        case "ru": return "Включать при внешнем мониторе"
        case "de": return "Bei externem Bildschirm aktivieren"
        case "fr": return "Activer sur écran externe"
        case "es": return "Activar con pantalla externa"
        default:   return "Activate on external display"
        }
    }
}
