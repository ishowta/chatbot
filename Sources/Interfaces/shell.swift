import Bot
import Foundation

public class Shell: Interface {
    public static func run() {
        let bot = Bot(userRawId: "Shell.test")
        while true {
            print("user: ", terminator: "")
            guard let user_message = readLine() else { break }
            let bot_messages: [String] = bot.talk(user_message)
            for message in bot_messages {
                print("bot: \(message)")
            }
        }
    }
}
