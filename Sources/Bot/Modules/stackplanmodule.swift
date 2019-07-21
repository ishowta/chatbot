//
//  stackplanmodule.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation

enum EitherSpec<BasicType, DomainType> {
    case Basic(BasicType)
    case Domain(DomainType)
}

/// 共通の応答発話行為
enum BasicDialogueActForBot {
    case MessageAct(message: String)
}

/// 共通の発話生成
func basicGenerate(_ dialogueAct: BasicDialogueActForBot) -> [String] {
    switch dialogueAct {
    case .MessageAct(let message):
        return [
            message
        ]
    }
}

/// ドメインプラン
protocol DomainPlan {}
extension DomainPlan {
    /// プラン名
    var name: String {
        return String(describing: type(of: self))
    }
}

/// スタック方式で複数のプランを管理するモジュールのプロトコル
protocol StackPlanModule: Module {
    /// 発話行為
    associatedtype DialogueAct
    
    /// 応答発話行為
    associatedtype DialogueActForBot
    
    /// 共通の応答発話行為 or Module別の応答発話行為
    typealias EitherDialogueActForBot = EitherSpec<BasicDialogueActForBot, DialogueActForBot>
    
    /// ドメインプランスタック
    var planStack: [DomainPlan] { get set }
    
    /// 言語理解
    ///
    /// - Parameter message: 入力文
    /// - Returns: 入力の発話行為
    func recognize(_ message: String) -> DialogueAct?
    
    /// 応答（内部状態更新）
    ///
    /// - Parameters:
    ///   - domainPlan: ドメインプラン
    ///   - dialogueAct: 入力発話行為
    /// - Returns: 応答発話行為
    func act(_ domainPlan: inout DomainPlan, _ dialogueAct: DialogueAct) -> (EitherDialogueActForBot, Bool)?
    
    /// 言語生成
    ///
    /// - Parameter dialogueAct: 応答発話行為
    /// - Returns: 応答文
    func generate(_ dialogueAct: DialogueActForBot) -> [String]
    
    /// 最初に使用するプランを選択する
    ///
    /// - Parameter firstDialogueAct: 入力発話行為
    /// - Returns: 選択されたモジュール
    func selectFirstPlan(_ firstDialogueAct: DialogueAct) -> DomainPlan?
    
    /// 割り込むプランを選択する
    ///
    /// - Parameter interruptMessage: 入力文
    /// - Returns: 割り込むモジュール
    func selectInterruptPlan(_ interruptAct: DialogueAct) -> DomainPlan?
}

extension StackPlanModule {
    func isAccestableForFirstMessage(_ message: String) -> Bool {
        guard let firstUserAct = recognize(message) else {
            logger.info("Can't recognize a message in this module")
            return false
        }
        guard selectFirstPlan(firstUserAct) != nil else {
            logger.info("Can't recognize a dialogue act in this module")
            return false
        }
        return true
    }
    
    mutating func execute(_ userMessage: String) -> [String]? {
        logger.info("(1/3) Recognize message")
        guard let userAct = recognize(userMessage) else {
            logger.info("Can't recognize a message in this module")
            return nil
        }
        logger.info("(1/3) User act: \(dump(userAct))")
        logger.info("(2/3) Action")
        guard let botAct = executeAct(userAct) else {
            logger.info("Can't action in this module")
            return nil
        }
        logger.info("(2/3) Bot act: \(dump(botAct))")
        logger.info("(3/3) Generate message")
        var botMessages: [String] = []
        switch botAct {
        case .Basic(let botAct):
            botMessages = basicGenerate(botAct)
        case .Domain(let botAct):
            botMessages = generate(botAct)
        }
        logger.info("(3/3) Bot message: \(botMessages.joined(separator: " "))")
        return botMessages
    }
    
    var isPlanFinished: Bool {
        return planStack.isEmpty
    }
    
    /// プランスタックからプランを選択しactを呼ぶ
    private mutating func executeAct(_ userAct: DialogueAct) -> EitherDialogueActForBot? {
        if planStack.isEmpty {
            logger.info("Domain plan stack is empty. Select first plan.")
            let selectedPlan = selectFirstPlan(userAct)!
            logger.info("Selected plan: \(selectedPlan.name)")
            planStack.append(selectedPlan)
        }
        var currentDomainPlan: DomainPlan = planStack.last!
        logger.info("Current plan: \(currentDomainPlan.name)")
        logger.info("Challenge talk with it.")
        guard let (botAct, isPlanFinished) = act(&currentDomainPlan, userAct) else {
            logger.info("Talk failed. Challenge interrupt other plan.")
            guard let interruptPlan = selectInterruptPlan(userAct) else {
                logger.info("Interrupt plan failed.")
                return nil
            }
            logger.info("Interrupted plan is \(interruptPlan.name)")
            planStack.append(interruptPlan)
            return executeAct(userAct)
        }
        if isPlanFinished {
            logger.info("\(currentDomainPlan) is finished.")
            planStack.removeLast()
        }
        return botAct
    }
    
    func selectInterruptPlan(_ interruptAct: DialogueAct) -> DomainPlan? {
        return selectFirstPlan(interruptAct) // TODO: Implement specialized algorithm
    }
}
