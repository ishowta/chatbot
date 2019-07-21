import Bot
import Foundation

/// コンソール上で対話を行うインターフェース
public class Shell: Interface {
    public static func run() {
        let bot = Bot(userRawId: "Shell.test")
        while true {
            print("user: ", terminator: "")
            guard let userMessage = readLine() else { break }
            let botMessages = bot.talk(userMessage)
            for message in botMessages {
                print("bot: \(message)")
            }
        }
    }
}
