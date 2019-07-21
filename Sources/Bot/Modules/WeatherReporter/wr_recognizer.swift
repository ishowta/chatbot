import PythonKit

extension WeatherReporter {
    class Recognizer: CaseAnylysis {
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
            guard let message = knpParse(rawMessage) else {
                logger.info("メッセージ \"\(rawMessage)\" の構文・意味解析に失敗しました")
                return nil
            }
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
