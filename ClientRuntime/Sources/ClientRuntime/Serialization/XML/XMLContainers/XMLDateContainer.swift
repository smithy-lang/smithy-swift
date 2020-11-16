//
//  XMLDateContainer.swift
//  ClientRuntime
//
// TODO:: Add copyrights
//

import Foundation

struct XMLDateContainer: Equatable {

    enum Format: Equatable {
        case secondsSince1970
        case millisecondsSince1970
        case iso8601
        case formatter(DateFormatter)
    }

    let unboxed: Date
    let format: Format

    init(_ unboxed: Date, format: Format) {
        self.unboxed = unboxed
        self.format = format
    }

    init?(secondsSince1970 string: String) {
        guard let seconds = TimeInterval(string) else {
            return nil
        }
        let unboxed = Date(timeIntervalSince1970: seconds)
        self.init(unboxed, format: .secondsSince1970)
    }

    init?(millisecondsSince1970 string: String) {
        guard let milliseconds = TimeInterval(string) else {
            return nil
        }
        let unboxed = Date(timeIntervalSince1970: milliseconds / 1000.0)
        self.init(unboxed, format: .millisecondsSince1970)
    }

    init?(iso8601 string: String) {
        if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
            guard let unboxed = _iso8601Formatter.date(from: string) else {
                return nil
            }
            self.init(unboxed, format: .iso8601)
        } else {
            fatalError("ISO8601DateFormatter is unavailable on this platform.")
        }
    }

    init?(xmlString: String, formatter: DateFormatter) {
        guard let date = formatter.date(from: xmlString) else {
            return nil
        }
        self.init(date, format: .formatter(formatter))
    }

    func xmlString(format: Format) -> String {
        switch format {
        case .secondsSince1970:
            let seconds = unboxed.timeIntervalSince1970
            return seconds.description
        case .millisecondsSince1970:
            let milliseconds = unboxed.timeIntervalSince1970 * 1000.0
            return milliseconds.description
        case .iso8601:
            if #available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *) {
                return _iso8601Formatter.string(from: self.unboxed)
            } else {
                fatalError("ISO8601DateFormatter is unavailable on this platform.")
            }
        case let .formatter(formatter):
            return formatter.string(from: unboxed)
        }
    }
}

extension XMLDateContainer: XMLSimpleContainer {
    var isNull: Bool {
        return false
    }

    var xmlString: String? {
        return xmlString(format: format)
    }
}

extension XMLDateContainer: CustomStringConvertible {
    var description: String {
        return unboxed.description
    }
}

// swiftlint:disable identifier_name
/// Shared ISO8601 Date Formatter
/// NOTE: This value is implicitly lazy and _must_ be lazy. We're compiled
/// against the latest SDK (w/ ISO8601DateFormatter), but linked against
/// whichever Foundation the user has. ISO8601DateFormatter might not exist, so
/// we better not hit this code path on an older OS.
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
var _iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = .withInternetDateTime
    return formatter
}()
