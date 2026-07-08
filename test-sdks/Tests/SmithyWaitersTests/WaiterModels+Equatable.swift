//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import WaitersTestSDK

// Fully-qualifying the protocol as `Swift.Equatable` suppresses the Swift 6
// "retroactive conformance" warning in a manner compatible with Swift 5.
// See: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md#source-compatibility

extension GetWidgetInput: Swift.Equatable {

    public static func ==(lhs: GetWidgetInput, rhs: GetWidgetInput) -> Bool {
        return lhs.stringProperty == rhs.stringProperty
    }
}

extension GetWidgetOutput: Swift.Equatable {

    public static func ==(lhs: GetWidgetOutput, rhs: GetWidgetOutput) -> Bool {
        return lhs.booleanArrayProperty == rhs.booleanArrayProperty &&
        lhs.booleanProperty == rhs.booleanProperty &&
        lhs.children == rhs.children &&
        lhs.dataMap == rhs.dataMap &&
        lhs.stringArrayProperty == rhs.stringArrayProperty &&
        lhs.stringProperty == rhs.stringProperty
    }
}

extension WaitersClientTypes.Child: Swift.Equatable {

    public static func ==(lhs: WaitersClientTypes.Child, rhs: WaitersClientTypes.Child) -> Bool {
        return lhs.grandchildren == rhs.grandchildren
    }
}

extension WaitersClientTypes.Grandchild: Swift.Equatable {

    public static func ==(lhs: WaitersClientTypes.Grandchild, rhs: WaitersClientTypes.Grandchild) -> Bool {
        return lhs.name == rhs.name && lhs.number == rhs.number
    }
}
