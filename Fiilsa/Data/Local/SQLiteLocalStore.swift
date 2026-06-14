import Foundation
import SQLite3

actor SQLiteLocalStore {
    private var database: OpaquePointer?
    private let path: String

    init(path: String = SQLiteLocalStore.defaultDatabasePath()) throws {
        self.path = path
        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        try open()
        try createTables()
    }

    deinit {
        sqlite3_close(database)
    }

    func getAllQuotes() throws -> [LocalQuoteInfo] {
        try queryQuotes("SELECT * FROM quoteInfo ORDER BY date DESC")
    }

    func findQuoteById(seq: Int) throws -> LocalQuoteInfo? {
        try queryQuotes("SELECT * FROM quoteInfo WHERE id = ? LIMIT 1", bindings: [.int(seq)]).first
    }

    func insertQuote(_ quote: LocalQuoteInfo) throws {
        try execute(
            """
            INSERT OR REPLACE INTO quoteInfo (
                id, korQuote, engQuote, korAuthor, engAuthor, korTyping, engTyping, likeYn, memo, date, dayOfWeek
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            bindings: quote.bindings
        )
    }

    func updateQuote(_ quote: LocalQuoteInfo) throws {
        try insertQuote(quote)
    }

    func updateMemo(_ memo: String, seq: Int) throws {
        try execute("UPDATE quoteInfo SET memo = ? WHERE id = ?", bindings: [.text(memo), .int(seq)])
    }

    func updateLike(_ likeYN: YN, seq: Int) throws -> Int {
        if likeYN == .no,
           let quote = try findQuoteById(seq: seq),
           quote.korTyping.isEmpty,
           quote.engTyping.isEmpty,
           quote.memo.isEmpty {
            try deleteQuoteById(seq)
            return 0
        }

        try execute("UPDATE quoteInfo SET likeYn = ? WHERE id = ?", bindings: [.text(likeYN.rawValue), .int(seq)])
        return Int(sqlite3_changes(database))
    }

    func deleteQuoteById(_ seq: Int) throws {
        try execute("DELETE FROM quoteInfo WHERE id = ?", bindings: [.int(seq)])
    }

    func clearQuotes() throws {
        try execute("DELETE FROM quoteInfo")
    }

    func setTodayStreakInfo(today: Date = Date()) throws {
        let yesterday = Self.dateString(daysFromToday: -1, relativeTo: today)
        let yesterdayInfo = try getStreakInfo(date: yesterday)
        let count = yesterdayInfo?.isDailyWritingCompleted == true ? yesterdayInfo!.streakDateCount + 1 : 1

        try insertStreakInfo(
            StreakInfo(
                date: Self.dateString(daysFromToday: 0, relativeTo: today),
                streakDateCount: count,
                isDailyWritingCompleted: true
            )
        )
    }

    func getYesterdayStreakInfo(today: Date = Date()) throws -> StreakInfo? {
        try getStreakInfo(date: Self.dateString(daysFromToday: -1, relativeTo: today))
    }

    func getAllStreakInfos() throws -> [StreakInfo] {
        try queryStreaks("SELECT * FROM streak_info ORDER BY date DESC")
    }

    func getStreakDateCount(today: Date = Date()) throws -> Int {
        if let todayInfo = try getStreakInfo(date: Self.dateString(daysFromToday: 0, relativeTo: today)) {
            return todayInfo.streakDateCount
        }
        return try getYesterdayStreakInfo(today: today)?.streakDateCount ?? 0
    }

    func checkYesterdayStreak(today: Date = Date()) throws {
        let yesterday = Self.dateString(daysFromToday: -1, relativeTo: today)
        guard let yesterdayInfo = try getStreakInfo(date: yesterday), !yesterdayInfo.isDailyWritingCompleted else {
            return
        }

        try insertStreakInfo(
            StreakInfo(
                date: Self.dateString(daysFromToday: 0, relativeTo: today),
                streakDateCount: 0,
                isDailyWritingCompleted: false
            )
        )
    }

    func getTodayLocalStreakInfo(today: Date = Date()) throws -> StreakInfo? {
        try getStreakInfo(date: Self.dateString(daysFromToday: 0, relativeTo: today))
    }

    private func getStreakInfo(date: String) throws -> StreakInfo? {
        try queryStreaks("SELECT * FROM streak_info WHERE date = ? LIMIT 1", bindings: [.text(date)]).first
    }

    private func insertStreakInfo(_ streakInfo: StreakInfo) throws {
        try execute(
            """
            INSERT OR REPLACE INTO streak_info (
                date, streak_date_count, is_daily_writing_completed
            ) VALUES (?, ?, ?)
            """,
            bindings: [
                .text(streakInfo.date),
                .int(streakInfo.streakDateCount),
                .bool(streakInfo.isDailyWritingCompleted)
            ]
        )
    }

    private func open() throws {
        guard sqlite3_open(path, &database) == SQLITE_OK else {
            throw SQLiteLocalStoreError.openFailed(message)
        }
    }

    private func createTables() throws {
        try execute(
            """
            CREATE TABLE IF NOT EXISTS quoteInfo (
                id INTEGER PRIMARY KEY NOT NULL,
                korQuote TEXT NOT NULL,
                engQuote TEXT NOT NULL,
                korAuthor TEXT NOT NULL,
                engAuthor TEXT NOT NULL,
                korTyping TEXT NOT NULL,
                engTyping TEXT NOT NULL,
                likeYn TEXT NOT NULL,
                memo TEXT NOT NULL,
                date TEXT NOT NULL,
                dayOfWeek TEXT NOT NULL
            )
            """
        )

        try execute(
            """
            CREATE TABLE IF NOT EXISTS streak_info (
                date TEXT PRIMARY KEY NOT NULL,
                streak_date_count INTEGER NOT NULL DEFAULT 0,
                is_daily_writing_completed INTEGER NOT NULL DEFAULT 0
            )
            """
        )
    }

    private func queryQuotes(_ sql: String, bindings: [SQLiteBinding] = []) throws -> [LocalQuoteInfo] {
        try query(sql, bindings: bindings) { statement in
            LocalQuoteInfo(
                dailyQuoteSeq: sqlite3_column_int_value(statement, 0),
                korQuote: sqlite3_column_text_value(statement, 1),
                engQuote: sqlite3_column_text_value(statement, 2),
                korAuthor: sqlite3_column_text_value(statement, 3),
                engAuthor: sqlite3_column_text_value(statement, 4),
                korTyping: sqlite3_column_text_value(statement, 5),
                engTyping: sqlite3_column_text_value(statement, 6),
                likeYn: sqlite3_column_text_value(statement, 7),
                memo: sqlite3_column_text_value(statement, 8),
                date: sqlite3_column_text_value(statement, 9),
                dayOfWeek: sqlite3_column_text_value(statement, 10)
            )
        }
    }

    private func queryStreaks(_ sql: String, bindings: [SQLiteBinding] = []) throws -> [StreakInfo] {
        try query(sql, bindings: bindings) { statement in
            StreakInfo(
                date: sqlite3_column_text_value(statement, 0),
                streakDateCount: sqlite3_column_int_value(statement, 1),
                isDailyWritingCompleted: sqlite3_column_int_value(statement, 2) == 1
            )
        }
    }

    private func query<Value>(
        _ sql: String,
        bindings: [SQLiteBinding] = [],
        map: (OpaquePointer) -> Value
    ) throws -> [Value] {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }

        var values: [Value] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            values.append(map(statement!))
        }
        return values
    }

    private func execute(_ sql: String, bindings: [SQLiteBinding] = []) throws {
        let statement = try prepare(sql, bindings: bindings)
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw SQLiteLocalStoreError.executeFailed(message)
        }
    }

    private func prepare(_ sql: String, bindings: [SQLiteBinding]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteLocalStoreError.prepareFailed(message)
        }

        for (index, binding) in bindings.enumerated() {
            try bind(binding, to: statement, at: Int32(index + 1))
        }
        return statement
    }

    private func bind(_ binding: SQLiteBinding, to statement: OpaquePointer?, at index: Int32) throws {
        let status: Int32
        switch binding {
        case let .int(value):
            status = sqlite3_bind_int(statement, index, Int32(value))
        case let .text(value):
            status = sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
        case let .bool(value):
            status = sqlite3_bind_int(statement, index, value ? 1 : 0)
        }

        guard status == SQLITE_OK else {
            throw SQLiteLocalStoreError.bindFailed(message)
        }
    }

    private var message: String {
        guard let database else { return "SQLite database is not open." }
        return String(cString: sqlite3_errmsg(database))
    }

    private static func defaultDatabasePath() -> String {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return url.appendingPathComponent("Fillsa.sqlite").path
    }

    private static func dateString(daysFromToday: Int, relativeTo date: Date) -> String {
        let calendar = Calendar.current
        let targetDate = calendar.date(byAdding: .day, value: daysFromToday, to: date) ?? date
        return DateFormatter.fillsaDate.string(from: targetDate)
    }
}

private extension LocalQuoteInfo {
    var bindings: [SQLiteBinding] {
        [
            .int(dailyQuoteSeq),
            .text(korQuote),
            .text(engQuote),
            .text(korAuthor),
            .text(engAuthor),
            .text(korTyping),
            .text(engTyping),
            .text(likeYn),
            .text(memo),
            .text(date),
            .text(dayOfWeek)
        ]
    }
}

private enum SQLiteBinding {
    case int(Int)
    case text(String)
    case bool(Bool)
}

enum SQLiteLocalStoreError: Error, Equatable {
    case openFailed(String)
    case prepareFailed(String)
    case bindFailed(String)
    case executeFailed(String)
}

private extension DateFormatter {
    static let fillsaDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

nonisolated private func sqlite3_column_int_value(_ statement: OpaquePointer?, _ index: Int32) -> Int {
    Int(sqlite3_column_int(statement, index))
}

nonisolated private func sqlite3_column_text_value(_ statement: OpaquePointer?, _ index: Int32) -> String {
    guard let cString = sqlite3_column_text(statement, index) else {
        return ""
    }
    return String(cString: cString)
}

nonisolated(unsafe) private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
