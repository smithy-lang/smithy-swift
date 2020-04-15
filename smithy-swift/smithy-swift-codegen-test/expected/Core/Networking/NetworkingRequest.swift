import Foundation

typealias NetworkingUploadProgressBlock = (bytesSent: Int, totalBytesSent: Int, totalBytesExpectedToSend)
typealias NetworkingDownloadProgressBlock = (bytesWritten: Int, totalBytesWritten: Int, totalBytesExpectedToWrite)

class NetworkingRequest: NetworkingConfiguration {

    public let parameters: [:]
    public let uploadingFileUrl: URL
    public let downloadingFileUrl: URL
    public let shouldWriteDirectly: Bool
    public let uploadProgress: NetworkingUploadProgressBlock
    public let downloadProgress: NetworkingDownloadProgressBlock
    public let task: URLSessionTask
    public let isCancelled: Bool

    func assignProperties(NetworkingConfiguration configuration)
    func cancel()
    func pause()
}