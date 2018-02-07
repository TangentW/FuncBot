//
//  Message.swift
//  FuncBot
//
//  Created by Tangent on 05/02/2018.
//

import Foundation

public protocol IncomingMessage {
    init?(jsonString: String)
}

public enum Message {
    static var hubotId = ""
}

// MARK: - Incoming
public extension Message {
    struct Normal: Codable, IncomingMessage {
        let createdTs: Date
        let image: String?
        let key: String
        let referKey: String?
        let subtype: String
        let text: String
        let toUid: String?
        let type: MsgType
        let uid: String
        let vchannelId: String
        
        enum CodingKeys: String, CodingKey {
            case createdTs = "created_ts"
            case image
            case key
            case referKey = "refer_key"
            case subtype
            case text
            case toUid = "to_uid"
            case type
            case uid
            case vchannelId = "vchannel_id"
        }
        
        public init?(jsonString: String) {
            guard
                let jsonData = jsonString.data(using: .utf8),
                let typeString: String = jsonData.json?["type"],
                MsgType(rawValue: typeString) != nil,
                let uid: String = jsonData.json?["uid"],
                uid != Message.hubotId
                else { return nil }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            do {
                self = try decoder.decode(Normal.self, from: jsonData)
            } catch let error {
                print("JSON parse error: \(error)")
                return nil
            }
        }
    }
}

public extension Message.Normal {
    enum MsgType: String, Codable {
        case message
        case channelMessage = "channel_message"
    }
}

// MARK: - Outgoing
public extension Message {
    struct Outgoing {
        let type: MsgType
        let vchannelId: String
        let text: String
        let referKey: String?
        let callId: Int
        
        init(type: MsgType, vchannelId: String, text: String, referKey: String? = nil) {
            self.type = type
            self.vchannelId = vchannelId
            self.text = text
            self.referKey = referKey
            callId = Outgoing._identifier
        }
        
        var dic: [String: Any] {
            let referKey: Any = self.referKey ?? NSNull()
            return [
                "vchannel_id": vchannelId,
                "text": text,
                "refer_key": referKey,
                "call_id": callId
            ].merging(type.dic) { a, _ in a }
        }
        
        var jsonString: String? {
            do {
                let data = try JSONSerialization.data(withJSONObject: dic, options: [])
                return String(data: data, encoding: .utf8)
            } catch let error {
                print("Parse Message error: \(error)")
                return nil
            }
        }
    }
}

public extension Message.Outgoing {
    enum MsgType {
        case P2P(to: String)
        case channel(to: String)
        
        var dic: [String: Any] {
            switch  self {
            case .P2P(let uid):
                return ["type": "message", "to_uid": uid]
            case .channel(let channelId):
                return ["type": "channel_message", "channel_id": channelId]
            }
        }
    }
}

private extension Message.Outgoing {
    static var _identifierPool: Int = 0
    static let _identifierPoolLock = NSRecursiveLock()
    static var _identifier: Int {
        defer {
            _identifierPoolLock.lock()
            _identifierPool += 1
            if _identifierPool == Int.max {
                _identifierPool = 0
            }
            _identifierPoolLock.unlock()
        }
        return _identifierPool
    }
}

// MARK: - IO
public extension Message {
    static func filter<T>(to type: T.Type) -> (String) -> IO<T> where T: IncomingMessage {
        return { jsonString in
            return IO { send in
                if let message = T(jsonString: jsonString) {
                    send(message)
                }
            }
        }
    }
    
    static func replyBindText(refer: Bool = false, _ fun: @escaping (String) -> IO<String>) -> (Message.Normal) -> IO<Message.Outgoing> {
        return { incoming in
            fun(incoming.text).map { text in
                let type: Message.Outgoing.MsgType = incoming.toUid == nil ? .channel(to: incoming.vchannelId) : .P2P(to: incoming.uid)
                return Outgoing(type: type, vchannelId: incoming.vchannelId, text: text, referKey: refer ? incoming.key : nil)
            }
        }
    }
    
    static func replyMapText(refer: Bool = false, _ fun: @escaping (String) -> String?) -> (Message.Normal) -> IO<Message.Outgoing> {
        return replyBindText(refer: refer) {
            guard let value = fun($0) else { return IO.never }
            return IO.return(value)
        }
    }
}

