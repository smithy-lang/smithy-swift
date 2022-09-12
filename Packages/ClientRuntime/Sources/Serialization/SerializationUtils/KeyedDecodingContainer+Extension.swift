//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
extension KeyedDecodingContainer where K: CodingKey {
    public func nestedContainerNonThrowable<NestedKey>(keyedBy type: NestedKey.Type, forKey key: KeyedDecodingContainer<K>.Key) -> KeyedDecodingContainer<NestedKey>? where NestedKey: CodingKey {
        do {
            return try nestedContainer(keyedBy: type, forKey: key)
        } catch {
            return nil
        }
    }
}
