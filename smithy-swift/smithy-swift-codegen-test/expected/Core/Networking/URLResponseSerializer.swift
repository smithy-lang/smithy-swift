import Foundation

protocol URLResponseSerializer {
    func validateRequest(response: URLResponse, fromRequest: URLRequest, data: Any, error: Error) -> Bool
    func responseObjectForResponse(response: URLResponse, originalRequest: URLRequest, currentRequest: URLRequest, data: Any, error: Error) -> Any

}