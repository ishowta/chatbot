//
//  domainselector.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation
import SQLite

open class DomainSelector {
    /// 使用するモジュールのリスト
    static let moduleTypeList: [Module.Type] = [
        PlanManager.self,
        WeatherReporter.self
        // ! Append new module here
    ]
    
    /// 会話プランスタック
    var discoursePlanStack: [Module] = []
    
    let db: Connection
    let userId: Int
    
    /// 初期化
    public init(db: Connection, userId: Int) {
        self.db = db
        self.userId = userId
    }
    
    func drawPlanStack() -> String {
        return discoursePlanStack.reversed().map { "[\($0.name)]" }.joined(separator: "\n")
    }
    
    func talk(_ userMessage: String) -> [String] {
        logger.info("Current plan stack: \(drawPlanStack())")
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
            return talk(userMessage)
        }
        if isPlanFinished {
            logger.info("\(currentPlanModule) is finished.")
            discoursePlanStack.removeLast()
        }
        return responseMessages
    }
    
    /// 最初に使用するプランを選択する
    ///
    /// - Parameter firstMessage: 入力文
    /// - Returns: 選択されたモジュール
    func selectFirstPlan(firstMessage: String) -> Module? {
        let acceptableModuleTypeList = DomainSelector.moduleTypeList.filter {
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
