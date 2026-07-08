//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import WaitersTestSDK

// `@retroactive` silences the retroactive-conformance warning on Swift 6+, but
// the attribute is not recognized by the Swift 5.9 compiler, so gate on it.
#if compiler(>=6.0)

extension GetWidgetInput: @retroactive Equatable {

    public static func ==(lhs: GetWidgetInput, rhs: GetWidgetInput) -> Bool {
        return lhs.stringProperty == rhs.stringProperty
    }
}

extension GetWidgetOutput: @retroactive Equatable {

    public static func ==(lhs: GetWidgetOutput, rhs: GetWidgetOutput) -> Bool {
        return lhs.booleanArrayProperty == rhs.booleanArrayProperty &&
        lhs.booleanProperty == rhs.booleanProperty &&
        lhs.children == rhs.children &&
        lhs.dataMap == rhs.dataMap &&
        lhs.stringArrayProperty == rhs.stringArrayProperty &&
        lhs.stringProperty == rhs.stringProperty
    }
}

extension WaitersClientTypes.Child: @retroactive Equatable {

    public static func ==(lhs: WaitersClientTypes.Child, rhs: WaitersClientTypes.Child) -> Bool {
        return lhs.grandchildren == rhs.grandchildren
    }
}

extension WaitersClientTypes.Grandchild: @retroactive Equatable {

    public static func ==(lhs: WaitersClientTypes.Grandchild, rhs: WaitersClientTypes.Grandchild) -> Bool {
        return lhs.name == rhs.name && lhs.number == rhs.number
    }
}

#else

extension WaitersTestSDK.GetWidgetInput: Equatable {

    public static func ==(lhs: GetWidgetInput, rhs: GetWidgetInput) -> Bool {
        return lhs.stringProperty == rhs.stringProperty
    }
}

extension WaitersTestSDK.GetWidgetOutput: Equatable {

    public static func ==(lhs: GetWidgetOutput, rhs: GetWidgetOutput) -> Bool {
        return lhs.booleanArrayProperty == rhs.booleanArrayProperty &&
        lhs.booleanProperty == rhs.booleanProperty &&
        lhs.children == rhs.children &&
        lhs.dataMap == rhs.dataMap &&
        lhs.stringArrayProperty == rhs.stringArrayProperty &&
        lhs.stringProperty == rhs.stringProperty
    }
}

extension WaitersTestSDK.WaitersClientTypes.Child: Equatable {

    public static func ==(lhs: WaitersClientTypes.Child, rhs: WaitersClientTypes.Child) -> Bool {
        return lhs.grandchildren == rhs.grandchildren
    }
}

extension WaitersTestSDK.WaitersClientTypes.Grandchild: Equatable {

    public static func ==(lhs: WaitersClientTypes.Grandchild, rhs: WaitersClientTypes.Grandchild) -> Bool {
        return lhs.name == rhs.name && lhs.number == rhs.number
    }
}

#endif
