/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit
import struct Foundation.URL
import struct Foundation.Data

public enum HttpBody {
    case data(Data?)
    case streamSource(StreamSourceProvider)
    case streamSink(StreamSinkProvider)
    case none
}

extension HttpBody: Equatable {
    public static func == (lhs: HttpBody, rhs: HttpBody) -> Bool {
        switch (lhs, rhs) {
        case (let .data(unwrappedlhsData), let .data(unwrappedRhsData)):
            return unwrappedlhsData == unwrappedRhsData
        case (.streamSource, .streamSource):
            return false
        case (.streamSink, .streamSink):
            return false
        case (.none, .none):
            return true
        default:
            return false
        }
    }
}

public extension HttpBody {

    static var empty: HttpBody {
        .data(nil)
    }
}
