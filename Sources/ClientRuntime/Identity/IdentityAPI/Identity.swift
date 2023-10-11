//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Base protocol for all identity types
public protocol Identity {
    var expiration: Date? { get }
}

// Identity v. IdentityT v. IdentityKind
// - Identity is the protocol that all identity types must conform to.
// - IdentityT is the associated type / generic type name used by protocols like IdentityResolver and Signer.
// - IdentityKind is the enum that's used by IdentityResolverConfiguration to return correct kind of identity resolver
//   for the given auth scheme. E.g., SigV4AuthScheme has idKind field as .aws. And identityResolver method in SigV4AuthScheme
//   returns an identity resolver that returns identity of type .aws. 
public enum IdentityKind: CaseIterable {
    case aws
}
