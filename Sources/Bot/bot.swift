import Foundation
import SQLite

open class Bot {
    /// 対話相手のID
    public let userId: Int

    /// 使用するモジュールのリスト
    static let moduleTypeList: [Module.Type] = [
        PlanManager.self,
        WeatherReporter.self
        // ! Append new module here
    ]

    /// 会話プランスタック
    var discoursePlanStack: [Module] = []

    static let cannotUnderstandMessage = ["どういうこと？"]

    let db = try! Connection("./db.sqlite3")
    let Users = Table("Users")
    let Plans = Table("Plans")

    /// 一回の会話を行う
    ///
    /// - Parameter userRawId: ユーザーを識別するためのユニークなID
    public init(userRawId: String) {
        User.create(db: db, table: Users)
        Plan.create(db: db, table: Plans)
        try! db.run(Users.insert(or: .ignore, User.rawId <- userRawId))
        self.userId = try! db.pluck(Users.filter(User.rawId == userRawId))![User.id]
    }

    func drawPlanStack() -> String {
        return discoursePlanStack.reversed().map { "[\($0.name)]" }.joined(separator: "\n")
    }

    /// 一回の会話を行う
    ///
    /// - Parameter userMessage: 入力文
    /// - Returns: 返答文
    public func talk(_ userMessage: String) -> [String] {
        logger.info("Current plan stack: \(drawPlanStack())")
        logger.info("User message: \(userMessage)")
        let botMessages = talkImpl(userMessage)
        for message in botMessages {
            logger.info("Bot message: \(message)")
        }
        return botMessages
    }

    func talkImpl(_ userMessage: String) -> [String] {
        if discoursePlanStack.isEmpty {
            logger.info("Discourse plan stack is empty. Select first plan.")
            guard let selectedPlan = selectFirstPlan(firstMessage: userMessage) else {
                logger.info("Select plan faild.")
                return Bot.cannotUnderstandMessage
            }
            logger.info("Selected plan: \(selectedPlan.name)")
            discoursePlanStack.append(selectedPlan)
        }
        var currentPlanModule: Module = discoursePlanStack.last!
        logger.info("Current plan: \(currentPlanModule.name)")
        logger.info("Challenge talk with it.")
        guard let (responseMessages, isPlanFinished) = currentPlanModule.execute(userMessage) else {
            logger.info("Talk failed. Challenge interrupt other plan.")
            guard let interruptPlan = selectInterruptPlan(userMessage) else {
                logger.info("Interrupt plan failed.")
                return Bot.cannotUnderstandMessage
            }
            logger.info("Interrupted plan is \(interruptPlan.name)")
            discoursePlanStack.append(interruptPlan)
            return talkImpl(userMessage)
        }
        if isPlanFinished {
            logger.info("\(currentPlanModule) is finished.")
            discoursePlanStack.removeLast()
        }
        logger.info("Talk finished.")
        return responseMessages
    }

    /// 最初に使用するプランを選択する
    ///
    /// - Parameter firstMessage: 入力文
    /// - Returns: 選択されたモジュール
    func selectFirstPlan(firstMessage: String) -> Module? {
        let acceptableModuleTypeList = Bot.moduleTypeList.filter {
            $0.init(db: db, userId: userId).isAccestableForFirstMessage(firstMessage)
        }
        if acceptableModuleTypeList.isEmpty {
            return nil
        } else if acceptableModuleTypeList.count == 1 {
            return acceptableModuleTypeList.first!.init(db: db, userId: userId)
        } else {
            return acceptableModuleTypeList.first!.init(db: db, userId: userId) // TODO: Select a module by some acceptance score
        }
    }

    /// 割り込むプランを選択する
    ///
    /// - Parameter interruptMessage: 入力文
    /// - Returns: 割り込むモジュール
    func selectInterruptPlan(_ interruptMessage: String) -> Module? {
        return selectFirstPlan(firstMessage: interruptMessage) // TODO: Implement specialized algorithm
    }
}
