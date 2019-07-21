//
//  datehelper.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation
import Regex
import SQLite

let calendar = Calendar(identifier: .gregorian)

extension Date {
    func toComponents() -> DateComponents {
        return Calendar(identifier: .gregorian).dateComponents(in: TimeZone.current, from: self)
    }
}

protocol SQL {
    func toSQL() -> String
}

extension String: SQL {
    func toSQL() -> String { return self }
}

extension Expression: SQL {
    func toSQL() -> String { return template }
}

extension DateComponents {
    var y: String { return "\(year!)" }
    var m: String { return "\(month!)" }
    var d: String { return "\(day!)" }
    var h: String { return "\(hour!)" }
    var M: String { return "\(minute!)" }
    var s: String { return "\(second!)" }
}

extension Calendar {
    func date(byAdding: Component, value: Int, to: Expression<Date>) -> Expression<Date> {
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
func genDate(y: SQL, m: SQL, d: SQL, h: SQL, M: SQL, s: SQL) -> Expression<Date> {
    return Expression<Date>("datetime('0000-00-00 00:00:00', '\(y.toSQL()) years', '\(m.toSQL()) months', '\(d.toSQL()) days', '\(h.toSQL()) hours', '\(M.toSQL()) minutes', '\(s.toSQL()) seconds')")
}

func replaceDatetime(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: to.m,
        d: to.d,
        h: to.h,
        M: to.M,
        s: from.s
    )
}

func compDatetime(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.m == rhs.m
        && lhs.d == rhs.d
        && lhs.h == rhs.h
        && lhs.M == rhs.M
}

func replaceDate(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: to.m,
        d: to.d,
        h: from.h,
        M: from.M,
        s: from.s
    )
}

func compDate(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.m == rhs.m
        && lhs.d == rhs.d
}

func replaceTime(_ from: Expression<Date>, _ to: DateComponents) -> Expression<Date> {
    return genDate(
        y: from.y,
        m: from.m,
        d: from.d,
        h: to.h,
        M: to.M,
        s: from.s
    )
}

func compTime(_ lhs: Expression<Date>, _ rhs: DateComponents) -> Expression<Bool> {
    return lhs.h == rhs.h
        && lhs.M == rhs.M
}

func replaceDatetime(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceDatetime(from, to.toComponents()) }
func replaceDate(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceDate(from, to.toComponents()) }
func replaceTime(_ from: Expression<Date>, _ to: Date) -> Expression<Date> { return replaceTime(from, to.toComponents()) }
func compDatetime(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compDatetime(from, to.toComponents()) }
func compDate(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compDate(from, to.toComponents()) }
func compTime(_ from: Expression<Date>, _ to: Date) -> Expression<Bool> { return compTime(from, to.toComponents()) }
