import Bot
import Dispatch
import Foundation
import Just
import Logging
import Swifter
import Viber

public class ViberBot: Interface {
    static let viber = Viber(token: config.viber.token, name: config.viber.name)
    
    static func talk(userRawId: String, userMessage: String) -> [String] {
        let bot = Bot(userRawId: userRawId)
        logger.info("user: \(userMessage)")
        let botMessages: [String] = bot.talk(userMessage)
        for message in botMessages {
            logger.info("bot: \(message)")
        }
        return botMessages
    }
    
    public static func run() {
        let server = HttpServer()
        server["/"] = { request in
            logger.info("Get request: \(request.path)")
            let data = Data(bytes: request.body)
            // let rawJson = String(bytes: request.body, encoding: .utf8)
            // dump(rawJson)
            
            if let callback = viber.parseCallback(data: data) {
                switch callback.event {
                case .Message:
                    let callback = callback as! ViberAPI.MessageCallback
                    let user = callback.sender
                    switch callback.message.type {
                    case .Text:
                        let userMessage = callback.message.text!
                        logger.info("Get message \"\(userMessage)\" from \(user.name)")
                        let botMessages = ViberBot.talk(userRawId: user.id, userMessage: userMessage)
                        for message in botMessages {
                            viber.sendMessage(
                                message: Viber.TextMessage(text: message),
                                to: user.name,
                                { _ in }
                            )
                        }
                    case .Picture, .Video, .File, .Sticker, .Contact, .Url:
                        logger.info("Does not support this message type.")
                    }
                    return HttpResponse.ok(.text(""))
                case .Subscribed, .Unsubscribed, .ConversationStarted, .Delivered, .Seen, .Failed, .Action:
                    logger.info("Does not support this callback.")
                    return HttpResponse.ok(.text(""))
                case .Webhook:
                    logger.info("Accept webhook.")
                    return HttpResponse.ok(.text(""))
                }
            } else {
                return HttpResponse.badRequest(nil)
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        do {
            try server.start(config.viber.port)
            let portNumber = try server.port()
            logger.info("Server has started ( port = \(portNumber) ).")
            logger.info("Challenge set webhook after 3 seconds.")
            sleep(3)
            logger.info("try...")
            viber.setWebhook(callbackUrl: config.viber.url) { res in
                switch res {
                case .none:
                    logger.info("Webhook success")
                case .some(let error):
                    logger.warning("Webhook failed.")
                    if let error = error as? Viber.ViberError {
                        logger.warning("Error code: \(error.code) Error message: \(error.message)")
                    }
                    semaphore.signal()
                }
            }
            
            semaphore.wait()
        } catch {
            print("Server start error: \(error)")
            semaphore.signal()
        }
    }
}
