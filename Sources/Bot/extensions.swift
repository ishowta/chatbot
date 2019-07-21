import Foundation
import SQLite
import XCGLogger

let logger = XCGLogger(identifier: "jp.ac.tsukuba.cs.mibel.chatbot.bot", includeDefaultDestinations: true)

public struct Config: Codable {
    init() {
        let rawConfig = (NSDictionary(contentsOfFile: "./config.plist") ?? NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)) as! [String: [String: Any]]
        let config = try! JSONDecoder().decode(Config.self, from: JSONSerialization.data(withJSONObject: rawConfig["bot"]!))
        self = config
    }

    public enum DomainStrategy: String, Codable {
        case OneDomain
        case Simple
        case Stack
    }

    public let domainStrategy: DomainStrategy
    public let domain: String
}

public let config = Config()

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
