import Foundation
import SQLite

open class Bot {
    /// 対話相手のID
    public let userId: Int

    /// ユーザーメッセージに全く応対できなかったときに返す最終手段のメッセージ
    static let cannotUnderstandMessage = ["すみません。理解できません。"]

    /// Botで用いるDB
    let db = try! Connection("./db.sqlite3")

    /// ユーザーDB
    let Users = Table("Users")

    /// 予定DB
    let Plans = Table("Plans")

    /// ドメイン選択器
    let domainSelector: DomainSelector

    /// 初期化
    ///
    /// - Parameter userRawId: ユーザーを識別するためのユニークなID
    public init(userRawId: String) {
        User.create(db: db, table: Users)
        Plan.create(db: db, table: Plans)
        try! db.run(Users.insert(or: .ignore, User.rawId <- userRawId))
        self.userId = try! db.pluck(Users.filter(User.rawId == userRawId))![User.id]
        switch config.domainStrategy {
        case .OneDomain:
            let moduleType = NSClassFromString("Bot." + config.domain) as! Module.Type
            self.domainSelector = OneDomainDomainSelector(
                module: moduleType.init(db: db, userId: userId)
            )
        case .Simple:
            self.domainSelector = SimpleDomainSelector(db: db, userId: userId)
        case .Stack:
            self.domainSelector = StackDomainSelector(db: db, userId: userId)
        }
    }

    /// 一回の会話を行う
    ///
    /// - Parameter userMessage: 入力文
    /// - Returns: 返答文
    public func talk(_ userMessage: String) -> [String] {
        logger.info("User message: \(userMessage)")
        let botMessages = domainSelector.talk(userMessage)
        for message in botMessages {
            logger.info("Bot message: \(message)")
        }
        return botMessages
    }
}
