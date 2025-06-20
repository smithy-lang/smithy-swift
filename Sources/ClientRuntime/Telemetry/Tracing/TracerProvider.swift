//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A Tracer Provider provides implementations of Tracers.
public protocol TracerProvider: Sendable {

    /// Gets a scoped Tracer.
    ///
    /// - Parameter scope: the unique scope of the Tracer
    /// - Returns: a Tracer
    func getTracer(scope: String) -> Tracer
}
