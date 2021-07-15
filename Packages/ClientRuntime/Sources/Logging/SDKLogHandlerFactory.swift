//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import Logging

public protocol SDKLogHandlerFactory {
    var label: String { get }
    func construct(label: String) -> LogHandler
}
