 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

public struct HttpResponseContext {
    let executionContext: Attributes
    var response: HttpResponse
    
    init(executionContext: Attributes, response: HttpResponse) {
        self.executionContext = executionContext
        self.response = response
    }
    
    func getDecoder() -> ResponseDecoder {
        return executionContext.get(key: AttributeKey<ResponseDecoder>(name: "Decoder"))! // can we do this since we know there will be a decoder? if theres not a decoder we shouldn't even be at this point to call one
    }
}

public class HttpResponseContextBuilder {
    
    public init() {}

    var attributes: Attributes = Attributes()
    var response: HttpResponse = HttpResponse()
    let decoder = AttributeKey<ResponseDecoder>(name: "Decoder")
    let operation = AttributeKey<String>(name: "Operation")
    let serviceName = AttributeKey<String>(name: "ServiceName")

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T>(key: AttributeKey<T>,
                 value: T,
                attributes: Attributes) -> HttpResponseContextBuilder {
        self.attributes.set(key: key, value: value)

        return self
    }
    
    @discardableResult
    public func withDecoder(value: ResponseDecoder) -> HttpResponseContextBuilder {
        self.attributes.set(key: decoder, value: value)
        return self
    }
    
    @discardableResult
    public func withResponse(value: HttpResponse) -> HttpResponseContextBuilder {
        self.response = value
        return self
    }
    
    @discardableResult
    public func withOperation(value: String) -> HttpResponseContextBuilder {
        self.attributes.set(key: operation, value: value)
        return self
    }
    
    @discardableResult
    public func withServiceName(value: String) -> HttpResponseContextBuilder {
        self.attributes.set(key: serviceName, value: value)
        return self
    }

    public func build() -> HttpResponseContext {
        return HttpResponseContext(executionContext: attributes, response: response)
    }
}
