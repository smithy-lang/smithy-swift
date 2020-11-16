import Foundation

protocol NetworkingRequestInterceptor {
    func interceptRequest(request: URLRequest) -> URLSessionTask
}
