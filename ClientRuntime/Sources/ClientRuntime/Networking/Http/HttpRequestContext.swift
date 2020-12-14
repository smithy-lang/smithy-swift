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

public struct HttpRequestContext {
    var executionContext: Attributes
    
    public init(executionContext:Attributes) {
        self.executionContext = executionContext
    }
    
    func getPath() -> String {
         return executionContext.get(key: AttributeKey<String>(name: "Path"))!
    }
    
    func getMethod() -> HttpMethodType {
        return executionContext.get(key: AttributeKey<HttpMethodType>(name: "Method"))!
    }
    
    func getEncoder() -> RequestEncoder {
        return executionContext.get(key: AttributeKey<RequestEncoder>(name: "Encoder"))!
    }
}

public class HttpRequestContextBuilder {
    
    public init() {}

    var attributes: Attributes = Attributes()
    let encoder = AttributeKey<RequestEncoder>(name: "Encoder")
    let method = AttributeKey<HttpMethodType>(name: "Method")
    let path = AttributeKey<String>(name: "Path")
    let operation = AttributeKey<String>(name: "Operation")
    let serviceName = AttributeKey<String>(name: "ServiceName")

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T>(key: AttributeKey<T>,
                 value: T,
                attributes: Attributes) -> HttpRequestContextBuilder {
        self.attributes.set(key: key, value: value)

        return self
    }
    
    @discardableResult
    public func withEncoder(value: RequestEncoder) -> HttpRequestContextBuilder {
        self.attributes.set(key: encoder, value: value)
        return self
    }
    
    @discardableResult
    public func withMethod(value: HttpMethodType) -> HttpRequestContextBuilder {
        self.attributes.set(key: method, value: value)
        return self
    }
    
    @discardableResult
    public func withPath(value: String) -> HttpRequestContextBuilder {
        self.attributes.set(key: path, value: value)
        return self
    }
    
    @discardableResult
    public func withOperation(value: String) -> HttpRequestContextBuilder {
        self.attributes.set(key: operation, value: value)
        return self
    }
    
    @discardableResult
    public func withServiceName(value: String) -> HttpRequestContextBuilder {
        self.attributes.set(key: serviceName, value: value)
        return self
    }

    public func build() -> HttpRequestContext {
        return HttpRequestContext(executionContext: attributes)
    }
}
