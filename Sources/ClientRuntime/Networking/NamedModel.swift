//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Swift type that is generated from a model may conform to this protocol
/// to provide the name of the model it was based upon.
public protocol NamedModel {

    /// The non-namespaced name of the model this type is based upon.
    static var modelName: String { get }
}
