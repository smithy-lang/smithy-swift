//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes

/// A Tracer Provider provides implementations of Tracers.
public protocol TracerProvider {

    /// Gets a scoped Tracer.
    ///
    /// - Parameter scope: the unique scope of the Tracer
    /// - Parameter attributes: instrumentation scope attributes
    /// - Returns: a Tracer
    func getTracer(scope: String, attributes: Attributes?) -> Tracer
}
