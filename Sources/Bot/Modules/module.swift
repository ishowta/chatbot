import SQLite

/// モジュールのプロトコル
protocol Module {
    /// モジュールがメッセージを会話の最初の入力文として受理できるかをチェックする
    ///
    /// - Parameter message: 最初の入力文
    /// - Returns: 受理できるか
    func isAccestableForFirstMessage(_ message: String) -> Bool

    /// 一回の会話を実行する
    ///
    /// - Parameter userMessage: 入力文
    /// - Returns: 応答文のリスト
    mutating func execute(_ userMessage: String) -> [String]?

    /// - Parameter db: データベース
    /// - Parameter userId: UsersテーブルのユーザーID
    init(db: Connection, userId: Int)

    /// 一通りの会話が終了したか（将来的に修辞関係や隣接ペアを使いたい）
    var isPlanFinished: Bool { get }

    /// このモジュールで使用するDB（現状DBは一つだけ）
    var db: Connection { get }

    /// 対話するユーザーのUsersテーブルのユーザーID
    var userId: Int { get }
}

extension Module {
    /// モジュール名の文字列を返す
    var name: String {
        return String(describing: type(of: self))
    }
}
