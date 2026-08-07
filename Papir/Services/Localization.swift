//
//  Localization.swift
//  The app's own language switch, independent of the phone's, because the
//  people using this often run an English phone and want the app in Ukrainian
//  or the other way round. Keys carry their English text as the raw value, so
//  a call site reads as the sentence it renders and English needs no table at
//  all; the table only holds the three translations. A missing translation
//  falls back to the English raw value rather than showing a key, so a gap
//  looks like untranslated copy instead of a bug.
//  Reading goes through a plain function rather than an environment object
//  because every screen needs it; HomeView rebuilds the tree when the stored
//  language changes, which is what makes a switch take effect everywhere.
//  Used by: every view, and PDFLanguage for the picker names.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case ukrainian
    case russian
    case polish

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:   return "English"
        case .ukrainian: return "Українська"
        case .russian:   return "Русский"
        case .polish:    return "Polski"
        }
    }

    var flag: String {
        switch self {
        case .english:   return "🇬🇧"
        case .ukrainian: return "🇺🇦"
        case .russian:   return "🇷🇺"
        case .polish:    return "🇵🇱"
        }
    }

    var locale: Locale {
        switch self {
        case .english:   return Locale(identifier: "en_US")
        case .ukrainian: return Locale(identifier: "uk_UA")
        case .russian:   return Locale(identifier: "ru_RU")
        case .polish:    return Locale(identifier: "pl_PL")
        }
    }

    var pdfLanguage: PDFLanguage {
        switch self {
        case .english:   return .english
        case .ukrainian: return .ukrainian
        case .russian:   return .russian
        case .polish:    return .polish
        }
    }
}

enum LKey: String {
    case menu = "menu"
    case create = "create"
    case stock = "stock"

    case settings = "Settings"
    case done = "Done"
    case cancel = "Cancel"
    case delete = "Delete"
    case ok = "OK"
    case add = "Add"

    case language = "Language"
    case currency = "Currency"
    case newRowDefaults = "NEW ROW DEFAULTS"
    case unitsSettingCaption = "How many packs a new row starts at"
    case perUnitSettingCaption = "Pieces in one pack"
    case zeroLeavesEmpty = "Set either to 0 to leave that field empty on a new row."

    case invoices = "Invoices"
    case invoice = "Invoice"
    case newInvoice = "Invoice +"
    case editInvoice = "Edit Invoice"
    case searchInvoices = "Search invoices..."
    case noInvoices = "No invoices yet"
    case noInvoicesHint = "Swipe up on home to create your first one"
    case noMatches = "No matches"
    case newest = "Newest"
    case oldest = "Oldest"
    case lowestPrice = "Lowest price"
    case highestPrice = "Highest price"
    case selectInvoices = "Select invoices"
    case doneSelecting = "Done selecting"
    case selected = "selected"
    case share = "Share"
    case duplicate = "Duplicate"
    case viewPDF = "View PDF"
    case regenerate = "Re-generate"
    case makeChanges = "Make Changes"
    case deleteInvoiceTitle = "Delete this invoice?"
    case cannotBeUndone = "This action cannot be undone."
    case pdfReady = "PDF ready"
    case noPDF = "No PDF"
    case noReceiver = "No receiver"
    case couldNotGeneratePDF = "Couldn't generate PDF"
    case generatePDFIn = "Generate PDF in"
    case chooseLanguage = "Choose the language"

    case senderAndReceiver = "Sender & Receiver"
    case sender = "Sender"
    case receiver = "Receiver"
    case from = "From"
    case to = "To"
    case date = "Date"
    case items = "Items"
    case entry = "Entry"
    case row = "Row"
    case name = "Name"
    case units = "Units"
    case perUnit = "Per unit"
    case price = "Price"
    case colorsCaps = "COLORS"
    case addColor = "Add color..."
    case addNewRow = "Add new row"
    case totalCaps = "TOTAL"
    case subtotal = "Subtotal"
    case saveInvoice = "Save Invoice"
    case update = "Update"
    case saving = "Saving..."
    case updating = "Updating..."
    case required = "Required"
    case deleteRow = "Delete row"

