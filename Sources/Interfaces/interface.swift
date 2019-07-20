import Foundation
import XCGLogger

let logger = XCGLogger(identifier: "jp.ac.tsukuba.cs.mibel.chatbot.interface", includeDefaultDestinations: true)

extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}

public struct InterfaceConfig: Codable {
    init() {
        let rawConfig = (NSDictionary(contentsOfFile: "./config.plist") ?? NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)) as! [String: Any]
        let config = try! JSONDecoder().decode(InterfaceConfig.self, from: JSONSerialization.data(withJSONObject: rawConfig))
        self = config
    }

    public enum InterfaceType: String, Codable {
        case Shell = "shell"
        case ViberBot = "viberbot"
    }

    public struct ViberConfig: Codable {
        public let url: String
        public let port: UInt16
        public let name: String
        public let token: String
    }

    public let interface: InterfaceType
    public let viber: ViberConfig
}

public let config = InterfaceConfig()

protocol Interface {
    static func run()
}
