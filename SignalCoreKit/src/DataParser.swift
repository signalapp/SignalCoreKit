//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

public enum SSKDataParserError: Error {
    case overflow(description : String)
}

// MARK: - SSKDataParser

@objc public class SSKDataParser: NSObject {

    private let data: Data
    private var cursor: UInt = 0

    @objc public init(data: Data) {
        self.data = data
    }

    @objc public func nextData(length: UInt, name: String?=nil) throws -> Data {
        guard cursor + length <= data.count else {
            guard let name = name else {
                throw SSKDataParserError.overflow(description: "\(logTag) invalid data read")
            }
            throw SSKDataParserError.overflow(description: "\(logTag) invalid data read: \(name)")
        }

        let endIndex = cursor + length
        let result = data.subdata(in: Int(cursor)..<Int(endIndex))
        cursor += length
        return result
    }

    public func nextByte(name: String?=nil) throws -> UInt8 {
        let subdata = try nextData(length: 1, name: name)
        return subdata[0]
    }

    @objc public func remainder(name: String?=nil) throws -> Data {
        return try nextData(length: UInt(data.count) - cursor, name: name)
    }

    @objc public var isEmpty: Bool {
        return data.count == cursor
    }
}
