import Foundation

enum HttpMethod: String {
    case unknown = "Unknown"
    case get = "GET"
    case post = "POST"
    case head = "HEAD"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

class NetworkingConfiguration {
    public let url: URL
    public let baseUrl: URL
    public let urlString: String
    public let httpMethod: HttpMethod
    public let headers: [:]
    public let allowsCellularAccess: Bool
    public let sharedContainerIdentifier: String
    public let requestSerializer: URLRequestSerializer
    public let interceptors: [NetworkingRequestInterceptor]
    public let responseSerializer: URLResponseSerializer

}
