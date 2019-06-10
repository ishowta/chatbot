import Foundation
import SQLite

struct User: Model, Codable {
    let id: Int?
    let rawId: String
    let createAt: Date
    static let id = Expression<Int>("id")
    static let rawId = Expression<String>("rawId")
    static let createAt = Expression<Date>("createAt")
    static func create(db: Connection, table: Table) {
        try! db.run(table.create(ifNotExists: true) { t in
            t.column(User.id, primaryKey: true)
            t.column(User.rawId, unique: true)
            t.column(User.createAt, defaultValue: Date())
        })
    }
}
