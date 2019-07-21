import Foundation
import Regex
import SQLite

final class PlanManager: StackPlanModule {
    let db: Connection

    let userId: Int

    var planStack: [DomainPlan] = []

    let recognizer = Recognizer()
    func recognize(_ message: String) -> DialogueAct? {
        return recognizer.run(message)
    }

    var actor: Actor?
    func act(_ domainPlan: inout DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)? {
        if actor == nil {
            actor = Actor(db: db, userId: userId)
        }
        return actor!.run(domainPlan, dialogueAct)
    }

    let generator = Generator()
    func generate(_ dialogueAct: DialogueActForBot) -> [String] {
        return generator.run(dialogueAct)
    }

    init(db: Connection, userId: Int) {
        self.db = db
        self.userId = userId
    }

    struct Condition {
        let match: (_ date: Expression<Date>) -> Expression<Bool>
        let convert: (_ date: Expression<Date>) -> Expression<Date>
    }

    enum DialogueAct {
        case RequireRegistrationAct(title: String?, date: String?, time: String?)
        case RequireUpdateAct(to: String, title: String?, condition: String?)
        case RequireDeleteAct(title: String?, condition: String?)
        case RequireShowAct(title: String?, condition: String?)
        case TellAct(title: String?, date: String?, time: String?)
    }

    class RegistrationPlan: DomainPlan {
        var title: String?
        var date: DateComponents?
        var time: DateComponents?
        var registratedPlan: Plan?
        init() {}
    }

    class UpdatePlan: DomainPlan {
        var to: Condition?
        var title: String?
        var condition: Condition?
        var updatedPlans: [Plan]?
        init() {}
    }

    class DeletePlan: DomainPlan {
        var deletedPlans: [Plan]?
        init() {}
    }

    class ShowPlan: DomainPlan {
        var plans: [Plan]?
        init() {}
    }

    enum DialogueActForBot {
        enum DomainPlanState {
            case Complete
            case Error
        }

        case TellAct(domainPlan: DomainPlan, state: DomainPlanState, message: String?)
        case RequestDataAct(dataNameList: [String])
        case ShowPlanStatusAct(plan: Plan)
        case TellDuplicatedAct(duplicatedPlan: [Plan])
    }

    func selectFirstPlan(_ firstDialogueAct: DialogueAct) -> DomainPlan? {
        switch firstDialogueAct {
        case .RequireRegistrationAct:
            return RegistrationPlan()
        case .RequireUpdateAct:
            return UpdatePlan()
        case .RequireDeleteAct:
            return DeletePlan()
        case .RequireShowAct:
            return ShowPlan()
        case .TellAct:
            return nil
        }
    }
}
