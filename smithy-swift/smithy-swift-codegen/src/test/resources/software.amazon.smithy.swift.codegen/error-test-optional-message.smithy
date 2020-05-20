namespace smithy.example

use aws.protocols#awsJson1_1

@awsJson1_1
service Example {
    version: "1.0.0",
    operations: [DoSomething]
}

operation DoSomething {
    errors: [Err]
}

@error("client")
structure Err {
    message: String
}
