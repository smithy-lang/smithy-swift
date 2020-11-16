import Foundation

protocol URLRequestSerializer {
    func validateRequest(request: URLRequest) -> URLSessionTask
    func serializeRequest(request: URLRequest) -> URLSessionTask
    public let headers: [:]
    public let parameters: [:]

}
