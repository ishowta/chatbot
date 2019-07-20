//
//  viberAPI.swift
//  chatbot
//
//  Created by Clelia on 2019/07/19.
//

import Foundation
import Logging

extension Sequence {
    func any(_ f: (Element) -> Bool) -> Bool {
        return reduce(false) { $0 || f($1) }
    }
    
    func all(_ f: (Element) -> Bool) -> Bool {
        return reduce(true) { $0 && f($1) }
    }
}

public protocol ViberMessage {}

open class Viber {
    public let token: String
    public let name: String
    public let avatar: String?
    public let api: ViberAPI
    
    public init(token: String, name: String, avatar: String? = nil) {
        self.token = token
        self.name = name
        self.avatar = avatar
        api = ViberAPI(token: token)
    }
    
    public struct ViberError: Error {
        public let code: Int
        public let message: String
    }
    
    public struct ViberUserError: Error {
        public let user: String
        public let error: ViberError
    }
    
    public struct ViberBroadcastError: Error {
        public let error: ViberError
        public let userError: [ViberUserError]?
    }
    
    public struct TextMessage: ViberMessage {
        public let text: String
    }
    
    public struct PictureMessage: ViberMessage {
        public let text: String
        public let media: String
        public let thumbnail: String?
    }
    
    public struct VideoMessage: ViberMessage {
        public let media: String
        public let size: Int
        public let duration: Int?
        public let thumbnail: String?
    }
    
    public struct FileMessage: ViberMessage {
        public let media: String
        public let size: Int
        public let filename: String
    }
    
    public struct ContactMessage: ViberMessage {
        public let contact: ViberAPI.Contact
    }
    
    public struct LocationMessage: ViberMessage {
        public let location: ViberAPI.Location
    }
    
    public struct URLMessage: ViberMessage {
        public let URL: String
    }
    
    public struct StickerMessage: ViberMessage {
        public let sticker_id: Int
    }
    
    public struct CarouselMessage: ViberMessage {
        public let rich_media: ViberAPI.RichMedia
        public let alt_text: String?
    }
    
