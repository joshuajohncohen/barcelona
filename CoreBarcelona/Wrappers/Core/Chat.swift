//
//  Chat.swift
//  imcore-rest
//
//  Created by Eric Rabil on 7/23/20.
//  Copyright © 2020 Eric Rabil. All rights reserved.
//

import Foundation
import IMSharedUtilities
import IMCore
import NIO

public enum ChatStyle: UInt8 {
    case group = 0x2b
    case single = 0x2d
}

public class QueryFailedError: Error {
    init() {
        
    }
}

public protocol BulkChatRepresentatable {
    var chats: [Chat] { get set }
}

public struct BulkChatRepresentation: Codable, BulkChatRepresentatable {
    public init(_ chats: [IMChat]) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    public init(_ chats: ArraySlice<IMChat>) {
        self.chats = chats.map {
            Chat($0)
        }
    }
    
    public init(_ chats: [Chat]) {
        self.chats = chats
    }
    
    public var chats: [Chat]
}

public struct ChatIDRepresentation: Codable {
    public init(chat: String) {
        self.chat = chat
    }
    
    public var chat: String
}

public enum MessagePartType: String, Codable {
    case text
    case attachment
    case breadcrumb
}
//
//public enum MessagePartAttributes: String, Codable {
//    
//}

public struct MessagePart: Codable {
    public var type: MessagePartType
    public var details: String
    public var attributes: [TextPartAttribute]?
}

public struct CreateMessage: Codable {
    public var subject: String?
    public var parts: [MessagePart]
    public var isAudioMessage: Bool?
    public var flags: CLongLong?
    public var ballonBundleID: String?
    public var payloadData: String?
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToPart: String?
}

public struct CreatePluginMessage: Codable {
    public var extensionData: MessageExtensionsData
    public var attachmentID: String?
    public var bundleID: String
    public var expressiveSendStyleID: String?
    public var threadIdentifier: String?
    public var replyToPart: String?
}

public protocol MessageIdentifiable {
    var id: String { get set }
}

public protocol ChatConfigurationRepresentable {
    var readReceipts: Bool { get set }
    var ignoreAlerts: Bool { get set }
}

public struct ChatConfigurationRepresentation: Codable, ChatConfigurationRepresentable {
    public var id: String
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
}

public struct DeleteMessage: Codable, MessageIdentifiable {
    public var id: String
    public var parts: [Int]?
}

extension MessageIdentifiable {
    public func chat() -> EventLoopFuture<Chat?> {
        Chat.chat(forMessage: id)
    }
}

public struct DeleteMessageRequest: Codable {
    public var messages: [DeleteMessage]
}

private func flagsForCreation(_ creation: CreateMessage, transfers: [String]) -> FullFlagsFromMe {
    if let _ = creation.ballonBundleID { return .richLink }
    if let audio = creation.isAudioMessage { if audio { return .audioMessage } }
    if transfers.count > 0 || creation.parts.contains(where: { $0.type == .attachment }) { return .attachments }
    return .textOrPluginOrStickerOrImage
}

private extension String {
    func substring(trunactingFirst prefix: Int) -> Substring {
        self.suffix(from: self.index(startIndex, offsetBy: prefix))
    }
    
    func nsRange(of string: String) -> NSRange {
        (self as NSString).range(of: string)
    }
    
    var isBusinessBundleID: Bool {
        self == "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension"
    }
}

private extension NSAttributedString {
    func range(of string: String) -> NSRange {
        self.string.nsRange(of: string)
    }
}

public struct Chat: Codable, ChatConfigurationRepresentable {
    public init(_ backing: IMChat) {
        joinState = backing.joinState
        roomName = backing.roomName
        displayName = backing.displayName
        id = backing.id
        participants = backing.recentParticipantHandleIDs
        unreadMessageCount = backing.unreadMessageCount
        messageFailureCount = backing.messageFailureCount
        service = backing.account?.service?.id
        lastMessage = backing.lastFinishedMessage?.description(forPurpose: 0x2, inChat: backing, senderDisplayName: backing.lastMessage?.sender._displayNameWithAbbreviation)
        lastMessageTime = (backing.lastFinishedMessage?.time.timeIntervalSince1970 ?? 0) * 1000
        style = backing.chatStyle
        readReceipts = backing.readReceipts
        ignoreAlerts = backing.ignoreAlerts
    }
    
    public static func chat(forMessage id: String) -> EventLoopFuture<Chat?> {
        IMChat.chat(forMessage: id).map {
            if let chat = $0 {
                return Chat(chat)
            } else {
                return nil
            }
        }
    }
    
    public var id: String
    public var joinState: Int64
    public var roomName: String?
    public var displayName: String?
    public var participants: [String]
    public var unreadMessageCount: UInt64
    public var messageFailureCount: UInt64
    public var service: IMServiceStyle?
    public var lastMessage: String?
    public var lastMessageTime: Double
    public var style: UInt8
    public var readReceipts: Bool
    public var ignoreAlerts: Bool
    
