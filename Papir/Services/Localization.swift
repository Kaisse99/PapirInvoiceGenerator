//
//  Localization.swift
//  The app's own language switch, independent of the phone's, because the
//  people using this often run an English phone and want the app in Ukrainian
//  or the other way round. Keys carry their English text as the raw value, so
//  a call site reads as the sentence it renders and English needs no table at
//  all; the table only holds the three translations. The one exception is a
//  key whose English text collides with another case, since raw values must
//  be unique: those few live in englishOverrides. A missing translation
//  falls back to the English raw value rather than showing a key, so a gap
//  looks like untranslated copy instead of a bug.
//  Reading goes through a plain function rather than an environment object
//  because every screen needs it; HomeView rebuilds the tree when the stored
//  language changes, which is what makes a switch take effect everywhere.
//  Used by: every view, and PDFLanguage for the picker names.
//

import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
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

nonisolated enum LKey: String, CaseIterable {
    case menu = "menu"
    case create = "create"
    case stock = "stock"
    case statistics = "statistics"
    case statisticsTitle = "Statistics"
    case thisYear = "This year"
    case everything = "Everything"
    case earnedCaps = "EARNED"
    case averageInvoice = "average"
    case salesOverTimeCaps = "SALES OVER TIME"
    case topBuyersCaps = "TOP BUYERS"
    case noSalesInPeriod = "No sales in this period"
    case perDayLower = "a day"
    case perMonthLower = "a month"
    case modelsWithoutPrice = "models have no price yet"
    case nothingHereYet = "Nothing here yet"

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
    case noPDF = "No PDF"
    case noReceiver = "No receiver"
    case couldNotGeneratePDF = "Couldn't generate PDF"
    case generatePDFIn = "Generate PDF in"

    case senderAndReceiver = "Sender & Receiver"
    case sender = "Sender"
    case defaultSenderPlaceholder = "Your name or business"
    case defaultSenderCaption = "Filled into the sender field on every new invoice"
    case receiver = "Receiver"
    case from = "From"
    case to = "To"
    case date = "Date"
    case items = "Items"
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
    case modelCode = "Model code"
    case modelCodeHint = "Whatever you call it on the shelf"
    case modelCodeInvalid = "A model needs a name or a code."
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

    case pdfTitle = "INVOICE"
    case pdfFrom = "FROM"
    case pdfTo = "TO"
    case pdfItem = "ITEM"
    case pdfQty = "QTY"
    case pdfPrice = "PRICE"
    case pdfTotal = "pdf total"
    case pdfFooter = "GENERATED BY PAPIR"
    case storeFailedTitle = "Could not open your data"
    case storeFailedHint = "The app's database would not open. Trying again usually helps. Starting empty deletes everything stored on this phone."
    case tryAgain = "Try again"
    case startEmpty = "Start empty"
    case startEmptyWarning = "Delete everything on this phone and start empty?"
    case noPDFOnDisk = "No PDF for this invoice yet. Use Re-generate."
    case deleteSelectedTitle = "Delete the selected invoices?"

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
    case notDeducted = "Not deducted"
    case noColorOnRow = "This row has no color, so stock cannot tell what to take"
    case stockUpdated = "Stock updated"
    case stockReturned = "Packs returned to stock"
    case shortfallOnShipment = "Some colors went negative. Recount them when you can."
    case notInStockYet = "This code is not in stock yet."
    case lowStock = "Low"
    case dataCaps = "DATA"
    case backup = "Back up"
    case backupCaption = "One file with everything, for a safe place"
    case restore = "Restore from backup"
    case restoreCaption = "Replaces everything on this phone with the file's contents"
    case restoreConfirmTitle = "Replace everything on this phone?"
    case restored = "Restored"
    case exportEverything = "Export everything"
    case exportCaption = "One Excel workbook: invoices, stock, contacts, history"
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
    case pricePerPiece = "Price per piece"
    case setPrice = "Set price"
    case noPriceYet = "No price set"
    case unitsFollowColors = "Units follow the colors below"
    case differsFromStock = "Not the stock price"

    case addressBook = "Address book"
    case newContact = "New contact"
    case editContact = "Contact"
    case searchContacts = "Name, phone or city..."
    case noContacts = "No contacts yet"
    case noContactsHint = "Add someone you ship to and the receiver field will find them"
    case firstName = "First name"
    case lastName = "Last name"
    case phone = "Phone"
    case city = "City"
    case whoCaps = "WHO"
    case reachThemCaps = "REACH THEM"
    case whereToCaps = "WHERE TO"
    case deleteContact = "Delete contact"
    case deleteContactTitle = "Delete this contact?"
    case deleteContactMessage = "Invoices already written keep the name on them."
    case draftExplained = "Nothing has been taken off the shelf for this invoice yet."
    case shippedExplained = "The packs on this invoice have been deducted from stock."
    case invoicesShipped = "invoices shipped"
    case packsSoldLower = "packs sold"
    case profitabilityCaps = "PROFITABILITY"
    case packsSoldLabel = "Packs sold"
    case ordersMade = "Orders made"
    case inventoryValueCaps = "VALUE OF THE INVENTORY"
    case showMoreFormat = "Show %d more"
    case showLess = "Show less"
    case pdfNumber = "No."
    case backedUpNever = "No backup yet. Everything is on this phone only."
    case backedUpOn = "Last backup"
    case onThisPhoneOnly = "Invoices, stock and contacts live on this phone. If it is lost, so are they. Make a backup or turn on iCloud."
    case aboutCaps = "ABOUT"
    case privacyPolicy = "Privacy policy"
    case supportPage = "Support"
    case versionLabel = "Version"
    case itemsSoldLower = "items sold"
    case itemsSoldLabel = "Items sold"
    case shipmentAddress = "Shipment address"
    case unitsInStock = "units in stock"
    case allInvoices = "All invoices"
    case draftsOnly = "Drafts only"
    case shippedOnly = "Shipped only"
    case addUp = "Add up"
    case welcomeTitle = "Papir"
    case welcomeSubtitle = "Everything is one swipe from here."
    case welcomeCreate = "Write a new invoice"
    case welcomeInvoices = "Everything you have written"
    case welcomeStock = "What is on the shelf"
    case welcomeStats = "What actually sold"
    case welcomeStart = "Start"
    case cannotRevertMissingModel = "These models were deleted, so their packs cannot go back. Add them to stock again first"
    case inAnotherCurrency = "invoices are in another currency and are not counted here"
    case deletingShippedWarning = "This invoice has already shipped. The packs it took stay off the shelf, since they really did leave, and the movement log keeps the record. What goes is the money: it disappears from statistics. To put the stock back, return the invoice to draft first."
    case deletingShippedCount = "Some of these have already shipped. Their packs stay off the shelf and their money disappears from statistics. Return an invoice to draft first if you want its stock back."
    case newRowDefaultsExplained = "Every new invoice row starts with these two numbers, so the ones you type most are already there. Units is how many packs; Per unit is how many pieces are in one pack."
    case sellSinglesExplained = "Selling single items rather than boxes? Set Per unit to 1. The invoice then reads as a plain count times a price, and the × 1 stops appearing on the document."
}

