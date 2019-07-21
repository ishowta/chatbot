import Foundation
import SQLite

/// ユーザーの予定を管理するモデル
///
/// 予定管理モジュールで使う
struct Plan: Model, Codable {
    /// 予定ID
    let id: Int?
    /// 予定のタイトル
    let title: String
    /// 予定が行われる日付
    let date: Date
    /// 予定を登録したユーザーのID
    let userId: Int

    /// 予定ID
    static let id = Expression<Int>("id")
    /// 予定のタイトル
    static let title = Expression<String>("title")
    /// 予定が行われる日付
    static let date = Expression<Date>("date")
    /// 予定を登録したユーザーのID
    static let userId = Expression<Int>("userId")

    static func create(db: Connection, table: Table) {
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(Plan.id, primaryKey: true)
            t.column(Plan.title)
            t.column(Plan.date, defaultValue: Date())
            t.column(Plan.userId, references: Table("Users"), User.id)
        })
    }
}
