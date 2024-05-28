//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The type of the `Message`
/// It allows for the message to be decoded into the correct type.
public enum MessageType {
    /// Represents an `event` message type.
    /// All events include the headers
    /// `:message-type`: Always `event`
    /// `:event-type`: (Required) Identifies the event shape from the event stream union.
    ///     This is the member name from the union.
    /// `:content-type`: (Optional) Identifies the content type of the event payload.
    /// Example:
    /// ```
    ///     :message-type: event
    ///     :event-type: MyStruct
    ///     :content-type: application/json
    /// ```
    case event(EventParams)

    /// Represents an `exception` message type.
    /// All exceptions include the headers
    /// `:message-type`: Always `exception`
    /// `:exception-type`: (Required) Identifies the exception shape from the event stream union.
    ///     This is the member name from the union.
    /// `:content-type`: (Optional) Identifies the content type of the exception payload.
    /// Example:
    /// ```
    ///     :message-type: exception
    ///     :exception-type: FooException
    ///     :content-type: application/json
    /// ```
    case exception(ExceptionParams)

    /// Represents an `error` message type.
    /// Errors are like exceptions, but they are not modeled and have fixed
    /// set of fields.
    /// All errors include the headers
    /// `:message-type`: Always `error`
    /// `:error-code`: (Required) Identifies the error code.
    /// `:error-message`: (Optional) Identifies the error message.
    /// Example:
    /// ```
    ///     :message-type: error
    ///     :error-code: InternalServerError
    ///     :error-message: An internal server error occurred
    /// ```
    case error(ErrorParams)

    /// Represents an unknown message type.
    /// This is used when the message type is not recognized.
    case unknown(messageType: String)

    /// Represents associated type parameter for `event` message type.
    public struct EventParams {
        /// Event type name defined in the event stream union.
        /// eg. `MyStruct`
        public let eventType: String

        /// Content type of the event payload.
        /// This can be used to deserialize the payload.
        /// eg. `application/json`
        public let contentType: String?

        public init(eventType: String, contentType: String?) {
            self.eventType = eventType
            self.contentType = contentType
        }
    }

    /// Represents associated type parameter for `exception` message type.
    public struct ExceptionParams {
        /// Exception type name defined in the event stream union.
        /// eg. `FooException`
        public let exceptionType: String

        /// Content type of the exception payload.
        /// This can be used to deserialize the payload.
        /// eg. `application/json`
        public let contentType: String?

        public init(exceptionType: String, contentType: String?) {
            self.exceptionType = exceptionType
            self.contentType = contentType
        }
    }

    /// Represents associated type parameter for `error` message type.
    public struct ErrorParams {
        /// Error code which identifies the error.
        /// This may not be defined in the service model.
        /// eg. `InternalServerError`
        public let errorCode: String

        /// Human readable error message.
        /// eg. `An internal server error occurred`
        public let message: String?

        public init(errorCode: String, message: String?) {
            self.errorCode = errorCode
            self.message = message
        }
    }
}
