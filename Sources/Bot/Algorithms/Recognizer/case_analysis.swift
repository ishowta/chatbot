import Fortify
import Foundation
import PythonKit

extension String {
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ... end])
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }

    subscript(index: Int) -> Character {
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// 基本句を文字列に変換
    ///
    /// - Parameter tag: タグ
    /// - Returns: 文字列
    init(tag: PythonObject) {
        self = tag.mrph_list().map { String($0.midasi) ?? "" }.joined()
    }

    /// 基本句のリストをつなげて文字列に変換
    ///
    /// - Parameter tag: タグ
    /// - Returns: 文字列
    init(tags: [PythonObject]) {
        self = tags.map { String(tag: $0) }.joined()
    }
}

class CaseAnylysis {
    /// 述語のリストを得る
    ///
    /// - Parameter text: パースされたテキスト
    /// - Returns: 述語のリスト
    func getPredicateList(text: PythonObject) -> [PythonObject] {
        return text.tag_list().filter { $0.pas != Python.None }
    }

    /// 根が述語であれば返す
    ///
    /// - Parameter text: パースされたテキスト
    /// - Returns: 根の述語
    func getParentPredicate(text: PythonObject) -> PythonObject? {
        for tag in text.tag_list() {
            if tag.pas != Python.None, tag.parent_id == -1 {
                return tag
            }
        }
        return nil
    }

    /// 述語をマッチさせる
    ///
    /// - Parameters:
    ///   - pred: 述語のタグ
    ///   - predList: 述語の候補
    /// - Returns: マッチする述語が存在するか
    func match(_ pred: PythonObject, _ predList: [String]) -> Bool {
        guard let normalizedPred = String(pred.features.get("正規化代表表記", Python.None)) else { return false }
        return normalizedPred.components(separatedBy: "/").filter { predList.contains($0) }.count > 0
    }

    /// 基準となるタグの下にあるタグを集める
    ///
    /// - Parameter rootTag: 基準となるタグ
    /// - Returns: 下にあるタグのリスト（id順）
    func gatherTag(_ targetTag: PythonObject) -> [PythonObject] {
        var tags = [targetTag]
        if targetTag.children.count != 0 {
            tags += targetTag.children.flatMap { gatherTag($0) }
        }
        return tags.sorted(by: { $0.tag_id < $1.tag_id })
    }

    /// 基準となるタグの集合の下にあるタグをすべて集める
    ///
    /// - Parameter rootTags: 基準となるタグの集合
    /// - Returns: 下にあるタグのリスト（id順）
    func gatherTag(_ targetTags: [PythonObject]) -> [PythonObject] {
        let tags = targetTags.flatMap { gatherTag($0) }
        return tags.sorted(by: { $0.tag_id < $1.tag_id })
    }

    /// 基準となるタグの集合の子どもをつなげて文字列にする
    ///
    /// - Parameters:
    ///   - rootTags: 基準となるタグの集合
    ///   - exclude_current_tags: 基準となるタグを含めるか
    /// - Returns: 生成された文字列
    func joinChildlen(_ rootTags: [PythonObject], excludeCurrentTags: Bool = false) -> String {
        let tagList = gatherTag(excludeCurrentTags ? rootTags.flatMap { $0.children } : rootTags)
        return String(tags: tagList)
    }

    /// 文字列の最後に助詞や句読点などの余分なものが含まれていれば削除する
    ///
    /// - Parameter text: 文字列
    /// - Returns: 余分なものが削除された文字列
    func removeLastPostPosition(_ text: String) -> String {
        let postPositions = ["助詞", "助動詞", "判定詞", "特殊"]
        var text = text
        while true {
            let mrphList = juman.analysis(text).mrph_list()
            if mrphList.count >= 1, postPositions.contains(String(mrphList[mrphList.count - 1].hinsi)!) {
                text = mrphList[0 ..< mrphList.count - 1].map { String($0.midasi)! }.joined(separator: "")
            } else {
                break
            }
        }
        return text
    }