    mutating func setTimeSortedParticipants(participants: [HandleTimestampRecord]) {
        self.participants = participants.map {
            $0.handle_id
        }.including(array: self.participants)
    }
    
    public var imChat: IMChat {
        IMChat.resolve(withIdentifier: id)!
    }
    
    public func startTyping() {
        if imChat.localTypingMessageGUID == nil {
            imChat.setValue(NSString.stringGUID(), forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xc, error: nil, guid: imChat.localTypingMessageGUID, subject: nil)
            imChat._sendMessage(message, adjustingSender: true, shouldQueue: false)
        }
    }
    
    public func stopTyping() {
        if let typingGUID = imChat.localTypingMessageGUID {
            imChat.setValue(nil, forKey: "_typingGUID")
            let message = IMMessage(sender: nil, time: nil, text: nil, fileTransferGUIDs: nil, flags: 0xd, error: nil, guid: typingGUID, subject: nil)
            imChat.sendMessage(message)
        }
    }
    
    public func messages(before: String? = nil, limit: UInt64? = nil) -> EventLoopFuture<[ChatItem]> {
        if ERBarcelonaManager.isSimulation {
            let guids: [String] = imChat.chatItemRules._items().compactMap { item in
                if let chatItem = item as? IMChatItem {
                    return chatItem._item()?.guid
                } else if let item = item as? IMItem {
                    return item.guid
                }
                
                return nil
            }
            
            return IMMessage.messages(withGUIDs: guids, in: self.id, on: messageQuerySystem.next()).map { messages -> [ChatItem] in
                messages.sorted {
                    guard case .message(let message1) = $0, case .message(let message2) = $1 else {
                        return false
                    }
                    
                    return message1.time! > message2.time!
                }
            }
        }
        
        return DBReader.shared.rowIDs(forIdentifier: imChat.chatIdentifier).flatMap { ROWIDs -> EventLoopFuture<[String]> in
            let guidFetchTracker = ERTrack(log: .default, name: "Chat.swift:messages Loading newest guids for chat", format: "ChatID: %{public}s ROWIDs: %@", self.id, ROWIDs)
            
            return DBReader.shared.newestMessageGUIDs(inChatROWIDs: ROWIDs, beforeMessageGUID: before, limit: Int(limit ?? 100)).map {
                guidFetchTracker()
                return $0
            }
        }.flatMap { guids -> EventLoopFuture<[ChatItem]> in
            IMMessage.messages(withGUIDs: guids, in: self.id, on: messageQuerySystem.next())
        }.map { messages -> [ChatItem] in
            messages.sorted {
                guard case .message(let message1) = $0, case .message(let message2) = $1 else {
                    return false
                }
                
                return message1.time! > message2.time!
            }
        }
    }
    
    public func delete(message: DeleteMessage, on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let guid = message.id, parts = message.parts ?? []
        let fullMessage = parts.count == 0
        
        return IMMessage.imMessage(withGUID: guid, on: eventLoop).map { message -> Void in
            guard let message = message else {
                return
            }
            
            if fullMessage {
                IMDaemonController.shared()!.deleteMessage(withGUIDs: [guid], queryID: NSString.stringGUID())
            } else {
                let chatItems = message._imMessageItem._newChatItems()!
                
                let items: [IMChatItem] = parts.compactMap {
                    if chatItems.count <= $0 { return nil }
                    return chatItems[$0]
                }
                
                let newItem = self.imChat.chatItemRules._item(withChatItemsDeleted: items, fromItem: message._imMessageItem)!
                
                IMDaemonController.shared()!.updateMessage(newItem)
            }
        }
    }
    
    public func send(message options: CreatePluginMessage, on eventLoop: EventLoop? = nil) -> EventLoopFuture<BulkMessageRepresentation> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        let promise = eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        var payloadData = options.extensionData
        payloadData.data = payloadData.data ?? payloadData.synthesizedData
        
