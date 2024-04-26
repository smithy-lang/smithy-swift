namespace com.test

use aws.protocols#restXml

@restXml
service Lambda {
    operations: [ListFunctions, ListFunctions2, ListFunctions3]
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

// Suppress warning to mimic DynamoDB using map as pagination token.
@suppress(["PaginatedTrait.WrongShapeType"])
@paginated(
    inputToken: "mapToken",
    outputToken: "nextMapToken",
    pageSize: "maxItems"
)
@readonly
@http(method: "PUT", uri: "/function4", code: 200)
operation ListFunctions3 {
    input: ListFunctions3Input,
    output: ListFunctions3Output
}

structure ListFunctions3Input {
    @httpHeader("MaxItems")
    maxItems: Integer
    mapToken: PaginationMapInputToken
}

map PaginationMapInputToken {
    key: String,
    value: NestedInputTokenValue
}

structure NestedInputTokenValue {
    doublyNestedValue: DoublyNestedInputTokenValue
    doublyNextedUnion: InputPaginationUnion
}

structure DoublyNestedInputTokenValue {
    a: String
}

union InputPaginationUnion {
    a: Integer
    b: String
}

structure ListFunctions3Output {
    nextMapToken: PaginationMapOutputToken
}

map PaginationMapOutputToken {
    key: String,
    value: Integer
}