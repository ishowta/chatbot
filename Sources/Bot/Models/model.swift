import Foundation
import SQLite

protocol Model {
    var id: Int? { get }
    static func create(db: Connection, table: Table)
}

extension Expression where Datatype == Date {
    func strftime(format: String) -> Expression<String> {
        return Expression<String>("strftime('\(format)', \(template))")
    }

    var y: Expression<String> {
        return Expression<String>("strftime('%y', \(template))")
    }

    var m: Expression<String> {
        return Expression<String>("strftime('%m', \(template))")
    }

    var d: Expression<String> {
        return Expression<String>("strftime('%d', \(template))")
    }

    var h: Expression<String> {
        return Expression<String>("strftime('%h', \(template))")
    }

    var M: Expression<String> {
        return Expression<String>("strftime('%M', \(template))")
    }

    var s: Expression<String> {
        return Expression<String>("strftime('%s', \(template))")
    }
}
