//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
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

