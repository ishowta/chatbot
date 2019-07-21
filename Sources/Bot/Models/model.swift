import Foundation
import SQLite

/// DBモデルのプロトコル
protocol Model {
    var id: Int? { get }
    static func create(db: Connection, table: Table)
}

extension Expression where Datatype == Date {
    func strftime(format: String) -> Expression<String> {
        return Expression<String>("strftime('\(format)', \(template))")
    }

    /// Get year
    var y: Expression<String> {
        return Expression<String>("strftime('%y', \(template))")
    }

    /// Get month
    var m: Expression<String> {
        return Expression<String>("strftime('%m', \(template))")
    }

    /// Get day
    var d: Expression<String> {
        return Expression<String>("strftime('%d', \(template))")
    }

    /// Get hour
    var h: Expression<String> {
        return Expression<String>("strftime('%h', \(template))")
    }

    /// Get minute
    var M: Expression<String> {
        return Expression<String>("strftime('%M', \(template))")
    }

    /// Get second
    var s: Expression<String> {
        return Expression<String>("strftime('%s', \(template))")
    }
}
