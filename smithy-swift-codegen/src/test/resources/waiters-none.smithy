namespace com.test

use smithy.waiters#waitable
use aws.protocols#restXml

@restXml
service TestHasNoWaiters {
    operations: [NoWaiting]
}

@http(method: "HEAD", uri: "/no_waiting", code: 200)
operation NoWaiting {
    input: NoWaitingRequest
    output: NoWaitingResponse
}

structure NoWaitingRequest {}
structure NoWaitingResponse {}