    /// 文字列の前後にある括弧を削除する
    ///
    /// - Parameter text: 文字列
    /// - Returns: 括弧が削除された文字列
    func removeBrackets(_ text: String) -> String {
        let BRACKETS_PAIR_LIST: [[Character]] = [
            ["「", "」"],
            ["`", "`"],
            ["\"", "\""],
            ["'", "'"],
            ["【", "】"]
        ]
        if text.count >= 2, (BRACKETS_PAIR_LIST.filter { text[0] == $0[0] && text[-1] == $0[1] }.count > 0) {
            return text[0 ..< -1]
        } else {
            return text
        }
    }

    let PyKNP = Python.import("pyknp")
    let knp: PythonObject
    let juman: PythonObject

    init() {
        Python.import("os").environ["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" // envが無い
        self.knp = PyKNP.KNP(option: "-tab")
        self.juman = PyKNP.Juman()
    }

    // `a a`などの入力でFatal errorで落ちるのを防いでいるが、XCodeだと落ちる
    func knpParse(_ text: String) -> PythonObject? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: PythonObject?
        do {
            _ = try Fortify.exec {
                result = knp.parse(text)
                semaphore.signal()
            }
        } catch {
            logger.info("KNP parse error: \(error)")
            return nil
        }
        semaphore.wait()
        return result
    }

    func drawParsedText(_ text: PythonObject) -> String {
        var res = ""
        print("基本句", to: &res)
        for tag in text.tag_list() {
            print("\tID:\(tag.tag_id), 見出し:\(tag.mrph_list().map { String($0.midasi) ?? "" }.joined()), 係り受けタイプ:\(tag.dpndtype), 親基本句ID:\(tag.parent_id), 素性:\(tag.fstring)", to: &res)
        }

        print("述語項構造", to: &res)
        for tag in text.tag_list() where tag.pas != Python.None {
            print(tag.features.get("格解析結果"), to: &res)
            print("述語: \(tag.mrph_list().map { String($0.midasi) ?? "" }.joined())", to: &res)
            let mrphs = tag.pas.arguments.items()
            for mrph in mrphs {
                let mcase = mrph[0]
                let args = mrph[1]
                for arg in args {
                    print("\t格: \(mcase),  項: \(arg.midasi)  (項の基本句ID: \(arg.tid)", to: &res)
                }
            }
        }
        return res
    }

    /// 述語から時間を示すタグを返す
    ///
    /// - Parameters:
    ///   - message: パースされたテキスト
    ///   - predTag: 述語
    /// - Returns: 時間を示すタグ
    func getPredWhenTags(_ message: PythonObject, _ predTag: PythonObject) -> [PythonObject]? {
        let allTags = message.tag_list()
        guard predTag.pas.arguments.contains("時間") else {
            return nil
        }
        let predWhenArgs = predTag.pas.arguments["時間"]
        let predWhenTags = predWhenArgs.map { allTags[$0.tid] }
        return predWhenTags
    }

    /// 時間を示すタグから日時を取り出す
    ///
    /// - Parameter whenTags: 時間を示すタグの集合
    /// - Returns: 日時
    func extractDate(_ whenTags: [PythonObject]) -> String? {
        let allWhenTags = gatherTag(whenTags)
        for tag in allWhenTags {
            if tag.features.contains("NE"), String(tag.features["NE"])!.components(separatedBy: ":")[0] == "DATE" {
                return String(tag.features["NE"])!.components(separatedBy: ":")[1]
            }
        }
        return nil
    }

    /// 時間を示すタグから時刻を取り出す
    ///
    /// - Parameter whenTags: 時間を示すタグの集合
    /// - Returns: 時刻
    func extractTime(_ whenTags: [PythonObject]) -> String? {
        let allWhenTags = gatherTag(whenTags)
        var minute = ""
        var hour = ""
        for tag in allWhenTags {
            if tag.features.contains("カウンタ"), tag.features["カウンタ"] == "分" {
                minute = String(tag.features["正規化代表表記"])!.components(separatedBy: "/")[0] + "分"
            }
            if tag.features.contains("カウンタ"), tag.features["カウンタ"] == "時" {
                hour = String(tag.features["正規化代表表記"])!.components(separatedBy: "/")[0] + "時"
            }
        }
        let time = hour + minute
        return time == "" ? nil : time
    }
}
