namespace com.test

use aws.protocols#restJson1

service Lambda {
    operations: [ListFunctions, ListFunctions2]
}

@paginated(
    inputToken: "Marker",
    outputToken: "NextMarker",
    pageSize: "MaxItems",
    items: "Functions"
)
@readonly
@http(method: "GET", uri: "/functions", code: 200)
operation ListFunctions {
    input: ListFunctionsRequest,
    output: ListFunctionsResponse
}

structure ListFunctionsRequest {
    @httpQuery("FunctionVersion")
    FunctionVersion: String,
    @httpQuery("Marker")
    Marker: String,
    @httpQuery("MasterRegion")
    MasterRegion: String,
    @httpQuery("MaxItems")
    MaxItems: Integer
}

structure ListFunctionsResponse {
    Functions: FunctionConfigurationList,
    NextMarker: String
}

list FunctionConfigurationList {
    member: FunctionConfiguration
}

structure FunctionConfiguration {
    FunctionName: String
}

@paginated(
    inputToken: "Marker",
    outputToken: "NextMarker",
    pageSize: "MaxItems"
)
@readonly
@http(method: "GET", uri: "/functions2", code: 200)
operation ListFunctions2 {
    input: ListFunctionsRequest2,
    output: ListFunctionsResponse2
}

structure ListFunctionsRequest2 {
    @httpQuery("FunctionVersion")
    FunctionVersion: String,
    @httpQuery("Marker")
    Marker: String,
    @httpQuery("MasterRegion")
    MasterRegion: String,
    @httpQuery("MaxItems")
    MaxItems: Integer
}

structure ListFunctionsResponse2 {
    Functions: FunctionConfigurationList,
    NextMarker: String
}