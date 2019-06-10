import Foundation

extension Date {
    fileprivate func toStr() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: self)
    }
}

extension PlanManager {
    class Generator {
        func generatePlansDetails(_ plans: [Plan]) -> String {
            return plans.map { "\($0.date.toStr()): \($0.title)" }.joined(separator: ",")
        }

        func run(_ dialogueAct: PlanManager.DialogueActForBot) -> [String] {
            switch dialogueAct {
            case .TellAct(let domainPlan, let state, let message):
                switch state {
                case .Complete:
                    switch domainPlan {
                    case let plan as RegistrationPlan:
                        return [
                            "\(plan.title!)を登録しました。"
                        ]
                    case let plan as UpdatePlan:
                        return [
                            "\(plan.updatedPlans!.count)つの予定を登録しました。",
                            generatePlansDetails(plan.updatedPlans!)
                        ]
                    case let plan as DeletePlan:
                        return [
                            "\(plan.deletedPlans!.count)つの予定を削除しました。",
                            generatePlansDetails(plan.deletedPlans!)
                        ]
                    case let plan as ShowPlan:
                        return [
                            "\(plan.plans!.count)つの予定が見つかりました。",
                            generatePlansDetails(plan.plans!)
                        ]
                    default:
                        fatalError()
                    }
                case .Error:
                    return [message!]
                }
            case .RequestDataAct(let dataNameList):
                return [
                    "\(dataNameList.joined(separator: "と"))を教えてください。"
                ]
            case .ShowPlanStatusAct(let plan):
                return [
                    "\(plan.title)は\(plan.date.toStr())に予定されています。"
                ]
            case .TellDuplicatedAct(let duplicatedPlans):
                return [
                    "その時間は以下の予定と重複しています。",
                    generatePlansDetails(duplicatedPlans)
                ]
            }
        }
    }
}