nonisolated enum L {
    static func t(_ key: LKey, _ language: AppLanguage = AppSettings.language) -> String {
        guard language != .english else { return englishOverrides[key] ?? key.rawValue }
        return table[language]?[key] ?? englishOverrides[key] ?? key.rawValue
    }

    static let englishOverrides: [LKey: String] = [
        .pdfTotal: "TOTAL"
    ]

    private static let table: [AppLanguage: [LKey: String]] = [
        .ukrainian: ukrainian,
        .russian: russian,
        .polish: polish
    ]

    static let ukrainian: [LKey: String] = [
        .deletingShippedWarning: "Ця накладна вже відвантажена. Пачки, які вона забрала, зі складу не повернуться, бо вони справді пішли, і в історії руху запис лишиться. Зникнуть гроші: накладна більше не рахуватиметься у статистиці. Щоб повернути склад, спершу поверніть накладну в чернетку.",
        .deletingShippedCount: "Деякі з них уже відвантажені. Їхні пачки зі складу не повернуться, а гроші зникнуть зі статистики. Якщо потрібен склад назад, спершу поверніть накладну в чернетку.",
        .newRowDefaultsExplained: "Кожен новий рядок накладної починається з цих двох чисел, щоб те, що ви вводите найчастіше, вже стояло. Кількість — це скільки пачок; У пачці — скільки штук в одній пачці.",
        .sellSinglesExplained: "Продаєте поштучно, а не коробками? Поставте «У пачці» 1. Тоді накладна читається як кількість помножена на ціну, а × 1 зникає з документа.",
        .inAnotherCurrency: "накладних в іншій валюті сюди не входять",
        .cannotRevertMissingModel: "Ці моделі видалено, тож пачки нікуди повертати. Спочатку додайте їх на склад знову",
        .welcomeTitle: "Papir", .welcomeSubtitle: "Усе за один рух пальця звідси.",
        .welcomeCreate: "Написати нову накладну", .welcomeInvoices: "Усе, що вже написано",
        .welcomeStock: "Що лежить на складі", .welcomeStats: "Що справді продалося",
        .welcomeStart: "Почати",
        .addUp: "Додати",
        .allInvoices: "Усі накладні", .draftsOnly: "Лише чернетки", .shippedOnly: "Лише відвантажені",
        .shipmentAddress: "Адреса доставки", .unitsInStock: "штук на складі",
        .itemsSoldLower: "штук продано", .itemsSoldLabel: "Штук продано",
        .invoicesShipped: "накладних", .packsSoldLower: "пачок продано",
        .profitabilityCaps: "ПРИБУТКОВІСТЬ", .packsSoldLabel: "Пачок продано",
        .ordersMade: "Замовлень зроблено",
        .inventoryValueCaps: "ВАРТІСТЬ СКЛАДУ",
        .showMoreFormat: "Показати ще %d", .showLess: "Згорнути",
        .pdfNumber: "№",
        .backedUpNever: "Копії ще не було. Усе лише на цьому телефоні.",
        .backedUpOn: "Остання копія",
        .onThisPhoneOnly: "Накладні, склад і контакти лежать лише на цьому телефоні. Загубиться він, загубляться й вони. Зробіть копію або увімкніть iCloud.",
        .aboutCaps: "ПРО ЗАСТОСУНОК", .privacyPolicy: "Політика конфіденційності",
        .supportPage: "Підтримка", .versionLabel: "Версія",
        .pdfTitle: "НАКЛАДНА", .pdfFrom: "ВІД", .pdfTo: "ДЛЯ",
        .pdfItem: "ТОВАР", .pdfQty: "К-ТЬ", .pdfPrice: "ЦІНА",
        .pdfTotal: "СУМА", .pdfFooter: "СТВОРЕНО У PAPIR",
        .storeFailedTitle: "Не вдалося відкрити дані",
        .storeFailedHint: "База застосунку не відкрилась. Зазвичай допомагає спробувати ще раз. Почати з порожнього видалить усе на цьому телефоні.",
        .tryAgain: "Спробувати ще раз", .startEmpty: "Почати з порожнього",
        .startEmptyWarning: "Видалити все на цьому телефоні й почати з порожнього?",
        .noPDFOnDisk: "PDF для цієї накладної ще немає. Натисніть Заново.",
        .deleteSelectedTitle: "Видалити вибрані накладні?",
        .draft: "Чернетка", .shipped: "Відвантажено",
        .markShipped: "Відвантажити", .returnToDraft: "У чернетку",
        .shipment: "Відвантаження",
        .shipmentHint: "Перевірте і підтвердіть.",
        .packsLeavingStock: "ПАЧОК ЗІ СКЛАДУ", .confirmShipment: "Підтвердити",
        .notInStock: "Немає на складі",
        .notInStockHint: "Немає такої моделі на складі.",
 .notDeducted: "Не списується", .noColorOnRow: "У рядку немає кольору, тому склад не знає, що брати", .stockUpdated: "Склад оновлено",
        .stockReturned: "Пачки повернуто на склад",
        .shortfallOnShipment: "Деякі кольори пішли в мінус.",
        .notInStockYet: "Цього коду ще немає на складі.",
        .lowStock: "Мало",
        .dataCaps: "ДАНІ", .exportEverything: "Експортувати все",
        .backup: "Резервна копія",
        .backupCaption: "Один файл з усім, для надійного місця",
        .restore: "Відновити з копії",
        .restoreCaption: "Замінює все на цьому телефоні вмістом файлу",
        .restoreConfirmTitle: "Замінити все на цьому телефоні?",
        .restored: "Відновлено",
        .exportCaption: "Одна книга Excel: накладні, склад, контакти, історія",
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
        .statistics: "статистика",
        .statisticsTitle: "Статистика",
        .thisYear: "Цей рік", .everything: "Увесь час",
        .earnedCaps: "ЗАРОБЛЕНО", .averageInvoice: "середня",
        .salesOverTimeCaps: "ДИНАМІКА ПРОДАЖІВ",
        .topBuyersCaps: "ТОП ПОКУПЦІВ",
        .noSalesInPeriod: "У цьому періоді продажів не було",
        .perDayLower: "на день", .perMonthLower: "на місяць", .modelsWithoutPrice: "моделей без ціни",
        .nothingHereYet: "Тут поки порожньо",
        .pricePerPiece: "Ціна за штуку", .setPrice: "Вказати ціну",
        .noPriceYet: "Ціна не вказана",
        .unitsFollowColors: "Пачки рахуються за кольорами",
        .differsFromStock: "Не складська ціна",
        .addressBook: "Адресна книга", .newContact: "Новий контакт",
        .editContact: "Контакт", .searchContacts: "Імʼя, телефон або місто...",
        .noContacts: "Ще немає контактів",
        .noContactsHint: "Додайте, кому ви відправляєте, і поле «Кому» їх знайде",
        .firstName: "Імʼя", .lastName: "Прізвище", .phone: "Телефон",
        .city: "Місто",
        .whoCaps: "ХТО", .reachThemCaps: "ЗВʼЯЗОК", .whereToCaps: "КУДИ",
        .deleteContact: "Видалити контакт", .deleteContactTitle: "Видалити цей контакт?",
        .deleteContactMessage: "Уже виписані накладні збережуть імʼя.",
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
 .noPDF: "Без PDF", .noReceiver: "Без отримувача",
        .couldNotGeneratePDF: "Не вдалося створити PDF",
        .generatePDFIn: "Створити PDF",
        .senderAndReceiver: "Від кого / Кому",
        .sender: "Від кого", .receiver: "Кому",
        .defaultSenderPlaceholder: "Ваше імʼя або фірма",
        .defaultSenderCaption: "Підставляється у поле «Від кого» на кожній новій накладній",
        .from: "Від", .to: "Для", .date: "Дата", .items: "Позицій",
 .row: "Рядок", .name: "Назва",
        .units: "Пачки", .perUnit: "У пачці", .price: "Ціна",
        .colorsCaps: "КОЛЬОРИ", .addColor: "Додати колір...",
        .addNewRow: "Ще рядок", .totalCaps: "УСЬОГО", .subtotal: "Сума",
        .saveInvoice: "Зберегти", .update: "Оновити",
        .saving: "Збереження...", .updating: "Оновлення...",
        .required: "Обов'язково", .deleteRow: "Видалити рядок",
        .stockTitle: "Склад", .searchStock: "Модель або колір...",
        .noModels: "Ще немає моделей",
        .noModelsHint: "Додайте код моделі",
        .newModel: "Нова модель", .modelCode: "Код моделі",
        .modelCodeHint: "Як ви називаєте її на складі",
        .modelCodeInvalid: "Потрібна назва або код.",
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

    static let russian: [LKey: String] = [
        .deletingShippedWarning: "Эта накладная уже отгружена. Пачки, которые она забрала, на склад не вернутся, потому что они действительно ушли, и в истории движения запись останется. Исчезнут деньги: накладная больше не будет считаться в статистике. Чтобы вернуть склад, сначала верните накладную в черновик.",
        .deletingShippedCount: "Некоторые из них уже отгружены. Их пачки на склад не вернутся, а деньги исчезнут из статистики. Если нужен склад обратно, сначала верните накладную в черновик.",
        .newRowDefaultsExplained: "Каждая новая строка накладной начинается с этих двух чисел, чтобы то, что вы вводите чаще всего, уже стояло. Количество — это сколько пачек; В пачке — сколько штук в одной пачке.",
        .sellSinglesExplained: "Продаёте поштучно, а не коробками? Поставьте «В пачке» 1. Тогда накладная читается как количество умноженное на цену, а × 1 исчезает из документа.",
        .inAnotherCurrency: "накладных в другой валюте сюда не входят",
        .cannotRevertMissingModel: "Эти модели удалены, поэтому пачки некуда вернуть. Сначала добавьте их на склад снова",
        .welcomeTitle: "Papir", .welcomeSubtitle: "Всё в одном движении отсюда.",
        .welcomeCreate: "Написать новую накладную", .welcomeInvoices: "Всё, что уже написано",
        .welcomeStock: "Что лежит на складе", .welcomeStats: "Что действительно продалось",
        .welcomeStart: "Начать",
        .addUp: "Добавить",
        .allInvoices: "Все накладные", .draftsOnly: "Только черновики", .shippedOnly: "Только отгруженные",
        .shipmentAddress: "Адрес доставки", .unitsInStock: "штук на складе",
        .itemsSoldLower: "штук продано", .itemsSoldLabel: "Штук продано",
        .invoicesShipped: "накладных", .packsSoldLower: "пачек продано",
        .profitabilityCaps: "ПРИБЫЛЬНОСТЬ", .packsSoldLabel: "Пачек продано",
        .ordersMade: "Заказов сделано",
        .inventoryValueCaps: "СТОИМОСТЬ СКЛАДА",
        .showMoreFormat: "Показать ещё %d", .showLess: "Свернуть",
        .pdfNumber: "№",
        .backedUpNever: "Копии ещё не было. Всё только на этом телефоне.",
        .backedUpOn: "Последняя копия",
        .onThisPhoneOnly: "Накладные, склад и контакты лежат только на этом телефоне. Потеряется он, потеряются и они. Сделайте копию или включите iCloud.",
        .aboutCaps: "О ПРИЛОЖЕНИИ", .privacyPolicy: "Политика конфиденциальности",
        .supportPage: "Поддержка", .versionLabel: "Версия",
        .pdfTitle: "НАКЛАДНАЯ", .pdfFrom: "ОТ", .pdfTo: "ДЛЯ",
        .pdfItem: "ТОВАР", .pdfQty: "К-ВО", .pdfPrice: "ЦЕНА",
        .pdfTotal: "СУММА", .pdfFooter: "СОЗДАНО В PAPIR",
        .storeFailedTitle: "Не удалось открыть данные",
        .storeFailedHint: "База приложения не открылась. Обычно помогает попробовать ещё раз. Начать с пустого удалит всё на этом телефоне.",
        .tryAgain: "Попробовать ещё раз", .startEmpty: "Начать с пустого",
        .startEmptyWarning: "Удалить всё на этом телефоне и начать с пустого?",
        .noPDFOnDisk: "PDF для этой накладной ещё нет. Нажмите Заново.",
        .deleteSelectedTitle: "Удалить выбранные накладные?",
        .draft: "Черновик", .shipped: "Отгружено",
        .markShipped: "Отгрузить", .returnToDraft: "В черновик",
        .shipment: "Отгрузка",
        .shipmentHint: "Проверьте и подтвердите.",
        .packsLeavingStock: "ПАЧЕК СО СКЛАДА", .confirmShipment: "Подтвердить",
        .notInStock: "Нет на складе",
        .notInStockHint: "Такой модели нет на складе.",
 .notDeducted: "Не списывается", .noColorOnRow: "В строке нет цвета, поэтому склад не знает, что брать", .stockUpdated: "Склад обновлён",
        .stockReturned: "Пачки возвращены на склад",
        .shortfallOnShipment: "Некоторые цвета ушли в минус.",
        .notInStockYet: "Этого кода ещё нет на складе.",
        .lowStock: "Мало",
        .dataCaps: "ДАННЫЕ", .exportEverything: "Экспортировать всё",
        .backup: "Резервная копия",
        .backupCaption: "Один файл со всем, для надёжного места",
        .restore: "Восстановить из копии",
        .restoreCaption: "Заменяет всё на этом телефоне содержимым файла",
        .restoreConfirmTitle: "Заменить всё на этом телефоне?",
        .restored: "Восстановлено",
        .exportCaption: "Одна книга Excel: накладные, склад, контакты, история",
        .iCloudSync: "iCloud", .iCloudSyncCaption: "Накладные и склад на всех устройствах",
        .allModels: "Все модели", .lockedWhileShipped: "Верните в черновик, чтобы изменить", .allDays: "Все дни",
        .clearHistory: "Очистить историю", .clearHistoryCaption: "Убрать все записи движения",
        .clearHistoryWarning: "Остатки не изменятся, но как они сложились будет потеряно.",
        .restartToApply: "Перезапустите приложение.",
        .iCloudUnavailable: "iCloud недоступен, данные хранятся локально. Проверьте вход.", .lowStockThreshold: "Мало на складе",
        .lowStockCaption: "Предупреждать от этого количества",
        .history: "История", .noMovements: "Пока ничего не двигалось",
        .movementReceived: "Принято", .movementRemoved: "Списано",
        .movementReturned: "Возвращено",
        .movementRecounted: "Пересчитано", .assignedToColors: "по цветам", .draftExplained: "Со склада ещё ничего не списано.", .shippedExplained: "Пачки уже списаны со склада.",
        .menu: "меню", .create: "создать", .stock: "склад",
        .statistics: "статистика",
        .statisticsTitle: "Статистика",
        .thisYear: "Этот год", .everything: "Всё время",
        .earnedCaps: "ЗАРАБОТАНО", .averageInvoice: "средняя",
        .salesOverTimeCaps: "ДИНАМИКА ПРОДАЖ",
        .topBuyersCaps: "ТОП ПОКУПАТЕЛЕЙ",
        .noSalesInPeriod: "В этом периоде продаж не было",
        .perDayLower: "в день", .perMonthLower: "в месяц", .modelsWithoutPrice: "моделей без цены",
        .nothingHereYet: "Пока пусто",
        .pricePerPiece: "Цена за штуку", .setPrice: "Указать цену",
        .noPriceYet: "Цена не указана",
        .unitsFollowColors: "Пачки считаются по цветам",
        .differsFromStock: "Не складская цена",
        .addressBook: "Адресная книга", .newContact: "Новый контакт",
        .editContact: "Контакт", .searchContacts: "Имя, телефон или город...",
        .noContacts: "Пока нет контактов",
        .noContactsHint: "Добавьте, кому вы отправляете, и поле «Кому» их найдёт",
        .firstName: "Имя", .lastName: "Фамилия", .phone: "Телефон",
        .city: "Город",
        .whoCaps: "КТО", .reachThemCaps: "СВЯЗЬ", .whereToCaps: "КУДА",
        .deleteContact: "Удалить контакт", .deleteContactTitle: "Удалить этот контакт?",
        .deleteContactMessage: "Уже выписанные накладные сохранят имя.",
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
 .noPDF: "Без PDF", .noReceiver: "Без получателя",
        .couldNotGeneratePDF: "Не удалось создать PDF",
        .generatePDFIn: "Создать PDF",
        .senderAndReceiver: "От кого / Кому",
        .sender: "От кого", .receiver: "Кому",
        .defaultSenderPlaceholder: "Ваше имя или фирма",
        .defaultSenderCaption: "Подставляется в поле «От кого» на каждой новой накладной",
        .from: "От", .to: "Для", .date: "Дата", .items: "Позиций",
 .row: "Строка", .name: "Название",
        .units: "Пачки", .perUnit: "В пачке", .price: "Цена",
        .colorsCaps: "ЦВЕТА", .addColor: "Добавить цвет...",
        .addNewRow: "Ещё строка", .totalCaps: "ИТОГО", .subtotal: "Сумма",
        .saveInvoice: "Сохранить", .update: "Обновить",
        .saving: "Сохранение...", .updating: "Обновление...",
        .required: "Обязательно", .deleteRow: "Удалить строку",
        .stockTitle: "Склад", .searchStock: "Модель или цвет...",
        .noModels: "Пока нет моделей",
        .noModelsHint: "Добавьте код модели",
        .newModel: "Новая модель", .modelCode: "Код модели",
        .modelCodeHint: "Как вы называете её на складе",
        .modelCodeInvalid: "Нужно название или код.",
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

    static let polish: [LKey: String] = [
        .deletingShippedWarning: "Ta faktura została już wysłana. Paczki, które zabrała, nie wrócą do magazynu, bo naprawdę wyszły, a w historii ruchu wpis zostanie. Znikną pieniądze: faktura przestanie liczyć się w statystykach. Aby odzyskać stan magazynu, najpierw cofnij fakturę do szkicu.",
        .deletingShippedCount: "Niektóre z nich zostały już wysłane. Ich paczki nie wrócą do magazynu, a pieniądze znikną ze statystyk. Jeśli chcesz odzyskać stan magazynu, najpierw cofnij fakturę do szkicu.",
        .newRowDefaultsExplained: "Każdy nowy wiersz faktury zaczyna się od tych dwóch liczb, żeby to, co wpisujesz najczęściej, już tam było. Ilość to liczba paczek; W paczce to liczba sztuk w jednej paczce.",
        .sellSinglesExplained: "Sprzedajesz na sztuki, a nie w kartonach? Ustaw „W paczce” na 1. Faktura czyta się wtedy jako liczba razy cena, a × 1 znika z dokumentu.",
        .inAnotherCurrency: "faktur w innej walucie nie jest tu liczonych",
        .cannotRevertMissingModel: "Te modele usunięto, więc paczki nie mają dokąd wrócić. Najpierw dodaj je ponownie do magazynu",
        .welcomeTitle: "Papir", .welcomeSubtitle: "Wszystko o jeden gest stąd.",
        .welcomeCreate: "Napisz nową fakturę", .welcomeInvoices: "Wszystko, co już napisane",
        .welcomeStock: "Co jest w magazynie", .welcomeStats: "Co naprawdę się sprzedało",
        .welcomeStart: "Zacznij",
        .addUp: "Dodaj",
        .allInvoices: "Wszystkie faktury", .draftsOnly: "Tylko szkice", .shippedOnly: "Tylko wysłane",
        .shipmentAddress: "Adres dostawy", .unitsInStock: "sztuk w magazynie",
        .itemsSoldLower: "sztuk sprzedanych", .itemsSoldLabel: "Sztuk sprzedanych",
        .invoicesShipped: "faktur wysłanych", .packsSoldLower: "paczek sprzedanych",
        .profitabilityCaps: "RENTOWNOŚĆ", .packsSoldLabel: "Paczek sprzedanych",
        .ordersMade: "Złożonych zamówień",
        .inventoryValueCaps: "WARTOŚĆ MAGAZYNU",
        .showMoreFormat: "Pokaż jeszcze %d", .showLess: "Zwiń",
        .pdfNumber: "Nr",
        .backedUpNever: "Brak kopii zapasowej. Wszystko tylko na tym telefonie.",
        .backedUpOn: "Ostatnia kopia",
        .onThisPhoneOnly: "Faktury, magazyn i kontakty są tylko na tym telefonie. Zgubi się on, zgubią się i one. Zrób kopię albo włącz iCloud.",
        .aboutCaps: "O APLIKACJI", .privacyPolicy: "Polityka prywatności",
        .supportPage: "Wsparcie", .versionLabel: "Wersja",
        .pdfTitle: "FAKTURA", .pdfFrom: "OD", .pdfTo: "DLA",
        .pdfItem: "TOWAR", .pdfQty: "ILOSC", .pdfPrice: "CENA",
        .pdfTotal: "SUMA", .pdfFooter: "UTWORZONE W PAPIR",
        .storeFailedTitle: "Nie udało się otworzyć danych",
        .storeFailedHint: "Baza aplikacji nie otworzyła się. Zwykle pomaga spróbować ponownie. Zaczęcie od pustej usunie wszystko na tym telefonie.",
        .tryAgain: "Spróbuj ponownie", .startEmpty: "Zacznij od pustej",
        .startEmptyWarning: "Usunąć wszystko na tym telefonie i zacząć od pustej?",
        .noPDFOnDisk: "Nie ma jeszcze PDF dla tej faktury. Użyj Ponownie.",
        .deleteSelectedTitle: "Usunąć wybrane faktury?",
        .draft: "Szkic", .shipped: "Wysłano",
        .markShipped: "Oznacz jako wysłane", .returnToDraft: "Wróć do szkicu",
        .shipment: "Wysyłka",
        .shipmentHint: "Sprawdź, co schodzi z magazynu, i potwierdź.",
        .packsLeavingStock: "Paczek z magazynu", .confirmShipment: "Potwierdź",
        .notInStock: "Brak w magazynie",
        .notInStockHint: "Żaden model w magazynie nie pasuje do tego wiersza, więc nic nie zostanie odjęte.",
 .notDeducted: "Nie odjęto", .noColorOnRow: "Ten wiersz nie ma koloru, więc magazyn nie wie, co wydać", .stockUpdated: "Magazyn zaktualizowany",
        .stockReturned: "Paczki wrócily na magazyn",
        .shortfallOnShipment: "Niektóre kolory zeszły poniżej zera. Przelicz je przy okazji.",
        .notInStockYet: "Tego kodu nie ma jeszcze w magazynie.",
        .lowStock: "Mało", .lowStockThreshold: "Niski stan",
        .dataCaps: "DANE", .exportEverything: "Eksportuj wszystko",
        .backup: "Kopia zapasowa",
        .backupCaption: "Jeden plik ze wszystkim, do bezpiecznego miejsca",
        .restore: "Przywróć z kopii",
        .restoreCaption: "Zastępuje wszystko na tym telefonie zawartością pliku",
        .restoreConfirmTitle: "Zastąpić wszystko na tym telefonie?",
        .restored: "Przywrócono",
        .exportCaption: "Jeden skoroszyt Excel: faktury, magazyn, kontakty, historia",
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
        .statistics: "statystyka",
        .statisticsTitle: "Statystyka",
        .thisYear: "Ten rok", .everything: "Cały czas",
        .earnedCaps: "ZAROBIONE", .averageInvoice: "średnia",
        .salesOverTimeCaps: "SPRZEDAŻ W CZASIE",
        .topBuyersCaps: "NAJLEPSI KUPUJĄCY",
        .noSalesInPeriod: "Brak sprzedaży w tym okresie",
        .perDayLower: "dziennie", .perMonthLower: "miesięcznie", .modelsWithoutPrice: "modeli bez ceny",
        .nothingHereYet: "Na razie pusto",
        .pricePerPiece: "Cena za sztukę", .setPrice: "Ustal cenę",
        .noPriceYet: "Brak ceny",
        .unitsFollowColors: "Paczki liczone wg kolorów",
        .differsFromStock: "Inna niż cena z magazynu",
        .addressBook: "Książka adresowa", .newContact: "Nowy kontakt",
        .editContact: "Kontakt", .searchContacts: "Imię, telefon lub miasto...",
        .noContacts: "Brak kontaktów",
        .noContactsHint: "Dodaj odbiorcę, a pole \"Do\" go znajdzie",
        .firstName: "Imię", .lastName: "Nazwisko", .phone: "Telefon",
        .city: "Miasto",
        .whoCaps: "KTO", .reachThemCaps: "KONTAKT", .whereToCaps: "DOKĄD",
        .deleteContact: "Usuń kontakt", .deleteContactTitle: "Usunąć ten kontakt?",
        .deleteContactMessage: "Wystawione faktury zachowają nazwę.",
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
 .noPDF: "Brak PDF", .noReceiver: "Brak odbiorcy",
        .couldNotGeneratePDF: "Nie udało się utworzyć PDF",
        .generatePDFIn: "Utwórz PDF w",
        .senderAndReceiver: "Nadawca i odbiorca",
        .sender: "Nadawca", .receiver: "Odbiorca",
        .defaultSenderPlaceholder: "Twoje imię lub firma",
        .defaultSenderCaption: "Wypełnia pole nadawcy na każdej nowej fakturze",
        .from: "Od", .to: "Do", .date: "Data", .items: "Pozycji",
 .row: "Wiersz", .name: "Nazwa",
        .units: "Paczki", .perUnit: "W paczce", .price: "Cena",
        .colorsCaps: "KOLORY", .addColor: "Dodaj kolor...",
        .addNewRow: "Dodaj wiersz", .totalCaps: "RAZEM", .subtotal: "Suma",
        .saveInvoice: "Zapisz", .update: "Zaktualizuj",
        .saving: "Zapisywanie...", .updating: "Aktualizowanie...",
        .required: "Wymagane", .deleteRow: "Usuń wiersz",
        .stockTitle: "Magazyn", .searchStock: "Szukaj modelu lub koloru...",
        .noModels: "Brak modeli",
        .noModelsHint: "Dodaj kod modelu, aby liczyć paczki",
        .newModel: "Nowy model", .modelCode: "Kod modelu",
        .modelCodeHint: "Jak nazywasz go w magazynie",
        .modelCodeInvalid: "Potrzebna nazwa lub kod.",
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
