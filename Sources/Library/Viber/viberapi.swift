//
//  viberapi.swift
//  AppTests
//
//  Created by Clelia on 2019/07/20.
//

import Foundation
import Just
import Logging
import Swifter

extension Encodable {
    func toDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        return dictionary
    }
}

private func decode<T>(_ data: Data, _ modelType: T.Type) -> T? where T: Decodable {
    return try? JSONDecoder().decode(modelType, from: data)
}

public enum ViberAPIMessageType: String, Codable {
    case Text = "text"
    case Picture = "picture"
    case Video = "video"
    case File = "file"
    case Location = "location"
    case Contact = "contact"
    case Sticker = "sticker"
    case Carousel = "rich_media"
    case Url = "url"
}

public enum ViberAPIEventType: String, Codable {
    case Subscribed = "subscribed"
    case Unsubscribed = "unsubscribed"
    case ConversationStarted = "conversation_started"
    case Delivered = "delivered"
    case Seen = "seen"
    case Failed = "failed"
    case Message = "message"
}

/// Viber any content message protocol
///
///     Normal message ... Only receiver specified
///
///     Broadcast message ... Only broadcast_list specified
///
///     Post to public message ... Only from specified
///
///     Welcome message ... Not specified
public protocol ViberAPIMessage: Codable {
    var type: ViberAPIMessageType { get }
    
    var receiver: String? { get }
    var broadcast_list: [String]? { get }
    var from: String? { get }
}

public protocol ViberAPICallback: Codable {
    var event: ViberAPIEventType { get }
}

open class ViberAPI {
    public let http: JustOf<HTTP>
    
    public init(token: String) {
        http = JustOf<HTTP>(defaults: JustSessionDefaults(
            headers: ["X-Viber-Auth-Token": token]
        ))
    }
    
    // Various types
    
    public struct Sender: Codable {
        public let name: String
        public let avatar: String?
    }
    
    public struct Contact: Codable {
        public let name: String
        public let phone_number: String
    }
    
    public struct Location: Codable {
        public let lat: String
        public let lon: String
    }
    
    public struct Button: Codable {
        public let Columns: Int
        public let Rows: Int
        public let ActionType: String
        public let ActionBody: String
        public let Text: String
        public let TextSize: String
        public let TextVAlign: String
        public let TextHAlign: String
        public let Image: String
        public let BgColor: String
        public let Silent: Bool
    }
    
    public struct RichMedia: Codable {
        public let `Type`: String = "rich_media"
        public let ButtonsGroupColumns: Int
        public let ButtonsGroupRows: Int
        public let BgColor: String
        public let Buttons: [Button]
    }
    
    public enum EventType: String, Codable {
        case Delivered = "delivered"
        case Seen = "seen"
        case Failed = "failed"
        case Subscribed = "subscribed"
        case Unsubscribed = "unsubscribed"
        case ConversationStarted = "conversation_started"
    }
    
    // Webhook types
    
    public struct SetWebhookRequest: Codable {
        public let url: String
        public let event_types: [EventType]?
        public let send_name: Bool?
        public let send_photo: Bool?
        public init(url: String, event_types: [EventType]? = nil, send_name: Bool? = nil, send_photo: Bool? = nil) {
            self.url = url; self.event_types = event_types; self.send_name = send_name; self.send_photo = send_photo
        }
    }
    
    public struct SetWebhookResponse: Codable {
        public let status: Int
        public let status_message: String
        public let event_types: [EventType]?
    }
    
    // Message types
    