        var pendingThreadIdentifier: EventLoopFuture<String?>?
        
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let threadIdentifier = options.threadIdentifier {
                pendingThreadIdentifier = eventLoop.makeSucceededFuture(threadIdentifier)
            } else if let replyToPart = options.replyToPart {
                pendingThreadIdentifier = IMChatItem.resolveThreadIdentifier(forIdentifier: replyToPart, on: eventLoop)
            }
        }
        
        if pendingThreadIdentifier == nil {
            pendingThreadIdentifier = eventLoop.makeSucceededFuture(nil)
        }
        
        pendingThreadIdentifier!.whenSuccess { threadIdentifier in
            ERAttributedString(forExtensionOptions: options, on: eventLoop).whenSuccess { baseString in
                let messageString = NSMutableAttributedString(attributedString: baseString.string)
                messageString.append(.init(string: IMBreadcrumbCharacterString))
                        
                messageString.addAttributes([
                    MessageAttributes.writingDirection: -1,
                    MessageAttributes.breadcrumbOptions: 0,
                    MessageAttributes.breadcrumbMarker: options.extensionData.layoutInfo?.caption ?? "Message Extension"
                ], range: messageString.range(of: IMBreadcrumbCharacterString))
                
                let messageItem = IMMessageItem.init(sender: nil, time: nil, guid: nil, type: 0)!
                
                messageItem.body = messageString
                messageItem.balloonBundleID = options.bundleID
                messageItem.payloadData = payloadData.archive
                messageItem.flags = 5
                messageItem.service = IMServiceStyle.iMessage.service?.internalName
                messageItem.setValue(baseString.transferGUIDs, forKey: "fileTransferGUIDs")
                
                if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                    messageItem.setThreadIdentifier(threadIdentifier)
                }

                ERApplyMessageExtensionQuirks(toMessageItem: messageItem, inChatID: self.id, forOptions: options)
                
                guard let message = IMMessage.message(fromUnloadedItem: messageItem) else {
                    promise.fail(BarcelonaError(code: 500, message: "Failed to construct IMMessage from IMMessageItem"))
                    return
                }
                
                DispatchQueue.main.async {
                    self.imChat._sendMessage(message, adjustingSender: true, shouldQueue: true)

                    ERIndeterminateIngestor.ingest(messageLike: message, in: self.id).flatMapThrowing { message in
                        guard let message = message else {
                            throw BarcelonaError(code: 500, message: "Failed to construct represented message")
                        }

                        return BulkMessageRepresentation([message])
                    }.cascade(to: promise)
                }
            }
        }
        
        return promise.futureResult
    }
    
    public func send(message createMessage: CreateMessage, on eventLoop: EventLoop? = nil) -> EventLoopFuture<BulkMessageRepresentation> {
        let eventLoop = eventLoop ?? messageQuerySystem.next()
        let promise = eventLoop.makePromise(of: BulkMessageRepresentation.self)
        
        var pendingThreadIdentifier: EventLoopFuture<String?>?
        
        if #available(iOS 14, macOS 10.16, watchOS 7, *) {
            if let threadIdentifier = createMessage.threadIdentifier {
                pendingThreadIdentifier = eventLoop.makeSucceededFuture(threadIdentifier)
            } else if let replyToPart = createMessage.replyToPart {
                pendingThreadIdentifier = IMChatItem.resolveThreadIdentifier(forIdentifier: replyToPart, on: eventLoop)
            }
        }
        
        if pendingThreadIdentifier == nil {
            pendingThreadIdentifier = eventLoop.makeSucceededFuture(nil)
        }
        
        
        pendingThreadIdentifier!.whenSuccess { threadIdentifier in
            ERAttributedString(from: createMessage.parts, on: eventLoop).whenSuccess { result in
                let text = result.string
                let fileTransferGUIDs = result.transferGUIDs
                
                if text.length == 0 {
                    promise.fail(BarcelonaError(code: 400, message: "Cannot send an empty message"))
                    return
                }
                
                var subject: NSMutableAttributedString?
                
                if let rawSubject = createMessage.subject {
                    subject = NSMutableAttributedString(string: rawSubject)
                }
                
                /** Creates a base message using the computed attributed string */
                
                var message: IMMessage!

                if #available(iOS 14, macOS 10.16, watchOS 7, *) {
                    message = IMMessage.instantMessage(withText: text, messageSubject: subject, fileTransferGUIDs: fileTransferGUIDs, flags: flagsForCreation(createMessage, transfers: fileTransferGUIDs).rawValue, threadIdentifier: threadIdentifier)
                } else {
                    message = IMMessage.instantMessage(withText: text, messageSubject: subject, fileTransferGUIDs: fileTransferGUIDs, flags: flagsForCreation(createMessage, transfers: fileTransferGUIDs).rawValue)
                }

                DispatchQueue.main.async {
                    /** Split the base message into individual messages if it contains rich link(s) */
                    guard let messages = message.messagesBySeparatingRichLinks() as? [IMMessage] else {
                        print("Malformed message result when separating rich links at \(message?.guid ?? "nil")")
                        return
                    }
                    
                    messages.forEach { message in
                        self.imChat._sendMessage(message, adjustingSender: true, shouldQueue: true)
                    }
                    
                    messages.bulkRepresentation(in: self.id).cascade(to: promise)
                }
            }
        }
        
        return promise.futureResult
    }
}

public extension Chat {
    var participantIDs: BulkHandleIDRepresentation {
        BulkHandleIDRepresentation(handles: participants)
    }
}

func chatToRepresentation(_ backing: IMChat, skinny: Bool = false) -> Chat {
    return .init(backing)
}