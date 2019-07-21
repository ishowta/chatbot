//
//  ds_simple.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation
import SQLite

/// 毎ターンドメイン選択を行うドメイン選択器
open class SimpleDomainSelector: DomainSelector {
    /// 使用するモジュールのリスト
    static let moduleTypeList: [Module.Type] = [
        PlanManager.self,
        WeatherReporter.self
        // ! Append new module here
    ]
    
    /// 会話プランリスト
    var discoursePlanList: [Module] = []
    
    /// 初期化
    public init(db: Connection, userId: Int) {
        for moduleType in SimpleDomainSelector.moduleTypeList {
            discoursePlanList.append(moduleType.init(db: db, userId: userId))
        }
    }
    
    func talk(_ userMessage: String) -> [String] {
        logger.info("Select plan.")
        guard var selectedPlan = selectPlan(message: userMessage) else {
            logger.info("Select plan faild.")
            return Bot.cannotUnderstandMessage
        }
        logger.info("Selected plan: \(selectedPlan.name)")
        logger.info("Challenge talk with it.")
        guard let responseMessages = selectedPlan.execute(userMessage) else {
            fatalError("isAccestableのチェックに通ったのにexecuteできない")
        }
        return responseMessages
    }
    
    /// 使用するプランを選択する
    ///
    /// - Parameter message: 入力文
    /// - Returns: 選択されたモジュール
    func selectPlan(message: String) -> Module? {
        let acceptableModuleList = discoursePlanList.filter {
            $0.isAccestableForFirstMessage(message)
            // TODO: first messageではなく続けて発話できるかを判定する関数が必要
        }
        if acceptableModuleList.isEmpty {
            return nil
        } else if acceptableModuleList.count == 1 {
            return acceptableModuleList.first!
        } else {
            return acceptableModuleList.first! // TODO: Select a module by some acceptance score
        }
    }
}
