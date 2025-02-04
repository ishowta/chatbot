import Foundation
import SwiftyBeaver

fileprivate func setupLogger() -> SwiftyBeaver.Type {
        let logger = SwiftyBeaver.self
        let console = ConsoleDestination()
        logger.addDestination(console)
        return SwiftyBeaver.self
}
let logger = setupLogger()

extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}

/// インターフェースに関するコンフィグの定義
public struct Config: Codable {
    init() {
        let rawConfig = (NSDictionary(contentsOfFile: "./config.plist") ?? NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)) as! [String: [String: Any]]
        let config = try! JSONDecoder().decode(Config.self, from: JSONSerialization.data(withJSONObject: rawConfig["interfaces"]!))
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

public let config = Config()

/// チャットボットと会話するためのインターフェースのプロトコル
protocol Interface {
    static func run()
}
