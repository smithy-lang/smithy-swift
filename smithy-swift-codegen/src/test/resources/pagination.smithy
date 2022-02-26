namespace com.test

use aws.protocols#restJson1

service Lambda {
    operations: [ListFunctions, ListFunctions2]
}

@paginated(
    inputToken: "marker",
    outputToken: "nextMarker",
    pageSize: "maxItems",
    items: "functions"
)
@readonly
@http(method: "GET", uri: "/functions", code: 200)
operation ListFunctions {
    input: ListFunctionsRequest,
    output: ListFunctionsResponse
}

structure ListFunctionsRequest {
    @httpQuery("FunctionVersion")
    functionVersion: String,
    @httpQuery("Marker")
    marker: String,
    @httpQuery("MasterRegion")
    masterRegion: String,
    @httpQuery("MaxItems")
    maxItems: Integer
}

structure ListFunctionsResponse {
    functions: FunctionConfigurationList,
    nextMarker: String
}

list FunctionConfigurationList {
    member: FunctionConfiguration
}

structure FunctionConfiguration {
    functionName: String
}

@paginated(
    inputToken: "marker",
    outputToken: "nextMarker",
    pageSize: "maxItems"
)
@readonly
@http(method: "GET", uri: "/functions2", code: 200)
operation ListFunctions2 {
    input: ListFunctionsRequest2,
    output: ListFunctionsResponse2
}

structure ListFunctionsRequest2 {
    @httpQuery("FunctionVersion")
    functionVersion: String,
    @httpQuery("Marker")
    marker: String,
    @httpQuery("MasterRegion")
    masterRegion: String,
    @httpQuery("MaxItems")
    maxItems: Integer
}

structure ListFunctionsResponse2 {
    functions: FunctionConfigurationList,
    nextMarker: String
}