    public struct TextMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Text
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let text: String
    }
    
    public struct PictureMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Picture
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let text: String
        public let media: String
        public let thumbnail: String?
    }
    
    public struct VideoMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Video
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let media: String
        public let size: Int
        public let duration: Int?
        public let thumbnail: String?
    }
    
    public struct FileMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.File
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let media: String
        public let size: Int
        public let filename: String
    }
    
    public struct ContactMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Contact
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let contact: Contact
    }
    
    public struct LocationMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Location
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let location: Location
    }
    
    public struct URLMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Url
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let URL: String
    }
    
    public struct StickerMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Sticker
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 1
        
        public let sticker_id: Int
    }
    
    public struct CarouselMessage: ViberAPIMessage {
        public let receiver: String?
        public let broadcast_list: [String]?
        public let from: String?
        
        public let type: ViberAPIMessageType = ViberAPIMessageType.Carousel
        public let sender: Sender
        public let tracking_data: String?
        public let min_api_version: Int = 2
        
        public let rich_media: RichMedia
        public let alt_text: String?
    }
    
    // TODO: Implement keyboard message type
    
    // Broadcast message types
    
    public struct BroadcastMessageResponse: Codable {
        public struct Failed: Codable {
            public let receiver: String
            public let status: Int
            public let status_message: String
        }
        
        public let message_token: Int64
        public let status: Int
        public let status_message: String
        public let failed_list: [Failed]?
    }
    
    // Get Account Info types
    
    public struct AccountInfo: Codable {
        public struct Account: Codable {
            public let id: String
            public let name: String
            public let avatar: String
            public let role: String
        }
        
        public let status: Int
        public let status_message: String
        public let id: String
        public let name: String
        public let uri: String
        public let icon: String
        public let background: String
        public let category: String
        public let subcategory: String
        public let location: Location
        public let country: String
        public let webhook: String
        public let event_types: [String]
        public let subscribers_count: Int
        public let members: [Account]
    }
    
    // Get User Details types
    
    public struct GetUserDetailsRequest: Codable {
        public let id: String
    }
    
    public struct UserDetails: Codable {
        public struct User: Codable {
            public let id: String
            public let name: String
            public let avatar: String
            public let country: String
            public let language: String
            public let primary_device_os: String
            public let api_version: Int
            public let viber_version: String
            public let mcc: Int
            public let mnc: Int
            public let device_type: String
        }
        
        public let status: Int
        public let status_message: String
        public let message_token: Int64
        public let user: User
    }
    
    // Get Online types
    
    public struct GetOnlineRequest: Codable {
        public let ids: [String]
    }
    
    public struct Online: Codable {
        public struct UserOnlineStatus: Codable {
            public let id: String
            public let online_status: Int
            public let online_status_message: String
            public let last_online: Int64
        }
        
        public let status: Int
        public let status_message: String
        public let users: [UserOnlineStatus]
    }
    
    // Callback types
    
    public struct User: Codable {
        public let id: String
        public let name: String
        public let avatar: String
        public let country: String
        public let language: String
        public let api_version: Int
    }
    
    public struct UserMessage: Codable {
        public enum type: String, Codable {
            case Text = "text"
            case Picture = "picture"
            case Video = "video"
            case File = "file"
            case Sticker = "sticker"
            case Contact = "contact"
            case Url = "url"
        }
        
        public let type: type
        public let text: String?
        public let media: String?
        public let location: Location?
        public let contact: Contact?
        public let tracking_data: String?
        public let file_name: String?
        public let file_size: Int64?
        public let duration: Int?
        public let sticker_id: Int?
    }
    
    public struct SubscribedCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Subscribed
        public let timestamp: Int64
        public let user: User
        public let message_token: Int64
    }
    
    public struct UnsubscribedCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Unsubscribed
        public let timestamp: Int64
        public let message_token: Int64
        public let user_id: String
    }
    
    public struct ConversationStartedCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.ConversationStarted
        public let timestamp: Int64
        public let user: User
        public let message_token: Int64
        public let type: String = "open"
        public let context: String
        public let subscribed: Bool
    }
    
    public struct DeliveredCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Delivered
        public let timestamp: Int64
        public let message_token: Int64
        public let user_id: String
    }
    
    public struct SeenCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Seen
        public let timestamp: Int64
        public let message_token: Int64
        public let user_id: String
    }
    
    public struct FailedCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Failed
        public let timestamp: Int64
        public let message_token: Int64
        public let user_id: String
        public let desc: String
    }
    
    public struct MessageCallback: ViberAPICallback {
        public let event: ViberAPIEventType = ViberAPIEventType.Message
        public let timestamp: Int64
        public let message_token: Int64
        public let sender: User
        public let message: UserMessage
    }
    
    // Functions
    
    open func setWebhook(request: SetWebhookRequest, _ completion: @escaping (Result<SetWebhookResponse, Error>) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/set_webhook",
            json: request.toDictionary()
        ) { res in
            if res.ok {
                completion(.success(decode(res.json as! Data, SetWebhookResponse.self)!))
            } else {
                completion(.failure(res.error!))
            }
        }
    }
    
    open func removeWebhook(_ completion: @escaping (Error?) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/set_webhook",
            json: SetWebhookRequest(url: "")
        ) { res in
            if res.ok {
                completion(nil)
            } else {
                completion(res.error!)
            }
        }
    }
    
    open func sendMessage(message: ViberAPIMessage, _ completion: @escaping (Error?) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/send_message",
            json: message.toDictionary()
        ) { res in
            if res.ok {
                completion(nil)
            } else {
                completion(res.error!)
            }
        }
    }
    
    open func sendMessage(message: [String: Any], _ completion: @escaping (Error?) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/send_message",
            json: message
        ) { res in
            if res.ok {
                completion(nil)
            } else {
                completion(res.error!)
            }
        }
    }
    
    open func broadcastMessage(message: ViberAPIMessage, _ completion: @escaping (Result<BroadcastMessageResponse, Error>) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/send_message",
            json: message.toDictionary()
        ) { res in
            if res.ok {
                completion(.success(decode(res.json as! Data, BroadcastMessageResponse.self)!))
            } else {
                completion(.failure(res.error!))
            }
        }
    }
    
    open func getAccountInfo(_ completion: @escaping (Result<AccountInfo, Error>) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/get_account_info",
            json: []
        ) { res in
            if res.ok {
                completion(.success(decode(res.json as! Data, AccountInfo.self)!))
            } else {
                completion(.failure(res.error!))
            }
        }
    }
    
    open func getUserDetails(request: GetUserDetailsRequest, _ completion: @escaping (Result<UserDetails, Error>) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/get_user_details",
            json: request.toDictionary()
        ) { res in
            if res.ok {
                completion(.success(decode(res.json as! Data, UserDetails.self)!))
            } else {
                completion(.failure(res.error!))
            }
        }
    }
    
    open func getOnline(request: GetOnlineRequest, _ completion: @escaping (Result<Online, Error>) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/get_online",
            json: request.toDictionary()
        ) { res in
            if res.ok {
                completion(.success(decode(res.json as! Data, Online.self)!))
            } else {
                completion(.failure(res.error!))
            }
        }
    }
    
    open func postToPublicChat(request: GetUserDetailsRequest, _ completion: @escaping (Error?) -> Void) {
        http.post(
            "https://chatapi.viber.com/pa/post",
            json: request.toDictionary()
        ) { res in
            if res.ok {
                completion(nil)
            } else {
                completion(res.error!)
            }
        }
    }
    
    // TODO: Implement callback signature check
    
    open func parseCallback(data: Data) -> ViberAPICallback? {
        struct ViberAPICallbackBase: ViberAPICallback {
            let event: ViberAPIEventType
        }
        guard let callback = try? JSONDecoder().decode(ViberAPICallbackBase.self, from: data) else {
            return nil
        }
        switch callback.event {
        case .Subscribed:
            return try! JSONDecoder().decode(ViberAPI.SubscribedCallback.self, from: data)
        case .Unsubscribed:
            return try! JSONDecoder().decode(ViberAPI.UnsubscribedCallback.self, from: data)
        case .ConversationStarted:
            return try! JSONDecoder().decode(ViberAPI.ConversationStartedCallback.self, from: data)
        case .Delivered:
            return try! JSONDecoder().decode(ViberAPI.DeliveredCallback.self, from: data)
        case .Seen:
            return try! JSONDecoder().decode(ViberAPI.SeenCallback.self, from: data)
        case .Failed:
            return try! JSONDecoder().decode(ViberAPI.FailedCallback.self, from: data)
        case .Message:
            return try! JSONDecoder().decode(ViberAPI.MessageCallback.self, from: data)
        }
    }
}
