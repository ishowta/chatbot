import Foundation
import Regex
import SQLite

extension WeatherReporter {
    class Actor {
        let calendar = Calendar(identifier: .gregorian)

        init() {}

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
                                weather: Weather.allCases.randomElement()! // テストモジュールなので
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