    case stockTitle = "Stock"
    case searchStock = "Search model or color..."
    case noModels = "No models yet"
    case noModelsHint = "Add a model code to start counting packs"
    case newModel = "New model"
    case modelCodeHint = "Four digits, plus a letter if it has one"
    case modelCodeInvalid = "A model code is four digits, with an optional letter. For example 1987 or 6395C."
    case modelExists = "Model already exists"
    case addModel = "Add model"
    case deleteModel = "Delete model"
    case deleteModelTitle = "Delete this model?"
    case deleteModelMessage = "Everything counted under it will be removed."
    case totalPacksCaps = "TOTAL PACKS"
    case noColorsYet = "No colors yet"
    case nothingCounted = "Nothing counted yet"
    case takeStockIn = "Take stock in"
    case takeStockOut = "Take stock out"
    case takeOut = "Take out"
    case takeOutAnyway = "Take out anyway"
    case recount = "Recount"
    case saveCount = "Save count"
    case color = "Color"
    case packs = "Packs"
    case pack = "pack"
    case packsLower = "packs"
    case onHand = "On hand"
    case recorded = "Recorded"
    case packsOnShelf = "Packs on the shelf"
    case left = "left"
    case moreThanOnHand = "more than is on hand. The count will go negative until you recount."
    case wentNegative = "Stock went negative"
    case shortBy = "was short by"
    case negativeExplanation = "The count is now negative so it stands out until you recount."
    case couldNotSave = "Could not save"
    case inStock = "In stock"
    case outOfStock = "Out"
    case remove = "Remove"
    case home = "Home"

    case draft = "Draft"
    case shipped = "Shipped"
    case markShipped = "Mark as shipped"
    case returnToDraft = "Return to draft"
    case shipment = "Shipment"
    case shipmentHint = "Check what comes off the shelf, then confirm."
    case packsLeavingStock = "Packs leaving stock"
    case confirmShipment = "Confirm shipment"
    case notInStock = "Not in stock"
    case notInStockHint = "No model in stock matches this row, so nothing is deducted for it."
    case pickColor = "Pick a color"
    case notDeducted = "Not deducted"
    case noColorOnRow = "This row has no color, so stock cannot tell what to take"
    case stockUpdated = "Stock updated"
    case stockReturned = "Packs returned to stock"
    case shortfallOnShipment = "Some colors went negative. Recount them when you can."
    case notInStockYet = "This code is not in stock yet."
    case colorsOnTheShelf = "On the shelf"
    case lowStock = "Low"
    case iCloudSync = "iCloud"
    case allModels = "All models"
    case lockedWhileShipped = "Return to draft to make changes"
    case allDays = "All days"
    case clearHistory = "Clear history"
    case clearHistoryCaption = "Remove every recorded movement"
    case clearHistoryWarning = "Stock counts stay as they are, but how they got there is lost."
    case iCloudSyncCaption = "Keep invoices and stock on all your devices"
    case restartToApply = "Reopen the app to apply."
    case iCloudUnavailable = "iCloud is not available, so the app is using local storage. Check that you are signed in."
    case lowStockThreshold = "Low stock"
    case lowStockCaption = "Warn at this many packs or fewer"
    case history = "History"
    case noMovements = "Nothing has moved yet"
    case movementReceived = "Taken in"
    case movementRemoved = "Taken out"
    case movementReturned = "Returned"
    case movementRecounted = "Recounted"
    case assignedToColors = "assigned to colors"
    case draftExplained = "Nothing has been taken off the shelf for this invoice yet."
    case shippedExplained = "The packs on this invoice have been deducted from stock."
}

enum L {
    static func t(_ key: LKey, _ language: AppLanguage = AppSettings.language) -> String {
        guard language != .english else { return key.rawValue }
        return table[language]?[key] ?? key.rawValue
    }

