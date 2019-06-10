import Foundation
import Logging

let logger = Logger(label: "jp.ac.tsukuba.cs.mibel.chatbot.interface")

let CONFIG = (NSDictionary(contentsOfFile: "./config.plist") ?? NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)) as! [String: Any]

protocol Interface {
    static func run()
}
