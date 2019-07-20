import Foundation
import SQLite
import XCGLogger

let logger = XCGLogger(identifier: "jp.ac.tsukuba.cs.mibel.chatbot.bot", includeDefaultDestinations: true)

extension AnySequence where Element == Row {
    internal func decode<T: Codable>() -> [T] {
        return self.map { row in
            try! row.decode()
        }
    }
}

func dump<T>(_ value: T) -> String {
    var tmp = ""
    dump(value, to: &tmp)
    return tmp
}
