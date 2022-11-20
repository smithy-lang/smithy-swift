namespace com.test

use smithy.waiters#waitable
use aws.protocols#restJson1

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
}
