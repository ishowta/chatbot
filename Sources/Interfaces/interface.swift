import Foundation
import Logging

let logger = Logger(label: "jp.ac.tsukuba.cs.mibel.chatbot.interface")

extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}

public struct Config: Codable {
    init?(dict: [String: Any]) {
        guard let config = try? JSONDecoder().decode(Config.self, from: JSONSerialization.data(withJSONObject: dict)) else { return nil }
        self = config
    }

    struct ViberConfig: Codable {
        let url: String
        let port: UInt16
        let name: String
        let token: String
    }

    let interface: String
    let viber: ViberConfig
}

let config: Config = Config(dict: (
    NSDictionary(contentsOfFile: "./config.plist") ??
        NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)
) as! [String: Any])!

protocol Interface {
    static func run()
}
