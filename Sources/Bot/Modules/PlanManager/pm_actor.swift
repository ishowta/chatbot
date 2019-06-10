import Foundation
import Regex
import SQLite

private let calendar = Calendar(identifier: .gregorian)

extension Date {
    fileprivate func toComponents() -> DateComponents {
        return Calendar(identifier: .gregorian).dateComponents(in: TimeZone.current, from: self)
    }
}

private protocol SQL {
    func toSQL() -> String
}

extension String: SQL {
    fileprivate func toSQL() -> String { return self }
}

extension Expression: SQL {
    fileprivate func toSQL() -> String { return template }
}

extension DateComponents {
    fileprivate var y: String { return "\(year!)" }
    fileprivate var m: String { return "\(month!)" }
    fileprivate var d: String { return "\(day!)" }
    fileprivate var h: String { return "\(hour!)" }
    fileprivate var M: String { return "\(minute!)" }
    fileprivate var s: String { return "\(second!)" }
}

extension Calendar {
    fileprivate func date(byAdding: Component, value: Int, to: Expression<Date>) -> Expression<Date> {
        switch byAdding {
        case .day:
            return Expression<Date>("datetime(\(to.template), '\(value) days')")
        case .year:
            return Expression<Date>("datetime(\(to.template), '\(value) years')")
        case .month:
            return Expression<Date>("datetime(\(to.template), '\(value) months')")
        case .hour:
            return Expression<Date>("datetime(\(to.template), '\(value) hours')")
        case .minute:
            return Expression<Date>("datetime(\(to.template), '\(value) minutes')")
        case .second:
            return Expression<Date>("datetime(\(to.template), '\(value) seconds')")
        case .weekday:
            return Expression<Date>("datetime(\(to.template), 'weekday \(value)')")
        default:
            fatalError()
        }
    }
}

/// 日時を示すSQLを生成する
///
/// - Parameters:
///   - y: 年
///   - m: 月
///   - d: 日
///   - h: 時
///   - M: 分
///   - s: 秒
/// - Returns: 日時
private func genDate(y: SQL, m: SQL, d: SQL, h: SQL, M: SQL, s: SQL) -> Expression<Date> {
    return Expression<Date>("datetime('0000-00-00 00:00:00', '\(y.toSQL()) years', '\(m.toSQL()) months', '\(d.toSQL()) days', '\(h.toSQL()) hours', '\(M.toSQL()) minutes', '\(s.toSQL()) seconds')")
}

private func replaceDatetime(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: to.m,
        d: to.d,
        h: to.h,
        M: to.M,
        s: from.s
    )
}

private func compDatetime(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.m == rhs.m
        && lhs.d == rhs.d
        && lhs.h == rhs.h
        && lhs.M == rhs.M
}

private func replaceDate(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: to.m,
        d: to.d,
        h: from.h,
        M: from.M,
        s: from.s
    )
}

private func compDate(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.m == rhs.m
        && lhs.d == rhs.d
}

private func replaceTime(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: from.m,
        d: from.d,
        h: to.h,
        M: to.M,
        s: from.s
    )
}

private func compTime(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.h == rhs.h
        && lhs.M == rhs.M
}

private func replaceDatetime(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceDatetime(from, to.toComponents()) }
private func replaceDate(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceDate(from, to.toComponents()) }
private func replaceTime(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceTime(from, to.toComponents()) }
private func compDatetime(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compDatetime(from, to.toComponents()) }
private func compDate(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compDate(from, to.toComponents()) }
private func compTime(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compTime(from, to.toComponents()) }

extension PlanManager {
    class Actor {
        let planManager: Module
        let db: Connection

        init(_ planManager: PlanManager) {
            self.planManager = planManager
            self.db = planManager.db
        }

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

        func parseDateTime(_ raw_date: String, _ raw_time: String) -> DateComponents? {
            guard
                let date = parseDate(raw_date),
                let time = parseDate(raw_time)
                else {
                    return nil
            }
            return generateDateTime(date, time)
        }

        func checkDuplicate(date: Date) -> [Plan]? {
            let duplicatedPlans: [Plan]? = try? db.prepare(Table("Plans").filter(Plan.date == date)).decode()
            if duplicatedPlans?.count != 0 {
                return duplicatedPlans
            }
            return nil
        }

        func checkDuplicate(condition cond: Condition) -> [Plan]? {
            let duplicatedPlans: [Plan]? = try? db.prepare(Table("Plans").filter(cond.match(Plan.date))).decode()
            return duplicatedPlans
        }

        func run(_ domainPlan: DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)? {
            let userPlans = Table("Plans").filter(Plan.userId == planManager.userId)
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
                // プランを登録する
                let newPlan = Plan(id: nil, title: planTitle, date: planDatetime.date!, userId: planManager.userId)
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
