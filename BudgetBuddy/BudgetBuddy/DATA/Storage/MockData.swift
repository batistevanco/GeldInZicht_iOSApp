// /Data/Storage/MockData.swift
//
// Realistic Belgian demo data for screenshots and testing.
// Call MockData.seed(context:) to populate the database.
// WARNING: clears ALL existing data first.

import SwiftData
import Foundation

enum MockData {

    // MARK: - Public entry point

    static func seed(context: ModelContext) {
        clearAll(context: context)

        let categories = insertCategories(context: context)
        let accounts   = insertAccounts(context: context)
        let goals      = insertSavingGoals(context: context)
        insertTransactions(context: context,
                           categories: categories,
                           accounts: accounts,
                           goals: goals)

        do { try context.save() }
        catch { assertionFailure("MockData seed failed: \(error)") }
    }

    // MARK: - Clear

    private static func clearAll(context: ModelContext) {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: SavingGoal.self)
        try? context.delete(model: Account.self)
        try? context.delete(model: Category.self)
    }

    // MARK: - Categories

    private struct Categories {
        var werk: Category
        var boodschappen: Category
        var huur: Category
        var vrijeTijd: Category
        var abonnementen: Category
        var transport: Category
        var restaurant: Category
        var gezondheidszorg: Category
        var kleding: Category
        var onderwijs: Category
    }

    private static func insertCategories(context: ModelContext) -> Categories {
        let werk          = Category(name: "Werk",           iconName: "briefcase.fill",      isDefault: true)
        let boodschappen  = Category(name: "Boodschappen",   iconName: "cart.fill",            isDefault: true)
        let huur          = Category(name: "Huur",           iconName: "house.fill",           isDefault: true)
        let vrijeTijd     = Category(name: "Vrije tijd",     iconName: "gamecontroller.fill",  isDefault: true)
        let abonnementen  = Category(name: "Abonnementen",   iconName: "repeat",               isDefault: true)
        let transport     = Category(name: "Transport",      iconName: "car.fill",             isDefault: true)
        let restaurant    = Category(name: "Restaurant",     iconName: "fork.knife",           isDefault: false)
        let gezondheid    = Category(name: "Gezondheidszorg",iconName: "cross.fill",           isDefault: false)
        let kleding       = Category(name: "Kleding",        iconName: "tshirt.fill",          isDefault: false)
        let onderwijs     = Category(name: "Onderwijs",      iconName: "book.fill",            isDefault: false)

        [werk, boodschappen, huur, vrijeTijd, abonnementen,
         transport, restaurant, gezondheid, kleding, onderwijs].forEach { context.insert($0) }

        return Categories(werk: werk, boodschappen: boodschappen, huur: huur,
                          vrijeTijd: vrijeTijd, abonnementen: abonnementen,
                          transport: transport, restaurant: restaurant,
                          gezondheidszorg: gezondheid, kleding: kleding, onderwijs: onderwijs)
    }

    // MARK: - Accounts

    private struct Accounts {
        var zichtrekening: Account
        var spaarrekening: Account
        var cash: Account
    }

    private static func insertAccounts(context: ModelContext) -> Accounts {
        let zicht = Account(name: "BNP Zichtrekening", type: .checking, initialBalance: 1_250.00)
        zicht.iconName  = "creditcard.fill"
        zicht.colorHex  = "#3B82F6"
        zicht.isDefault = true

        let spaar = Account(name: "ING Spaarrekening", type: .savings, initialBalance: 8_500.00)
        spaar.iconName = "banknote.fill"
        spaar.colorHex = "#10B981"

        let cash = Account(name: "Portemonnee", type: .cash, initialBalance: 120.00)
        cash.iconName  = "banknote"
        cash.colorHex  = "#F59E0B"

        [zicht, spaar, cash].forEach { context.insert($0) }

        return Accounts(zichtrekening: zicht, spaarrekening: spaar, cash: cash)
    }

    // MARK: - Saving Goals

    private struct SavingGoals {
        var vakantie: SavingGoal
        var auto: SavingGoal
        var noodfonds: SavingGoal
    }

    private static func insertSavingGoals(context: ModelContext) -> SavingGoals {
        let vakantie = SavingGoal(name: "Vakantie Italië", goalAmount: 2_500.00)
        vakantie.currentAmount   = 1_100.00
        vakantie.iconName        = "airplane"
        vakantie.colorHex        = "#8B5CF6"
        vakantie.descriptionText = "Zomervakantie 2025 – Toscane"

        let auto = SavingGoal(name: "Nieuwe auto", goalAmount: 15_000.00)
        auto.currentAmount   = 4_200.00
        auto.iconName        = "car.fill"
        auto.colorHex        = "#EF4444"
        auto.descriptionText = "Tweedehands elektrisch"

        let noodfonds = SavingGoal(name: "Noodfonds", goalAmount: 5_000.00)
        noodfonds.currentAmount   = 5_000.00
        noodfonds.iconName        = "shield.fill"
        noodfonds.colorHex        = "#14B8A6"
        noodfonds.descriptionText = "3 maanden levenskosten"

        [vakantie, auto, noodfonds].forEach { context.insert($0) }

        return SavingGoals(vakantie: vakantie, auto: auto, noodfonds: noodfonds)
    }

    // MARK: - Transactions

    private static func insertTransactions(
        context: ModelContext,
        categories: Categories,
        accounts: Accounts,
        goals: SavingGoals
    ) {
        let now = Date()
        let cal = Calendar.current

        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        func monthsAgo(_ m: Int, day: Int = 1) -> Date {
            var comps = cal.dateComponents([.year, .month], from: now)
            comps.month! -= m
            comps.day = day
            return cal.date(from: comps) ?? now
        }

        var txns: [Transaction] = []

        // --- RECURRING TEMPLATES ---

        let salaris = Transaction(type: .income, amount: 2_850.00,
                                  date: monthsAgo(0, day: 25),
                                  frequency: .monthly, isRecurringTemplate: true)
        salaris.descriptionText    = "Nettoloon mei"
        salaris.destinationAccount = accounts.zichtrekening
        salaris.category           = categories.werk
        txns.append(salaris)

        let huurTemplate = Transaction(type: .expense, amount: 795.00,
                                       date: monthsAgo(0, day: 1),
                                       frequency: .monthly, isRecurringTemplate: true)
        huurTemplate.descriptionText = "Huur appartement"
        huurTemplate.sourceAccount   = accounts.zichtrekening
        huurTemplate.category        = categories.huur
        txns.append(huurTemplate)

        let netflixTemplate = Transaction(type: .expense, amount: 15.99,
                                          date: monthsAgo(0, day: 8),
                                          frequency: .monthly, isRecurringTemplate: true)
        netflixTemplate.descriptionText = "Netflix"
        netflixTemplate.sourceAccount   = accounts.zichtrekening
        netflixTemplate.category        = categories.abonnementen
        txns.append(netflixTemplate)

        let spotifyTemplate = Transaction(type: .expense, amount: 11.99,
                                          date: monthsAgo(0, day: 8),
                                          frequency: .monthly, isRecurringTemplate: true)
        spotifyTemplate.descriptionText = "Spotify"
        spotifyTemplate.sourceAccount   = accounts.zichtrekening
        spotifyTemplate.category        = categories.abonnementen
        txns.append(spotifyTemplate)

        // --- CURRENT MONTH ---

        txns.append(contentsOf: [
            income(2_850.00, "Nettoloon mei", daysAgo(5),
                   dest: accounts.zichtrekening, cat: categories.werk),

            expense(795.00, "Huur mei", daysAgo(14),
                    src: accounts.zichtrekening, cat: categories.huur),

            expense(87.40, "Carrefour", daysAgo(2),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(54.20, "Delhaize", daysAgo(9),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(32.50, "MIVB maandkaart", daysAgo(1),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(45.80, "Restaurant Bonsai", daysAgo(3),
                    src: accounts.zichtrekening, cat: categories.restaurant),

            expense(15.99, "Netflix", daysAgo(6),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(11.99, "Spotify", daysAgo(6),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(29.95, "Gym abonnement", daysAgo(6),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(68.00, "H&M kleding", daysAgo(10),
                    src: accounts.cash, cat: categories.kleding),

            expense(22.00, "Bioscooptickets", daysAgo(4),
                    src: accounts.cash, cat: categories.vrijeTijd),

            saving(200.00, "Spaarpot vakantie mei", daysAgo(7),
                   src: accounts.zichtrekening, goal: goals.vakantie),

            transfer(100.00, "Zakgeld cash", daysAgo(12),
                     src: accounts.zichtrekening, dest: accounts.cash),
        ])

        // --- PREVIOUS MONTH ---

        txns.append(contentsOf: [
            income(2_850.00, "Nettoloon april", monthsAgo(1, day: 25),
                   dest: accounts.zichtrekening, cat: categories.werk),

            expense(795.00, "Huur april", monthsAgo(1, day: 1),
                    src: accounts.zichtrekening, cat: categories.huur),

            expense(112.60, "Colruyt", monthsAgo(1, day: 3),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(63.40, "Lidl", monthsAgo(1, day: 17),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(38.50, "Tankbeurt", monthsAgo(1, day: 5),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(32.50, "MIVB maandkaart", monthsAgo(1, day: 1),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(15.99, "Netflix", monthsAgo(1, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(11.99, "Spotify", monthsAgo(1, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(29.95, "Gym abonnement", monthsAgo(1, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(89.00, "Dr. Peeters – tandarts", monthsAgo(1, day: 14),
                    src: accounts.zichtrekening, cat: categories.gezondheidszorg),

            expense(54.99, "Zara", monthsAgo(1, day: 19),
                    src: accounts.cash, cat: categories.kleding),

            expense(34.00, "Resto Le Beau", monthsAgo(1, day: 22),
                    src: accounts.cash, cat: categories.restaurant),

            expense(24.00, "Concerttickets", monthsAgo(1, day: 11),
                    src: accounts.cash, cat: categories.vrijeTijd),

            saving(300.00, "Spaarpot vakantie april", monthsAgo(1, day: 28),
                   src: accounts.zichtrekening, goal: goals.vakantie),

            saving(500.00, "Storting noodfonds", monthsAgo(1, day: 28),
                   src: accounts.zichtrekening, goal: goals.noodfonds),

            transfer(150.00, "Zakgeld cash", monthsAgo(1, day: 10),
                     src: accounts.zichtrekening, dest: accounts.cash),
        ])

        // --- 2 MONTHS AGO ---

        txns.append(contentsOf: [
            income(2_850.00, "Nettoloon maart", monthsAgo(2, day: 25),
                   dest: accounts.zichtrekening, cat: categories.werk),

            income(450.00, "Freelance opdracht", monthsAgo(2, day: 15),
                   dest: accounts.zichtrekening, cat: categories.werk),

            expense(795.00, "Huur maart", monthsAgo(2, day: 1),
                    src: accounts.zichtrekening, cat: categories.huur),

            expense(97.80, "Colruyt", monthsAgo(2, day: 6),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(48.20, "Albert Heijn", monthsAgo(2, day: 21),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(32.50, "MIVB maandkaart", monthsAgo(2, day: 1),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(15.99, "Netflix", monthsAgo(2, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(11.99, "Spotify", monthsAgo(2, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(29.95, "Gym abonnement", monthsAgo(2, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(120.00, "Cursus Python – Udemy", monthsAgo(2, day: 3),
                    src: accounts.zichtrekening, cat: categories.onderwijs),

            expense(67.50, "Resto Sushi Garden", monthsAgo(2, day: 9),
                    src: accounts.cash, cat: categories.restaurant),

            expense(44.00, "Weekend Gent", monthsAgo(2, day: 16),
                    src: accounts.cash, cat: categories.vrijeTijd),

            saving(600.00, "Storting auto spaarpot", monthsAgo(2, day: 27),
                   src: accounts.zichtrekening, goal: goals.auto),

            transfer(200.00, "Zakgeld cash", monthsAgo(2, day: 8),
                     src: accounts.zichtrekening, dest: accounts.cash),
        ])

        // --- 3 MONTHS AGO ---

        txns.append(contentsOf: [
            income(2_850.00, "Nettoloon februari", monthsAgo(3, day: 25),
                   dest: accounts.zichtrekening, cat: categories.werk),

            expense(795.00, "Huur februari", monthsAgo(3, day: 1),
                    src: accounts.zichtrekening, cat: categories.huur),

            expense(103.50, "Carrefour", monthsAgo(3, day: 4),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(55.00, "Lidl", monthsAgo(3, day: 19),
                    src: accounts.zichtrekening, cat: categories.boodschappen),

            expense(32.50, "MIVB maandkaart", monthsAgo(3, day: 1),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(38.00, "Tankbeurt", monthsAgo(3, day: 12),
                    src: accounts.zichtrekening, cat: categories.transport),

            expense(15.99, "Netflix", monthsAgo(3, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(11.99, "Spotify", monthsAgo(3, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(29.95, "Gym abonnement", monthsAgo(3, day: 8),
                    src: accounts.zichtrekening, cat: categories.abonnementen),

            expense(148.00, "Valentijn diner + bloemen", monthsAgo(3, day: 14),
                    src: accounts.cash, cat: categories.restaurant),

            expense(79.00, "Nike schoenen", monthsAgo(3, day: 20),
                    src: accounts.zichtrekening, cat: categories.kleding),

            saving(300.00, "Spaarpot vakantie feb", monthsAgo(3, day: 26),
                   src: accounts.zichtrekening, goal: goals.vakantie),

            saving(600.00, "Storting auto spaarpot", monthsAgo(3, day: 26),
                   src: accounts.zichtrekening, goal: goals.auto),

            saving(500.00, "Storting noodfonds", monthsAgo(3, day: 26),
                   src: accounts.zichtrekening, goal: goals.noodfonds),

            transfer(150.00, "Zakgeld cash", monthsAgo(3, day: 7),
                     src: accounts.zichtrekening, dest: accounts.cash),
        ])

        txns.forEach { context.insert($0) }
    }

    // MARK: - Helpers

    private static func income(_ amount: Decimal, _ desc: String, _ date: Date,
                                dest: Account, cat: Category) -> Transaction {
        let t = Transaction(type: .income, amount: amount, date: date)
        t.descriptionText    = desc
        t.destinationAccount = dest
        t.category           = cat
        return t
    }

    private static func expense(_ amount: Decimal, _ desc: String, _ date: Date,
                                 src: Account, cat: Category) -> Transaction {
        let t = Transaction(type: .expense, amount: amount, date: date)
        t.descriptionText = desc
        t.sourceAccount   = src
        t.category        = cat
        return t
    }

    private static func saving(_ amount: Decimal, _ desc: String, _ date: Date,
                                src: Account, goal: SavingGoal) -> Transaction {
        let t = Transaction(type: .savingDeposit, amount: amount, date: date)
        t.descriptionText = desc
        t.sourceAccount   = src
        t.savingGoal      = goal
        return t
    }

    private static func transfer(_ amount: Decimal, _ desc: String, _ date: Date,
                                  src: Account, dest: Account) -> Transaction {
        let t = Transaction(type: .transfer, amount: amount, date: date)
        t.descriptionText    = desc
        t.sourceAccount      = src
        t.destinationAccount = dest
        return t
    }
}