    private static let table: [AppLanguage: [LKey: String]] = [
        .ukrainian: ukrainian,
        .russian: russian,
        .polish: polish
    ]

    private static let ukrainian: [LKey: String] = [
        .draft: "Чернетка", .shipped: "Відвантажено",
        .markShipped: "Відвантажити", .returnToDraft: "У чернетку",
        .shipment: "Відвантаження",
        .shipmentHint: "Перевірте і підтвердіть.",
        .packsLeavingStock: "ПАЧОК ЗІ СКЛАДУ", .confirmShipment: "Підтвердити",
        .notInStock: "Немає на складі",
        .notInStockHint: "Немає такої моделі на складі.",
        .pickColor: "Оберіть колір", .notDeducted: "Не списується", .noColorOnRow: "У рядку немає кольору, тому склад не знає, що брати", .stockUpdated: "Склад оновлено",
        .stockReturned: "Пачки повернуто на склад",
        .shortfallOnShipment: "Деякі кольори пішли в мінус.",
        .notInStockYet: "Цього коду ще немає на складі.", .colorsOnTheShelf: "На складі",
        .lowStock: "Мало",
        .iCloudSync: "iCloud", .iCloudSyncCaption: "Накладні та склад на всіх пристроях",
        .allModels: "Усі моделі", .lockedWhileShipped: "Поверніть у чернетку, щоб змінити", .allDays: "Усі дні",
        .clearHistory: "Очистити історію", .clearHistoryCaption: "Прибрати всі записи руху",
        .clearHistoryWarning: "Залишки не зміняться, але як вони склались буде втрачено.",
        .restartToApply: "Перезапустіть застосунок.",
        .iCloudUnavailable: "iCloud недоступний, дані зберігаються локально. Перевірте вхід.", .lowStockThreshold: "Мало на складі",
        .lowStockCaption: "Попереджати від цієї кількості",
        .history: "Історія", .noMovements: "Ще нічого не рухалось",
        .movementReceived: "Прийнято", .movementRemoved: "Списано",
        .movementReturned: "Повернено",
        .movementRecounted: "Перераховано", .assignedToColors: "по кольорах", .draftExplained: "Зі складу ще нічого не списано.", .shippedExplained: "Пачки вже списані зі складу.",
        .menu: "меню", .create: "створити", .stock: "склад",
        .settings: "Налаштування", .done: "Готово", .cancel: "Скасувати",
        .delete: "Видалити", .ok: "Гаразд", .add: "Додати",
        .language: "Мова", .currency: "Валюта",
        .newRowDefaults: "ЗА ЗАМОВЧУВАННЯМ",
        .unitsSettingCaption: "Пачок у новому рядку",
        .perUnitSettingCaption: "Штук в одній пачці",
        .zeroLeavesEmpty: "0 — поле буде порожнім.",
        .invoices: "Накладні", .invoice: "Накладна", .newInvoice: "Накладна +",
        .editInvoice: "Правка", .searchInvoices: "Пошук...",
        .noInvoices: "Ще немає накладних",
        .noInvoicesHint: "Проведіть вгору",
        .noMatches: "Нічого не знайдено",
        .newest: "Найновіші", .oldest: "Найстаріші",
        .lowestPrice: "Дешевші", .highestPrice: "Дорожчі",
        .selectInvoices: "Вибрати", .doneSelecting: "Готово",
        .selected: "вибрано", .share: "Поділитися", .duplicate: "Дублювати",
        .viewPDF: "Відкрити", .regenerate: "Заново",
        .makeChanges: "Редагувати",
        .deleteInvoiceTitle: "Видалити цю накладну?",
        .cannotBeUndone: "Цю дію не можна скасувати.",
        .pdfReady: "PDF готовий", .noPDF: "Без PDF", .noReceiver: "Без отримувача",
        .couldNotGeneratePDF: "Не вдалося створити PDF",
        .generatePDFIn: "Створити PDF", .chooseLanguage: "Оберіть мову",
        .senderAndReceiver: "Від кого / Кому",
        .sender: "Від кого", .receiver: "Кому",
        .from: "Від", .to: "Для", .date: "Дата", .items: "Позицій",
        .entry: "Позиція", .row: "Рядок", .name: "Назва",
        .units: "Пачки", .perUnit: "У пачці", .price: "Ціна",
        .colorsCaps: "КОЛЬОРИ", .addColor: "Додати колір...",
        .addNewRow: "Ще рядок", .totalCaps: "УСЬОГО", .subtotal: "Сума",
        .saveInvoice: "Зберегти", .update: "Оновити",
        .saving: "Збереження...", .updating: "Оновлення...",
        .required: "Обов'язково", .deleteRow: "Видалити рядок",
        .stockTitle: "Склад", .searchStock: "Модель або колір...",
        .noModels: "Ще немає моделей",
        .noModelsHint: "Додайте код моделі",
        .newModel: "Нова модель",
        .modelCodeHint: "Чотири цифри та літера",
        .modelCodeInvalid: "Чотири цифри та літера. Наприклад 1987 або 6395C.",
        .modelExists: "Така модель вже є",
        .addModel: "Додати модель", .deleteModel: "Видалити модель",
        .deleteModelTitle: "Видалити цю модель?",
        .deleteModelMessage: "Усі залишки буде видалено.",
        .totalPacksCaps: "ПАЧОК", .noColorsYet: "Ще немає кольорів", .nothingCounted: "Порожньо",
        .takeStockIn: "Прийняти", .takeStockOut: "Списати",
        .takeOut: "Списати", .takeOutAnyway: "Все одно",
        .recount: "Перерахувати", .saveCount: "Зберегти",
        .color: "Колір", .packs: "Пачки", .pack: "пачка", .packsLower: "пачок",
        .onHand: "У наявності", .recorded: "Обліковано",
        .packsOnShelf: "Пачок на полиці", .left: "залишиться",
        .moreThanOnHand: "понад залишок. Кількість стане відʼємною.",
        .wentNegative: "Відʼємний залишок",
        .shortBy: "не вистачило",
        .negativeExplanation: "Залишок відʼємний, поки не перерахуєте.",
        .couldNotSave: "Не вдалося зберегти",
        .inStock: "У наявності", .outOfStock: "Немає",
        .remove: "Прибрати", .home: "Головна"
    ]

