// Code generated by smithy-swift-codegen. DO NOT EDIT!

import SmithyTestUtil
import WeatherSDK

extension ListCitiesInput: Swift.Equatable {

    public static func ==(lhs: ListCitiesInput, rhs: ListCitiesInput) -> Bool {
        if lhs.nextToken != rhs.nextToken { return false }
        if lhs.pageSize != rhs.pageSize { return false }
        return true
    }
}
