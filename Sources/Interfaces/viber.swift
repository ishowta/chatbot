import Bot
import Dispatch
import Foundation
import Just
import Logging
import Swifter

extension Encodable {
    fileprivate func asDictionary() -> [String: Any] {
        let data = try! JSONEncoder().encode(self)
        let dictionary = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        return dictionary
    }
}

public class Viber: Interface {
    static let conf = CONFIG["Viber"] as! [String: String]
    static let headers = [
        "X-Viber-Auth-Token": conf["token"]!
    ]
    static let callbackUrl = conf["url"]!
    
    struct MessageCallback: Codable {
        let event: String
        let timestamp: Int64
        let chat_hostname: String
        let message_token: Int64
        let sender: User
        let message: Message
        let silent: Bool
        struct User: Codable {
            let id: String
            let name: String
            let avatar: String?
            let country: String
            let language: String
            let api_version: Int
        }
        
        struct Message: Codable {
            let type: String
            let text: String
            let media: String?
            let location: Location?
            let tracking_data: String?
            struct Location: Codable {
                let lat: Float
                let lon: Float
            }
        }
    }
    
    struct TextMessage: Codable {
        let receiver: String
        let type: String
        let sender: Sender
        let text: String
        struct Sender: Codable {
            let name: String
            let avatar: String?
        }
    }
    
    static func talk(userRawId: String, userMessage: String) -> [String] {
        let bot = Bot(userRawId: userRawId)
        logger.info("user: \(userMessage)")
        let botMessages: [String] = bot.talk(userMessage)
        for message in botMessages {
            logger.info("bot: \(message)")
        }
        return botMessages
    }
    
    static func sendMessage(userId: String, message: String) {
        let response = Just.post(
            "https://chatapi.viber.com/pa/send_message",
            json: TextMessage(
                receiver: userId,
                type: "text",
                sender: TextMessage.Sender(name: conf["name"]!, avatar: nil),
                text: message
            ).asDictionary(),
            headers: headers
        )
        if response.ok {
            logger.info("Response done.")
            // dump(response.response)
            // dump(response.json)
        }
    }
    
    static func webhook(sem: DispatchSemaphore) {
        let webhookRequest = Just.post(
            "https://chatapi.viber.com/pa/set_webhook",
            json: [
                "url": Viber.callbackUrl
            ],
            headers: headers
        )
        
        if webhookRequest.ok {
            let value = webhookRequest.json as! [String: Any]
            if value["status"] as! Int == 0 {
                logger.info("Webhook success!")
            } else {
                logger.warning("Webhook failed.")
                var buf = ""
                dump(webhookRequest.response, to: &buf)
                logger.warning("Webhook request response: \(buf)")
                dump(webhookRequest.json, to: &buf)
                logger.warning("Webhook request json: \(buf)")
                sem.signal()
            }
        }
    }
    
    public static func run() {
        let server = HttpServer()
        server["/"] = { request in
            logger.info("Get request: \(request.path)")
            let data = Data(bytes: request.body)
            // let rawJson = String(bytes: request.body, encoding: .utf8)
            // dump(rawJson)
            
            if let messageCallback = try? JSONDecoder().decode(MessageCallback.self, from: data) {
                let userId = messageCallback.sender.id
                let userMessage = messageCallback.message.text
                logger.info("Get message \"\(userMessage)\" from \(userId)")
                let botMessages = Viber.talk(userRawId: userId, userMessage: userMessage)
                for message in botMessages {
                    Viber.sendMessage(userId: userId, message: message)
                }
            } else {
                logger.info("Not impl callback")
            }
            
            return HttpResponse.ok(.text(""))
        }
        let semaphore = DispatchSemaphore(value: 0)
        do {
            try server.start(UInt16(conf["port"]!)!)
            let portNumber = try server.port()
            logger.info("Server has started ( port = \(portNumber) ). Try to connect now...")
            
            logger.info("Challenge set webhook after 3 seconds.")
            sleep(3)
            Viber.webhook(sem: semaphore)
            
            semaphore.wait()
        } catch {
            print("Server start error: \(error)")
            semaphore.signal()
        }
    }
}