    private static let russian: [LKey: String] = [
        .draft: "Черновик", .shipped: "Отгружено",
        .markShipped: "Отгрузить", .returnToDraft: "В черновик",
        .shipment: "Отгрузка",
        .shipmentHint: "Проверьте и подтвердите.",
        .packsLeavingStock: "ПАЧЕК СО СКЛАДА", .confirmShipment: "Подтвердить",
        .notInStock: "Нет на складе",
        .notInStockHint: "Такой модели нет на складе.",
        .pickColor: "Выберите цвет", .notDeducted: "Не списывается", .noColorOnRow: "В строке нет цвета, поэтому склад не знает, что брать", .stockUpdated: "Склад обновлён",
        .stockReturned: "Пачки возвращены на склад",
        .shortfallOnShipment: "Некоторые цвета ушли в минус.",
        .notInStockYet: "Этого кода ещё нет на складе.", .colorsOnTheShelf: "На складе",
        .lowStock: "Мало",
        .iCloudSync: "iCloud", .iCloudSyncCaption: "Накладні та склад на всіх пристроях",
        .allModels: "Усі моделі", .lockedWhileShipped: "Поверніть у чернетку, щоб змінити", .allDays: "Усі дні",
        .clearHistory: "Очистити історію", .clearHistoryCaption: "Прибрати всі записи руху",
        .clearHistoryWarning: "Залишки не зміняться, але як вони склались буде втрачено.",
        .restartToApply: "Перезапустіть застосунок.",
        .iCloudUnavailable: "iCloud недоступний, дані зберігаються локально. Перевірте вхід.", .lowStockThreshold: "Мало на складе",
        .lowStockCaption: "Предупреждать от этого количества",
        .history: "История", .noMovements: "Пока ничего не двигалось",
        .movementReceived: "Принято", .movementRemoved: "Списано",
        .movementReturned: "Возвращено",
        .movementRecounted: "Пересчитано", .assignedToColors: "по цветам", .draftExplained: "Со склада ещё ничего не списано.", .shippedExplained: "Пачки уже списаны со склада.",
        .menu: "меню", .create: "создать", .stock: "склад",
        .settings: "Настройки", .done: "Готово", .cancel: "Отмена",
        .delete: "Удалить", .ok: "Хорошо", .add: "Добавить",
        .language: "Язык", .currency: "Валюта",
        .newRowDefaults: "ПО УМОЛЧАНИЮ",
        .unitsSettingCaption: "Пачек в новой строке",
        .perUnitSettingCaption: "Штук в одной пачке",
        .zeroLeavesEmpty: "0 — поле будет пустым.",
        .invoices: "Накладные", .invoice: "Накладная", .newInvoice: "Накладная +",
        .editInvoice: "Правка", .searchInvoices: "Поиск...",
        .noInvoices: "Пока нет накладных",
        .noInvoicesHint: "Проведите вверх",
        .noMatches: "Ничего не найдено",
        .newest: "Новые", .oldest: "Старые",
        .lowestPrice: "Дешевле", .highestPrice: "Дороже",
        .selectInvoices: "Выбрать", .doneSelecting: "Готово",
        .selected: "выбрано", .share: "Поделиться", .duplicate: "Дублировать",
        .viewPDF: "Открыть", .regenerate: "Заново",
        .makeChanges: "Редактировать",
        .deleteInvoiceTitle: "Удалить эту накладную?",
        .cannotBeUndone: "Это действие нельзя отменить.",
        .pdfReady: "PDF готов", .noPDF: "Без PDF", .noReceiver: "Без получателя",
        .couldNotGeneratePDF: "Не удалось создать PDF",
        .generatePDFIn: "Создать PDF", .chooseLanguage: "Выберите язык",
        .senderAndReceiver: "От кого / Кому",
        .sender: "От кого", .receiver: "Кому",
        .from: "От", .to: "Для", .date: "Дата", .items: "Позиций",
        .entry: "Позиция", .row: "Строка", .name: "Название",
        .units: "Пачки", .perUnit: "В пачке", .price: "Цена",
        .colorsCaps: "ЦВЕТА", .addColor: "Добавить цвет...",
        .addNewRow: "Ещё строка", .totalCaps: "ИТОГО", .subtotal: "Сумма",
        .saveInvoice: "Сохранить", .update: "Обновить",
        .saving: "Сохранение...", .updating: "Обновление...",
        .required: "Обязательно", .deleteRow: "Удалить строку",
        .stockTitle: "Склад", .searchStock: "Модель или цвет...",
        .noModels: "Пока нет моделей",
        .noModelsHint: "Добавьте код модели",
        .newModel: "Новая модель",
        .modelCodeHint: "Четыре цифры и буква",
        .modelCodeInvalid: "Четыре цифры и буква. Например 1987 или 6395C.",
        .modelExists: "Такая модель уже есть",
        .addModel: "Добавить модель", .deleteModel: "Удалить модель",
        .deleteModelTitle: "Удалить эту модель?",
        .deleteModelMessage: "Все остатки будут удалены.",
        .totalPacksCaps: "ПАЧЕК", .noColorsYet: "Пока нет цветов", .nothingCounted: "Пусто",
        .takeStockIn: "Принять", .takeStockOut: "Списать",
        .takeOut: "Списать", .takeOutAnyway: "Всё равно",
        .recount: "Пересчитать", .saveCount: "Сохранить",
        .color: "Цвет", .packs: "Пачки", .pack: "пачка", .packsLower: "пачек",
        .onHand: "В наличии", .recorded: "Учтено",
        .packsOnShelf: "Пачек на полке", .left: "останется",
        .moreThanOnHand: "сверх остатка. Количество уйдёт в минус.",
        .wentNegative: "Отрицательный остаток",
        .shortBy: "не хватило",
        .negativeExplanation: "Остаток в минусе, пока не пересчитаете.",
        .couldNotSave: "Не удалось сохранить",
        .inStock: "В наличии", .outOfStock: "Нет",
        .remove: "Убрать", .home: "Главная"
    ]

