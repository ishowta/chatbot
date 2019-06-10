import PythonKit

extension PlanManager {
    class Recognizer: CaseAnylysis {
        /// 述語からそのタイトルを取り出す
        ///
        /// - Parameters:
        ///   - message: パースされたテキスト
        ///   - predTag: 述語
        /// - Returns: タイトル
        func extractTitle(_ message: PythonObject, _ predTag: PythonObject) -> String {
            let allTags = message.tag_list()
            let TITLE_TAG_NAME_LIST = ["ガ", "デ", "ヲ"]
            let predTitleArgs = TITLE_TAG_NAME_LIST.flatMap { predTag.pas.arguments[$0] }
            let predTitleTags = predTitleArgs.map { allTags[$0.tid] }
            let rawTitle = joinChildlen(predTitleTags)
            return removeLastPostPosition(removeBrackets(rawTitle))
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

        /// プランについて話しているか判断する
        ///
        /// - Parameter predTag: 述語
        /// - Returns: プランについて話しているか
        func isIndicatePlan(_ predTag: PythonObject) -> Bool {
            return predTag.pas.arguments.contains("ヲ") &&
                ["予定", "プラン", "用事"].contains(String(predTag.pas.arguments["ヲ"][0].midasi))
        }

        func run(_ rawMessage: String) -> PlanManager.DialogueAct? {
            logger.debug("Raw message: \(rawMessage)")
            let message = knp.parse(rawMessage)
            logger.debug("Parsed message: \n\(drawParsedText(message))")
            guard let parentPredTag = getParentPredicate(text: message) else { return nil }
            let tag = parentPredTag
            if match(parentPredTag, ["する", "登録"]) {
                /* 登録要求
                 例：ショッピングを一週間後で登録して
                 */
                if let whenTags = getPredWhenTags(message, tag) {
                    return .RequireRegistrationAct(
                        title: extractTitle(message, tag),
                        date: extractDate(whenTags),
                        time: extractTime(whenTags)
                    )
                } else {
                    return .RequireRegistrationAct(
                        title: extractTitle(message, tag),
                        date: nil,
                        time: nil
                    )
                }
            } else if tag.features.contains("時間"), tag.pas.arguments.contains("ガ") {
                /* ある予定の情報の要求
                 例：友達とショッピングに行くのはいつなの
                 */
                return .RequireShowAct(
                    title: extractTitle(message, tag),
                    condition: nil
                )
            } else if match(parentPredTag, ["表示", "教える"]) {
                // TODO: ヲ格が一つしかないことを前提としている。確認
                if isIndicatePlan(tag) {
                    /* 特定の条件を満たす予定の情報の要求
                     例：３月３日の予定を表示
                     */
                    let planTag = message.tag_list()[tag.pas.arguments["ヲ"][0].tid]
                    return .RequireShowAct(
                        title: nil,
                        condition: removeLastPostPosition(joinChildlen([planTag], excludeCurrentTags: true))
                    )
                } else if tag.pas.arguments.contains("時間") {
                    /* ある予定の情報の要求
                     例：友達とショッピングに行くのはいつなのか教えて
                     */
                    let whenTag = message.tag_list()[tag.pas.arguments["時間"][0].tid]
                    return .RequireShowAct(
                        title: extractTitle(message, whenTag),
                        condition: nil
                    )
                }
            } else if match(parentPredTag, ["削除", "消す", "無くす"]) {
                if isIndicatePlan(tag) {
                    /* 特定の条件を満たす予定の削除の要求
                     例：３月３日の予定を消してください
                     */
                    let planTag = message.tag_list()[tag.pas.arguments["ヲ"][0].tid]
                    return .RequireDeleteAct(
                        title: nil,
                        condition: removeLastPostPosition(joinChildlen([planTag], excludeCurrentTags: true))
                    )
                }
            } else if match(parentPredTag, ["移動", "移す", "変更", "変える"]) {
                if isIndicatePlan(tag) {
                    if tag.pas.arguments.contains("時間") {
                        /* 予定の日付変更要求
                         例：３月３日の予定を5月2日に移動
                         */
                        let condPlanTag = message.tag_list()[tag.pas.arguments["ヲ"][0].tid]
                        let toTag = message.tag_list()[tag.pas.arguments["時間"][0].tid]
                        return .RequireUpdateAct(
                            to: removeLastPostPosition(joinChildlen([toTag])),
                            title: nil,
                            condition: removeLastPostPosition(joinChildlen([condPlanTag], excludeCurrentTags: true))
                        )
                    }
                } else if tag.pas.arguments.contains("ヲ") {
                    if tag.pas.arguments.contains("時間") {
                        /* 予定の日付変更要求
                         例：散歩を5月2日に移動
                         */
                        let titleTag = message.tag_list()[tag.pas.arguments["ヲ"][0].tid]
                        let toTag = message.tag_list()[tag.pas.arguments["時間"][0].tid]
                        return .RequireUpdateAct(
                            to: removeLastPostPosition(joinChildlen([toTag])),
                            title: removeLastPostPosition(joinChildlen([titleTag])),
                            condition: nil
                        )
                    }
                }
            } else if (message.tag_list().filter { $0.features.contains("時間") }).count == message.tag_list().count {
                /* 時間の情報提供
                 例：３月３日の5時 / 五週間後
                 */
                if let whenTags = getPredWhenTags(message, tag) {
                    return .TellAct(
                        title: nil,
                        date: extractDate(whenTags),
                        time: extractTime(whenTags)
                    )
                }
            }

            logger.info("メッセージ \"\(rawMessage)\" が認識されませんでした")
            return nil
        }
    }
}
