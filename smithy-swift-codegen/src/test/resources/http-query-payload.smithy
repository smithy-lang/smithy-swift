$version: "1.0"

namespace aws.protocoltests.restjson

use aws.api#service
use aws.protocols#restJson1
use smithy.test#httpRequestTests
use smithy.test#httpResponseTests

@service(sdkId: "Rest Json Protocol")
@restJson1
service RestJson {
    version: "2019-12-16",
    // Ensure that generators are able to handle renames.
    rename: {
        "aws.protocoltests.restjson.nested#GreetingStruct": "RenamedGreeting",
    },
    operations: [
        IgnoreQueryParamsInResponse
    ]
}
@http(uri: "/IgnoreQueryParamsInResponse", method: "GET")
operation IgnoreQueryParamsInResponse {
    output: IgnoreQueryParamsInResponseOutput
}

structure IgnoreQueryParamsInResponseOutput {
    @httpQuery("baz")
    baz: String
}