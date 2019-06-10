import Foundation

extension DateComponents {
    fileprivate func toStr() -> String {
        return "\(self.month!)月\(self.day!)日"
    }
}

extension WeatherReporter.Weather {
    fileprivate func toString() -> String {
        switch self {
        case .Sunny:
            return "晴れ"
        case .Rainy:
            return "雨"
        case .Cloudy:
            return "曇り"
        }
    }
}

extension WeatherReporter {
    class Generator {
        func run(_ dialogueAct: WeatherReporter.DialogueActForBot) -> [String] {
            switch dialogueAct {
            case .TellWeatherAct(let date, let weather):
                return [
                    "\(date.toStr())の天気は\(weather.toString())です。"
                ]
            }
        }
    }
}
