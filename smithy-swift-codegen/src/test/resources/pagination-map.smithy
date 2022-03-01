namespace com.test

use aws.protocols#awsJson1_1

@awsJson1_1
service TestService {
    operations: [PaginatedMap]
}

@readonly
@paginated(inputToken: "nextToken", outputToken: "inner.token",
           pageSize: "maxResults", items: "inner.mapItems")
@http(method: "GET", uri: "/foos", code: 200)
operation PaginatedMap {
    input: GetFoosInput,
    output: GetFoosOutput
}
structure GetFoosInput {
    @httpHeader("maxResults")
    maxResults: Integer,
    @httpHeader("nextToken")
    nextToken: String
}
structure Inner {
    token: String,
    @required
    mapItems: StringMap
}
structure GetFoosOutput {
    inner: Inner
}

map StringMap {
    key: String,
    value: Integer
}