//
//  ds_onedomain.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation
import SQLite

open class OneDomainDomainSelector: DomainSelector {
    /// 使用するモジュール
    var module: Module

    /// 初期化
    init(module: Module) {
        self.module = module
    }

    func talk(_ userMessage: String) -> [String] {
        if let responseMessages = module.execute(userMessage) {
            return responseMessages
        } else {
            logger.warning("Talk failed. Cannot understand `\(userMessage)` in \(module.self).")
            return Bot.cannotUnderstandMessage
        }
    }
}
