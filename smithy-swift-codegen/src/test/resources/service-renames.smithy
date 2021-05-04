$version: "1.0"

namespace aws.protocoltests.restjson

use aws.api#service
use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests
use aws.protocoltests.shared#GreetingStruct

@service(sdkId: "Rest Json Protocol")
@restJson1
service RestJson {
    version: "2019-12-16",
    rename: {
         "aws.protocoltests.restjson.nested#GreetingStruct": "RenamedGreeting",
    },
    operations: [
        MyTestOperation
    ]
}

@http(uri: "/MyTestOperation", method: "POST")
operation MyTestOperation {
    input: MyTestOperationResponseInput,
    output: MyTestOperationResponseOutput
}

structure MyTestOperationResponseInput {
    bar: aws.protocoltests.restjson.nested#GreetingStruct
}

structure MyTestOperationResponseOutput {
    baz: GreetingStruct
}