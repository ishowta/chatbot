//
//  domainselector.swift
//  chatbot
//
//  Created by Clelia on 2019/07/21.
//

import Foundation

protocol DomainSelector {
    func talk(_ userMessage: String) -> [String]
}
