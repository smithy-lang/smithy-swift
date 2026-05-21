import AwsCommonRuntimeKit
import struct SmithyHTTPAPI.Headers

@_spi(SmithyHTTPClient)
extension Headers {
    public func toHttpHeaders() -> [HTTPHeader] {
        headers.map {
            HTTPHeader(name: $0.name, value: $0.value.joined(separator: ","))
        }
    }

    public init(httpHeaders: [HTTPHeader]) {
        self.init()
        addAll(httpHeaders: httpHeaders)
    }

    public mutating func addAll(httpHeaders: [HTTPHeader]) {
        httpHeaders.forEach {
            add(name: $0.name, value: $0.value)
        }
    }
}
