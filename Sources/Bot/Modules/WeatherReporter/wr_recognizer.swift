import PythonKit

extension WeatherReporter {
    class Recognizer: CaseAnylysis {
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

        /// 天気について話しているか判断する
        ///
        /// - Parameter predTag: 述語
        /// - Returns: プランについて話しているか
        func isIndicatePlan(_ predTag: PythonObject) -> Bool {
            return predTag.pas.arguments.contains("ヲ") &&
                ["天気"].contains(String(predTag.pas.arguments["ヲ"][0].midasi))
        }

        func run(_ rawMessage: String) -> WeatherReporter.DialogueAct? {
            logger.debug("Raw message: \(rawMessage)")
            let message = knp.parse(rawMessage)
            logger.debug("Parsed message: \n\(drawParsedText(message))")
            guard let parentPredTag = getParentPredicate(text: message) else { return nil }
            let tag = parentPredTag
            if match(parentPredTag, ["表示", "教える"]) {
                // TODO: ヲ格が一つしかないことを前提としている。確認
                if isIndicatePlan(tag) {
                    /* 特定の条件を満たす予定の情報の要求
                     例：３月３日の天気を表示
                     */
                    let planTag = message.tag_list()[tag.pas.arguments["ヲ"][0].tid]
                    return .RequireWeatherAct(
                        date: removeLastPostPosition(joinChildlen([planTag], excludeCurrentTags: true))
                    )
                }
            }

            logger.info("メッセージ \"\(rawMessage)\" が認識されませんでした")
            return nil
        }
    }
}