    open func setWebhook(
        callbackUrl: String,
        receiveEventTypeList: [ViberAPI.EventType]? = nil,
        hasReceiveName: Bool = false,
        hasReceivePhoto: Bool = false,
        _ completion: @escaping (Error?) -> Void
    ) {
        api.setWebhook(request: ViberAPI.SetWebhookRequest(
            url: callbackUrl,
            event_types: receiveEventTypeList,
            send_name: hasReceiveName,
            send_photo: hasReceivePhoto
        )) { res in
            switch res {
            case .success(let res):
                if res.status == 0 {
                    completion(nil)
                } else {
                    completion(ViberError(code: res.status, message: res.status_message))
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    open func removeWebhook(_ completion: @escaping (Error?) -> Void) {
        api.removeWebhook { res in completion(res) }
    }
    
    open func sendMessage(message: ViberMessage, to: String, _ completion: @escaping (Error?) -> Void) {
        func convertMessage(_ mes: ViberMessage) -> ViberAPIMessage {
            let sender = ViberAPI.Sender(name: name, avatar: avatar)
            switch mes {
            case let mes as Viber.TextMessage:
                return ViberAPI.TextMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, text: mes.text)
            case let mes as Viber.PictureMessage:
                return ViberAPI.PictureMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, text: mes.text, media: mes.media, thumbnail: mes.thumbnail)
            case let mes as Viber.VideoMessage:
                return ViberAPI.VideoMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, media: mes.media, size: mes.size, duration: mes.duration, thumbnail: mes.thumbnail)
            case let mes as Viber.FileMessage:
                return ViberAPI.FileMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, media: mes.media, size: mes.size, filename: mes.filename)
            case let mes as Viber.ContactMessage:
                return ViberAPI.ContactMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, contact: mes.contact)
            case let mes as Viber.LocationMessage:
                return ViberAPI.LocationMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, location: mes.location)
            case let mes as Viber.URLMessage:
                return ViberAPI.URLMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, URL: mes.URL)
            case let mes as Viber.StickerMessage:
                return ViberAPI.StickerMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, sticker_id: mes.sticker_id)
            case let mes as Viber.CarouselMessage:
                return ViberAPI.CarouselMessage(receiver: to, broadcast_list: nil, from: nil, sender: sender, tracking_data: nil, rich_media: mes.rich_media, alt_text: mes.alt_text)
            default:
                fatalError()
            }
        }
        
        api.sendMessage(message: convertMessage(message)) { res in
            switch res {
            case .none:
                completion(nil)
            case .some(let error):
                completion(error)
            }
        }
    }
    
    open func sendMessage(message: ViberMessage, to: [String], _ completion: @escaping (Error?) -> Void) {
        func convertMessage(_ mes: ViberMessage) -> ViberAPIMessage {
            let sender = ViberAPI.Sender(name: name, avatar: avatar)
            switch mes {
            case let mes as Viber.TextMessage:
                return ViberAPI.TextMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, text: mes.text)
            case let mes as Viber.PictureMessage:
                return ViberAPI.PictureMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, text: mes.text, media: mes.media, thumbnail: mes.thumbnail)
            case let mes as Viber.VideoMessage:
                return ViberAPI.VideoMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, media: mes.media, size: mes.size, duration: mes.duration, thumbnail: mes.thumbnail)
            case let mes as Viber.FileMessage:
                return ViberAPI.FileMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, media: mes.media, size: mes.size, filename: mes.filename)
            case let mes as Viber.ContactMessage:
                return ViberAPI.ContactMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, contact: mes.contact)
            case let mes as Viber.LocationMessage:
                return ViberAPI.LocationMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, location: mes.location)
            case let mes as Viber.URLMessage:
                return ViberAPI.URLMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, URL: mes.URL)
            case let mes as Viber.StickerMessage:
                return ViberAPI.StickerMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, sticker_id: mes.sticker_id)
            case let mes as Viber.CarouselMessage:
                return ViberAPI.CarouselMessage(receiver: nil, broadcast_list: to, from: nil, sender: sender, tracking_data: nil, rich_media: mes.rich_media, alt_text: mes.alt_text)
            default:
                fatalError()
            }
        }
        
        api.broadcastMessage(message: convertMessage(message)) { res in
            switch res {
            case .success(let res):
                if let failed_list = res.failed_list {
                    if res.status == 0, failed_list.all({ $0.status == 0 }) {
                        completion(nil)
                    } else {
                        completion(
                            ViberBroadcastError(
                                error: ViberError(code: res.status, message: res.status_message),
                                userError: failed_list.map {
                                    ViberUserError(
                                        user: $0.receiver,
                                        error: ViberError(code: $0.status, message: $0.status_message)
                                    )
                                }
                            )
                        )
                    }
                } else {
                    if res.status == 0 {
                        completion(nil)
                    } else {
                        completion(
                            ViberBroadcastError(
                                error: ViberError(code: res.status, message: res.status_message),
                                userError: nil
                            )
                        )
                    }
                }
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    // TODO: implement rich Get Acount Info
    open func getAccountInfo(_ completion: @escaping (Result<ViberAPI.AccountInfo, Error>) -> Void) {
        api.getAccountInfo { res in completion(res) }
    }
    
    // TODO: implement rich Get User details
    open func getUserDetails(request: ViberAPI.GetUserDetailsRequest, _ completion: @escaping (Result<ViberAPI.UserDetails, Error>) -> Void) {
        api.getUserDetails(request: request) { res in completion(res) }
    }
    
    // TODO: implement rich Get Online
    open func getOnline(request: ViberAPI.GetOnlineRequest, _ completion: @escaping (Result<ViberAPI.Online, Error>) -> Void) {
        api.getOnline(request: request) { res in completion(res) }
    }
    
    // TODO: implement rich Post to Public Chat
    open func postToPublicChat(request: ViberAPI.GetUserDetailsRequest, _ completion: @escaping (Error?) -> Void) {
        api.postToPublicChat(request: request) { res in completion(res) }
    }
    
    open func parseCallback(data: Data) -> ViberAPICallback? {
        return api.parseCallback(data: data)
    }
}
