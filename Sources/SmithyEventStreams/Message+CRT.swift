//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum SmithyEventStreamsAPI.MessageType
import struct SmithyEventStreamsAPI.Message
import AwsCommonRuntimeKit


extension Message {
    /// Parses the protocol level headers into a `MessageType`
    public func type() throws -> MessageType {
        let headersByName = Dictionary(grouping: headers, by: \.name)
        // look for messageType header
        guard let messageTypeHeader = headersByName[":message-type"]?.first,
              case let .string(messageType) = messageTypeHeader.value else {
            throw EventStreamError.invalidMessage("Invalid `event` message: `:message-type` header is missing")
        }

        switch messageType {
        case "event":
            guard let eventTypeHeader = headersByName[":event-type"]?.first,
                    case let .string(eventType) = eventTypeHeader.value else {
                throw EventStreamError.invalidMessage("Invalid `event` message: `:event-type` header is missing")
            }

            let contentType: String?
            if let contentTypeHeader = headersByName[":content-type"]?.first,
                    case let .string(ct) = contentTypeHeader.value {
                contentType = ct
            } else {
                contentType = nil
            }
            return .event(.init(eventType: eventType, contentType: contentType))
        case "exception":
            guard let exceptionTypeHeader = headersByName[":exception-type"]?.first,
                    case let .string(exceptionType) = exceptionTypeHeader.value else {
                throw EventStreamError.invalidMessage("""
                Invalid `exception` message: `:exception-type` header is missing
                """)
            }

            let contentType: String?
            if let contentTypeHeader = headersByName[":content-type"]?.first,
                    case let .string(ct) = contentTypeHeader.value {
                contentType = ct
            } else {
                contentType = nil
            }
            return .exception(.init(exceptionType: exceptionType, contentType: contentType))
        case "error":
            guard let errorCodeHeader = headersByName[":error-code"]?.first,
                    case let .string(errorCode) = errorCodeHeader.value else {
                throw EventStreamError.invalidMessage("Invalid `error` message: `:error-code` header is missing")
            }

            let message: String?
            if let messageHeader = headersByName[":error-message"]?.first,
                    case let .string(msg) = messageHeader.value {
                message = msg
            } else {
                message = nil
            }
            return .error(.init(errorCode: errorCode, message: message))
        default:
            return .unknown(messageType: messageType)
        }
    }
}

extension Message {

    func toCRTMessage() -> EventStreamMessage {
        let crtHeaders = headers.map { header in
            header.toCRTHeader()
        }
        return EventStreamMessage(headers: crtHeaders, payload: payload)
    }
}
