namespace com.test

use smithy.waiters#waitable
use aws.protocols#restXml

@restXml
service TestHasWaiters {
    operations: [HeadBucket]
}

@readonly
@waitable(
    BucketExists: {
        documentation: "Wait until a bucket exists"
        acceptors: [
            {
                state: "success"
                matcher: {
                    success: true
                }
            }
            {
                state: "retry"
                matcher: {
                    errorType: "NotFound"
                }
            },
            {
                state: "success"
                matcher: {
                    output: {
                        path: "field1"
                        expected: "abc"
                        comparator: "stringEquals"
                    }
                }
            },
            {
                state: "success"
                matcher: {
                    inputOutput: {
                        path: "input.bucketName == output.field1"
                        expected: "true"
                        comparator: "booleanEquals"
                    }
                }
            }
        ]
        minDelay: 7
        maxDelay: 22
    }
)
@http(method: "HEAD", uri: "/bucket", code: 200)
operation HeadBucket {
    input: HeadBucketRequest,
    output: HeadBucketResponse
}

structure HeadBucketRequest {
    @httpQuery("BucketName")
    bucketName: String,
}

structure HeadBucketResponse {
    field1: String
    field2: Integer
}
