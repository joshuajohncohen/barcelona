//
//  GetMessagesAfter+Handler.swift
//  BarcelonaMautrixIPC
//
//  Created by Eric Rabil on 8/23/21.
//  Copyright © 2021 Eric Rabil. All rights reserved.
//

import Barcelona
import Foundation
import Logging
import Sentry

extension GetMessagesAfterCommand: Runnable, AuthenticatedAsserting {
    var log: Logging.Logger {
        Logger(label: "GetMessagesAfterCommand")
    }
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "GetMessagesAfterCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "GetMessagesAfterCommand/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        log.debug("Getting messages for chat guid \(chat_guid) after time \(timestamp)")

        guard let chat = await chat else {
            log.debug("Unknown chat with guid \(chat_guid)")
            payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
            span.finish(status: .notFound)
            return
        }
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": chat.id
                ],
                key: "imchat"
            )
        }

        if let lastMessageTime = chat.lastMessage?.time?.timeIntervalSince1970, lastMessageTime < timestamp {
            log.debug(
                "Not processing get_messages_after because chats last message timestamp \(lastMessageTime) is before req.timestamp \(timestamp)"
            )
            payload.respond(.messages([]), ipcChannel: ipcChannel)
            span.finish()
            return
        }

        do {
            let messages = try await BLLoadChatItems(withChat: chat.chatIdentifier, onService: service, afterDate: date, limit: limit).blMessages
            payload.respond(.messages(messages), ipcChannel: ipcChannel)
            span.finish()
        } catch {
            SentrySDK.capture(error: error)
            payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
            span.finish(status: .internalError)
        }
    }
}

extension GetRecentMessagesCommand: Runnable, AuthenticatedAsserting {
    func run(payload: IPCPayload, ipcChannel: MautrixIPCChannel, chatRegistry _: CBChatRegistry) async {
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": String(describing: payload.id),
                    "command": payload.command.name.rawValue,
                ],
                key: "payload"
            )
        }
        let span = SentrySDK.startTransaction(name: "GetRecentMessagesCommand", operation: "run", bindToScope: true)
        let breadcrumb = Breadcrumb(level: .debug, category: "command")
        breadcrumb.message = "GetRecentMessagesCommand/\(payload.id ?? 0)"
        breadcrumb.type = "user"
        SentrySDK.addBreadcrumb(breadcrumb)
        guard let chat = await chat else {
            payload.fail(strategy: .chat_not_found, ipcChannel: ipcChannel)
            span.finish(status: .notFound)
            return
        }
        SentrySDK.configureScope { scope in
            scope.setContext(
                value: [
                    "id": chat.id
                ],
                key: "imchat"
            )
        }

        Task {
            do {
                let messages = try await BLLoadChatItems(withChat: chat.chatIdentifier, onService: service, limit: limit).blMessages
                payload.respond(.messages(messages), ipcChannel: ipcChannel)
                span.finish()
            } catch {
                SentrySDK.capture(error: error)
                payload.fail(strategy: .internal_error(error.localizedDescription), ipcChannel: ipcChannel)
                span.finish(status: .internalError)
            }
        }
    }
}