    private static let polish: [LKey: String] = [
        .draft: "Szkic", .shipped: "Wysłano",
        .markShipped: "Oznacz jako wysłane", .returnToDraft: "Wróć do szkicu",
        .shipment: "Wysyłka",
        .shipmentHint: "Sprawdź, co schodzi z magazynu, i potwierdź.",
        .packsLeavingStock: "Paczek z magazynu", .confirmShipment: "Potwierdź",
        .notInStock: "Brak w magazynie",
        .notInStockHint: "Żaden model w magazynie nie pasuje do tego wiersza, więc nic nie zostanie odjęte.",
        .pickColor: "Wybierz kolor", .notDeducted: "Nie odjęto", .noColorOnRow: "Ten wiersz nie ma koloru, więc magazyn nie wie, co wydać", .stockUpdated: "Magazyn zaktualizowany",
        .stockReturned: "Paczki wrócily na magazyn",
        .shortfallOnShipment: "Niektóre kolory zeszły poniżej zera. Przelicz je przy okazji.",
        .notInStockYet: "Tego kodu nie ma jeszcze w magazynie.", .colorsOnTheShelf: "W magazynie",
        .lowStock: "Mało", .lowStockThreshold: "Niski stan",
        .iCloudSync: "iCloud", .iCloudSyncCaption: "Faktury i magazyn na wszystkich urządzeniach",
        .allModels: "Wszystkie modele", .lockedWhileShipped: "Wróć do szkicu, aby edytować", .allDays: "Wszystkie dni",
        .clearHistory: "Wyczyść historię", .clearHistoryCaption: "Usuń wszystkie zapisy ruchu",
        .clearHistoryWarning: "Stany zostaną, ale historia ich powstania zniknie.",
        .restartToApply: "Uruchom aplikację ponownie.",
        .iCloudUnavailable: "iCloud niedostępny, dane są lokalne. Sprawdź logowanie.",
        .lowStockCaption: "Ostrzegaj przy tylu paczkach lub mniej",
        .history: "Historia", .noMovements: "Nic się jeszcze nie ruszyło",
        .movementReceived: "Przyjęto", .movementRemoved: "Wydano",
        .movementReturned: "Zwrócono",
        .movementRecounted: "Przeliczono", .assignedToColors: "przypisano", .draftExplained: "Nic jeszcze nie zeszło z magazynu dla tej faktury.", .shippedExplained: "Paczki z tej faktury zostały odjęte od stanu.",
        .menu: "menu", .create: "nowa", .stock: "magazyn",
        .settings: "Ustawienia", .done: "Gotowe", .cancel: "Anuluj",
        .delete: "Usuń", .ok: "OK", .add: "Dodaj",
        .language: "Język", .currency: "Waluta",
        .newRowDefaults: "DOMYŚLNE WARTOŚCI",
        .unitsSettingCaption: "Ile paczek ma nowy wiersz",
        .perUnitSettingCaption: "Sztuk w jednej paczce",
        .zeroLeavesEmpty: "Ustaw 0, aby pole pozostało puste.",
        .invoices: "Faktury", .invoice: "Faktura", .newInvoice: "Faktura +",
        .editInvoice: "Edycja faktury", .searchInvoices: "Szukaj faktur...",
        .noInvoices: "Brak faktur",
        .noInvoicesHint: "Przesuń w górę, aby utworzyć pierwszą",
        .noMatches: "Brak wyników",
        .newest: "Najnowsze", .oldest: "Najstarsze",
        .lowestPrice: "Najtańsze", .highestPrice: "Najdroższe",
        .selectInvoices: "Wybierz faktury", .doneSelecting: "Gotowe",
        .selected: "wybrano", .share: "Udostępnij", .duplicate: "Duplikuj",
        .viewPDF: "Otwórz PDF", .regenerate: "Utwórz ponownie",
        .makeChanges: "Edytuj",
        .deleteInvoiceTitle: "Usunąć tę fakturę?",
        .cannotBeUndone: "Tej operacji nie można cofnąć.",
        .pdfReady: "PDF gotowy", .noPDF: "Brak PDF", .noReceiver: "Brak odbiorcy",
        .couldNotGeneratePDF: "Nie udało się utworzyć PDF",
        .generatePDFIn: "Utwórz PDF w", .chooseLanguage: "Wybierz język",
        .senderAndReceiver: "Nadawca i odbiorca",
        .sender: "Nadawca", .receiver: "Odbiorca",
        .from: "Od", .to: "Do", .date: "Data", .items: "Pozycji",
        .entry: "Pozycja", .row: "Wiersz", .name: "Nazwa",
        .units: "Paczki", .perUnit: "W paczce", .price: "Cena",
        .colorsCaps: "KOLORY", .addColor: "Dodaj kolor...",
        .addNewRow: "Dodaj wiersz", .totalCaps: "RAZEM", .subtotal: "Suma",
        .saveInvoice: "Zapisz", .update: "Zaktualizuj",
        .saving: "Zapisywanie...", .updating: "Aktualizowanie...",
        .required: "Wymagane", .deleteRow: "Usuń wiersz",
        .stockTitle: "Magazyn", .searchStock: "Szukaj modelu lub koloru...",
        .noModels: "Brak modeli",
        .noModelsHint: "Dodaj kod modelu, aby liczyć paczki",
        .newModel: "Nowy model",
        .modelCodeHint: "Cztery cyfry, opcjonalnie z literą",
        .modelCodeInvalid: "Kod modelu to cztery cyfry i opcjonalna litera. Na przykład 1987 lub 6395C.",
        .modelExists: "Taki model już istnieje",
        .addModel: "Dodaj model", .deleteModel: "Usuń model",
        .deleteModelTitle: "Usunąć ten model?",
        .deleteModelMessage: "Wszystko, co na nim policzono, zostanie usunięte.",
        .totalPacksCaps: "RAZEM PACZEK", .noColorsYet: "Brak kolorów", .nothingCounted: "Nic jeszcze nie policzono",
        .takeStockIn: "Przyjmij na magazyn", .takeStockOut: "Wydaj z magazynu",
        .takeOut: "Wydaj", .takeOutAnyway: "Wydaj mimo to",
        .recount: "Przelicz", .saveCount: "Zapisz",
        .color: "Kolor", .packs: "Paczki", .pack: "paczka", .packsLower: "paczek",
        .onHand: "Na stanie", .recorded: "Zapisano",
        .packsOnShelf: "Paczek na półce", .left: "zostanie",
        .moreThanOnHand: "więcej niż jest na stanie. Stan będzie ujemny do czasu przeliczenia.",
        .wentNegative: "Stan magazynu jest ujemny",
        .shortBy: "zabrakło",
        .negativeExplanation: "Stan jest teraz ujemny, żeby rzucał się w oczy do czasu przeliczenia.",
        .couldNotSave: "Nie udało się zapisać",
        .inStock: "Na stanie", .outOfStock: "Brak",
        .remove: "Usuń", .home: "Główna"
    ]
}
