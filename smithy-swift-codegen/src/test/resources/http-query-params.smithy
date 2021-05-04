$version: "1.0"

namespace com.test

use aws.api#service
use aws.protocols#restJson1

@service(sdkId: "Rest Json Protocol")
@restJson1
service Example {
    version: "2019-12-16",
    operations: [
        AllQueryStringTypes
    ]
}

@readonly
@http(uri: "/AllQueryStringTypesInput", method: "GET")
operation AllQueryStringTypes {
    input: AllQueryStringTypesInput
}

structure AllQueryStringTypesInput {
    @httpQuery("String")
    queryString: String,

    @httpQuery("StringList")
    queryStringList: StringList,

    @httpQueryParams
    queryParamsMapOfStrings: StringMap,
}

list StringList {
    member: String,
}

map StringMap {
    key: String,
    value: String,
}