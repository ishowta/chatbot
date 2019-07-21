import Foundation
import Regex
import SQLite

extension PlanManager {
    class Actor {
        let db: Connection
        let userId: Int

        init(db: Connection, userId: Int) {
            self.db = db
            self.userId = userId
        }

        /// 日付をパースする
        func parseDate(_ rawDate: String) -> DateComponents? {
            let dateFormater = DateFormatter()
            let calendar = Calendar.current
            dateFormater.locale = Locale(identifier: "ja_JP")
            dateFormater.dateFormat = "MM月dd日"
            guard let date = dateFormater.date(from: rawDate) else {
                return nil
            }
            return DateComponents(
                month: calendar.component(.month, from: date),
                day: calendar.component(.day, from: date)
            )
        }

        /// 時刻をパースする
        func parseTime(_ rawTime: String) -> DateComponents? {
            let dateFormater = DateFormatter()
            let calendar = Calendar.current
            dateFormater.locale = Locale(identifier: "ja_JP")
            dateFormater.dateFormat = "HH時mm分"
            guard let date = dateFormater.date(from: rawTime) else {
                return nil
            }
            return DateComponents(
                hour: calendar.component(.hour, from: date),
                minute: calendar.component(.minute, from: date)
            )
        }

        /// 日付に関する条件（明日、3日前など）をパースする
        func parseCondition(_ cond: String) -> Condition? {
            let today = Date()
            switch cond {
            case Regex("([0-9０-９]+月[0-9０-９]+日)([0-9０-９]+時[0-9０-９]+分)"):
                // Datetime
                let cond = parseDateTime(Regex.lastMatch!.captures[0]!, Regex.lastMatch!.captures[1]!)!.date! // Too bad code
                return Condition(
                    match: { compDatetime($0, cond) },
                    convert: { replaceDatetime($0, cond) }
                )
            case Regex("((?:[0-9０-９]+月){0,1}(?:[0-9０-９]+日) | (?:[0-9０-９]+月)(?:[0-9０-９]+日){0,1})"):
                // Date
                let cond = parseDate(Regex.lastMatch!.captures[0]!)!.date!
                return Condition(
                    match: { compDate($0, cond) },
                    convert: { replaceDate($0, cond) }
                )
            case Regex("((?:[0-9０-９]+時){0,1}(?:[0-9０-９]+分) | (?:[0-9０-９]+時)(?:[0-9０-９]+分){0,1})"):
                // Time
                let cond = parseTime(Regex.lastMatch!.captures[0]!)!.date!
                return Condition(
                    match: { compTime($0, cond) },
                    convert: { replaceTime($0, cond) }
                )
            case Regex("今日"):
                return Condition(
                    match: { compDatetime($0, today) },
                    convert: { replaceDatetime($0, today) }
                )
            case Regex("明日"):
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
                return Condition(
                    match: { compDatetime($0, tomorrow) },
                    convert: { replaceDatetime($0, tomorrow) }
                )
            case Regex("([0-9０-９]+)日前"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .day, value: -n, to: today)!) },
                    convert: { calendar.date(byAdding: .day, value: -n, to: $0) }
                )
            case Regex("([0-9０-９]+)日後"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .day, value: +n, to: today)!) },
                    convert: { calendar.date(byAdding: .day, value: +n, to: $0) }
                )
            case Regex("([0-9０-９]+)週間前"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .weekday, value: -n, to: today)!) },
                    convert: { calendar.date(byAdding: .weekday, value: -n, to: $0) }
                )
            case Regex("([0-9０-９]+)週間後"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .weekday, value: +n, to: today)!) },
                    convert: { calendar.date(byAdding: .weekday, value: +n, to: $0) }
                )
            case Regex("([0-9０-９]+)ヶ月前"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .month, value: -n, to: today)!) },
                    convert: { calendar.date(byAdding: .month, value: -n, to: $0) }
                )
            case Regex("([0-9０-９]+)ヶ月後"):
                let n = Int(Regex.lastMatch!.matchedString)!
                return Condition(
                    match: { compDate($0, calendar.date(byAdding: .month, value: +n, to: today)!) },
                    convert: { calendar.date(byAdding: .month, value: +n, to: $0) }
                )
            default:
                return nil
            }
        }

        /// 日付と時刻をくっつける
        func generateDateTime(_ date: DateComponents, _ time: DateComponents) -> DateComponents {
            return DateComponents(
                calendar: calendar,
                timeZone: TimeZone.current,
                year: Date().toComponents().year,
                month: date.month,
                day: date.day,
                hour: time.hour,
                minute: time.minute
            )
        }

        /// 日時をパースする
        func parseDateTime(_ raw_date: String, _ raw_time: String) -> DateComponents? {
            guard
                let date = parseDate(raw_date),
                let time = parseDate(raw_time)
            else {
                return nil
            }
            return generateDateTime(date, time)
        }

        /// 同じ日時にプランが存在しないかチェック
        func checkDuplicate(date: Date) -> [Plan]? {
            let duplicatedPlans: [Plan]? = try? db.prepare(Table("Plans").filter(Plan.date == date)).decode()
            if duplicatedPlans?.count != 0 {
                return duplicatedPlans
            }
            return nil
        }

        /// 同じ日時条件にプランが存在しないかチェック
        func checkDuplicate(condition cond: Condition) -> [Plan]? {
            let duplicatedPlans: [Plan]? = try? db.prepare(Table("Plans").filter(cond.match(Plan.date))).decode()
            return duplicatedPlans
        }

        func run(_ domainPlan: DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)? {
            let userPlans = Table("Plans").filter(Plan.userId == userId)
            switch domainPlan {
            case let plan as RegistrationPlan:
                switch dialogueAct {
                case .RequireRegistrationAct(let reqTitle, let reqDate, let reqTime),
                     .TellAct(let reqTitle, let reqDate, let reqTime):
                    if reqTitle != nil {
                        plan.title = reqTitle
                    }
                    if reqDate != nil {
                        let parsedDate = parseDate(reqDate!)
                        if parsedDate != nil {
                            plan.date = parsedDate
                        } else {
                            return (.Basic(.MessageAct(message: "何日？")), false)
                        }
                    }
                    if reqTime != nil {
                        let parsedTime = parseTime(reqTime!)
                        if parsedTime != nil {
                            plan.time = parsedTime
                        } else {
                            return (.Basic(.MessageAct(message: "何時？")), false)
                        }
                    }
                case .RequireUpdateAct:
                    return nil
                case .RequireDeleteAct:
                    return nil
                case .RequireShowAct:
                    return nil
                }
                guard let planTitle = plan.title, let planDate = plan.date, let planTime = plan.time else {
                    // 足りない情報を要求する
                    var reqDataList: [String] = []
                    if plan.title == nil { reqDataList.append("タイトル") }
                    if plan.date == nil { reqDataList.append("日付") }
                    if plan.time == nil { reqDataList.append("時刻") }
                    return (
                        .Domain(
                            .RequestDataAct(
                                dataNameList: reqDataList
                            )
                        ),
                        false
                    )
                }
                let planDatetime = generateDateTime(planDate, planTime)
                if let duplicatedPlan = checkDuplicate(date: planDatetime.date!) {
                    // 他のプランと重複していることを伝える
                    return (
                        .Domain(
                            .TellDuplicatedAct(
                                duplicatedPlan: duplicatedPlan
                            )
                        ),
                        false
                    )
                }
                // 予定を登録する
                let newPlan = Plan(id: nil, title: planTitle, date: planDatetime.date!, userId: userId)
                try! db.run(Table("Plans").insert(newPlan))
                plan.registratedPlan = newPlan
                return (
                    .Domain(
                        .TellAct(
                            domainPlan: domainPlan,
                            state: .Complete,
                            message: nil
                        )
                    ),
                    true
                )
            case let plan as UpdatePlan:
                switch dialogueAct {
                case .RequireRegistrationAct,
                     .TellAct:
                    return nil
                case .RequireUpdateAct(let reqTo, let reqTitle, let reqCondition):
                    guard let parsedTo = parseCondition(reqTo) else {
                        return (.Basic(.MessageAct(message: "移動先を詳しく教えてください")), false)
                    }
                    plan.to = parsedTo
                    if reqTitle != nil { plan.title = reqTitle }
                    if let reqCondition = reqCondition {
                        guard let parsedCondition = parseCondition(reqCondition) else {
                            return (.Basic(.MessageAct(message: "プランの条件を詳しく教えてください")), false)
                        }
                        plan.condition = parsedCondition
                    }
                case .RequireDeleteAct:
                    return nil
                case .RequireShowAct:
                    return nil
                }
                if plan.title != nil {
                    // 指定されたタイトルのプランを移動する
                    try! db.run(Table("Plans")
                        .filter(Plan.title == plan.title!)
                        .update(Plan.date <- plan.to!.convert(Plan.date))
                    )
                    plan.updatedPlans = try! db.prepare(userPlans.filter(Plan.title == plan.title!)).decode()
                    return (
                        .Domain(
                            .TellAct(
                                domainPlan: plan,
                                state: .Complete,
                                message: nil
                            )
                        ),
                        true
                    )

                } else if plan.condition != nil {
                    // 条件に当てはまるプランを移動する
                    let willUpdatePlans: [Plan] = try! db.prepare(userPlans.filter(plan.condition!.match(Plan.date))).decode()
                    try! db.run(Table("Plans")
                        .filter(plan.condition!.match(Plan.date))
                        .update(Plan.date <- plan.to!.convert(Plan.date))
                    )
                    plan.updatedPlans = try! db.prepare(userPlans.filter(
                        willUpdatePlans.map { $0.id! }.contains(Plan.id)
                    )).decode()
                    return (
                        .Domain(
                            .TellAct(
                                domainPlan: plan,
                                state: .Complete,
                                message: nil
                            )
                        ),
                        true
                    )
                } else {
                    // 足りない情報を要求する
                    return (.Domain(.RequestDataAct(dataNameList: ["移動対象"])), false)
                }
            case let plan as DeletePlan:
                switch dialogueAct {
                case .RequireRegistrationAct,
                     .TellAct,
                     .RequireShowAct,
                     .RequireUpdateAct:
                    return nil
                case .RequireDeleteAct(let title, let condition):
                    if title != nil {
                        // 指定されたタイトルのプランを削除する
                        plan.deletedPlans = try! db.prepare(userPlans.filter(Plan.title == title!)).decode()
                        try! db.run(userPlans.filter(Plan.title == title!).delete())
                    } else if condition != nil {
                        guard let parsedCondition = parseCondition(condition!) else {
                            return (.Basic(.MessageAct(message: "プランの条件を詳しく教えてください")), false)
                        }
                        // 条件に当てはまるプランを削除する
                        plan.deletedPlans = try! db.prepare(userPlans.filter(parsedCondition.match(Plan.date))).decode()
                        try! db.run(userPlans.filter(parsedCondition.match(Plan.date)).delete())
                    } else {
                        // 足りない情報を要求する
                        return (.Domain(.RequestDataAct(dataNameList: ["削除対象"])), false)
                    }
                    return (.Domain(.TellAct(
                        domainPlan: plan,
                        state: .Complete,
                        message: nil
                    )), true)
                }
            case let plan as ShowPlan:
                switch dialogueAct {
                case .RequireRegistrationAct,
                     .TellAct,
                     .RequireDeleteAct,
                     .RequireUpdateAct:
                    return nil
                case .RequireShowAct(let title, let condition):
                    if title != nil {
                        // 指定されたタイトルのプランを表示する
                        plan.plans = try! db.prepare(userPlans.filter(Plan.title == title!)).decode()
                    } else if condition != nil {
                        guard let parsedCondition = parseCondition(condition!) else {
                            return (.Basic(.MessageAct(message: "プランの条件を詳しく教えてください")), false)
                        }
                        // 条件に当てはまるプランを表示する
                        plan.plans = try! db.prepare(userPlans.filter(parsedCondition.match(Plan.date))).decode()
                    } else {
                        // すべてのプランを表示する
                        plan.plans = try! db.prepare(userPlans).decode()
                    }
                    return (.Domain(.TellAct(
                        domainPlan: plan,
                        state: .Complete,
                        message: nil
                    )), true)
                }
            default:
                fatalError()
            }
        }
    }
}
