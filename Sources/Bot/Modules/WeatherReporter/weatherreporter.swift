import Foundation
import Regex
import SQLite

/// 天気を教えてくれるモジュール
///
/// 最小構成のテストモジュールのためランダムに天気を返すだけ
final class WeatherReporter: StackPlanModule {
    let db: Connection

    let userId: Int

    var planStack: [DomainPlan] = []

    let recognizer: Recognizer
    func recognize(_ message: String) -> DialogueAct? {
        return recognizer.run(message)
    }

    var actor: Actor
    func act(_ domainPlan: inout DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)? {
        return actor.run(domainPlan, dialogueAct)
    }

    let generator: Generator
    func generate(_ dialogueAct: DialogueActForBot) -> [String] {
        return generator.run(dialogueAct)
    }

    init(db: Connection, userId: Int) {
        self.db = db
        self.userId = userId
        self.recognizer = Recognizer()
        self.actor = Actor()
        self.generator = Generator()
    }

    enum Weather: CaseIterable {
        case Sunny, Rainy, Cloudy
    }

    enum DialogueAct {
        case RequireWeatherAct(date: String)
    }

    class TellWeatherPlan: DomainPlan {}

    enum DialogueActForBot {
        case TellWeatherAct(date: DateComponents, weather: Weather)
    }

    func selectFirstPlan(_ firstDialogueAct: DialogueAct) -> DomainPlan? {
        switch firstDialogueAct {
        case .RequireWeatherAct:
            return TellWeatherPlan()
        }
    }
}
