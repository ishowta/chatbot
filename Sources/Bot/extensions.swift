import Foundation
import Logging
import SQLite

let logger = Logger(label: "jp.ac.tsukuba.cs.mibel.chatbot.main")

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
