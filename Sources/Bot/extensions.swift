import Foundation
import SQLite
import XCGLogger

let logger = XCGLogger(identifier: "jp.ac.tsukuba.cs.mibel.chatbot.bot", includeDefaultDestinations: true)

/// チャットボットに関するコンフィグの定義
public struct Config: Codable {
    init() {
        let rawConfig = (NSDictionary(contentsOfFile: "./config.plist") ?? NSDictionary(contentsOfFile: Bundle.main.path(forResource: "Interfaces.framework/Resources/config", ofType: "plist")!)) as! [String: [String: Any]]
        let config = try! JSONDecoder().decode(Config.self, from: JSONSerialization.data(withJSONObject: rawConfig["bot"]!))
        self = config
    }

    /// ドメイン選択器のリスト
    public enum DomainStrategy: String, Codable {
        case OneDomain
        case Simple
        case Stack
    }

    /// どのドメイン選択器を用いるか
    public let domainStrategy: DomainStrategy

    /// SimpleDomainSelectorを使う場合に使用するドメイン
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

// Too bad extension. Bad I think it is the best way.
extension String {
    subscript(index: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: index)]
    }
    
    subscript(bounds: CountableRange<Int>) -> Substring {
        return self[index(at: bounds.lowerBound)..<index(at: bounds.upperBound)]
    }
    
    subscript(bounds: CountableClosedRange<Int>) -> Substring {
        return self[index(at: bounds.lowerBound)...index(at: bounds.upperBound)]
    }
    
    subscript(bounds: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(at: bounds.upperBound)]
    }
    
    subscript(bounds: PartialRangeThrough<Int>) -> Substring {
        return self[...index(at: bounds.upperBound)]
    }
    
    subscript(bounds: PartialRangeFrom<Int>) -> Substring {
        return self[index(at: bounds.lowerBound)...]
    }
    
    subscript(bounds: CountableRange<Int>) -> String {
        return String(self[index(at: bounds.lowerBound)..<index(at: bounds.upperBound)])
    }
    
    subscript(bounds: CountableClosedRange<Int>) -> String {
        return String(self[index(at: bounds.lowerBound)...index(at: bounds.upperBound)])
    }
    
    subscript(bounds: PartialRangeUpTo<Int>) -> String {
        return String(self[..<index(at: bounds.upperBound)])
    }
    
    subscript(bounds: PartialRangeThrough<Int>) -> String {
        return String(self[...index(at: bounds.upperBound)])
    }
    
    subscript(bounds: PartialRangeFrom<Int>) -> String {
        return String(self[index(at: bounds.lowerBound)...])
    }
    
    func index(at offset: Int) -> String.Index {
        return index(startIndex, offsetBy: offset)
    }
}
