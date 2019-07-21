import Foundation
import SQLite

/// ユーザーを管理するモデル
struct User: Model, Codable {
    /// ユーザーID
    let id: Int?
    /// 外部のユーザーID（ユニークでなければならない）
    let rawId: String
    /// 登録日
    let createAt: Date

    /// ユーザーID
    static let id = Expression<Int>("id")
    /// 外部のユーザーID（ユニークでなければならない）
    static let rawId = Expression<String>("rawId")
    /// 登録日
    static let createAt = Expression<Date>("createAt")

    static func create(db: Connection, table: Table) {
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(User.id, primaryKey: true)
            t.column(User.rawId, unique: true)
            t.column(User.createAt, defaultValue: Date())
        })
    }
}
