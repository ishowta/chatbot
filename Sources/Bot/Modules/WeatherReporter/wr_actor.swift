import Foundation
import Regex
import SQLite

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

extension WeatherReporter {
    class Actor {
        let weatherReporter: Module
        let db: Connection
        let calendar = Calendar(identifier: .gregorian)

        init(_ planManager: WeatherReporter) {
            self.weatherReporter = planManager
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

        func run(_ domainPlan: DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)? {
            switch domainPlan {
            case _ as TellWeatherPlan:
                switch dialogueAct {
                case .RequireWeatherAct(let rawDate):
                    let date = parseDate(rawDate)!
                    return (
                        .Domain(
                            .TellWeatherAct(
                                date: date,
                                weather: Weather.allCases.randomElement()!
                            )
                        ),
                        true
                    )
                }
            default:
                fatalError()
            }
        }
    }
}
