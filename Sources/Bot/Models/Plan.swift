import Foundation
import SQLite

struct Plan: Model, Codable {
    let id: Int?
    let title: String
    let date: Date
    let userId: Int
    static let id = Expression<Int>("id")
    static let title = Expression<String>("title")
    static let date = Expression<Date>("date")
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
