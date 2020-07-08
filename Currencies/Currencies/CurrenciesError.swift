//
//  CurrenciesError.swift
//  Currencies
//
//  Created by Sahara Runo on 2020/07/08.
//  Copyright © 2020 Runo Sahara. All rights reserved.
//

import Foundation

public class CurrenciesError: Error {
    public let description: String
    public let type: CurrenciesErrorType
    public let function: String
    public let line: Int

    public init(
       _ description: String,
       type: CurrenciesErrorType = .nonFatal(nil),
       function: String = #function,
       line: Int = #line
    ) {
        self.description = description
        self.type = type
        self.function = function
        self.line = line
    }
}

extension CurrenciesError: LocalizedError {
    public var errorDescription: String? {
        return "\(String(describing: self)): \(description) (\(type.description)) in \(function):L\(line)"
    }
}

// Error handling types.
public enum CurrenciesErrorType {
    // Fatal error, no need to retry. Expected flow: return to the top screen etc.
    case fatal(Error?)
    // Maybe the result will change later. Expected flow: show alerts if needed, let the user retry.
    case nonFatal(Error?)
    // No updates available. Expected flow: Do nothing, don't refresh UI etc.
    case noUpdates

    // Other types in production: cancelled by user, maintenance mode, network condition errors, etc.

    var description: String {
        switch self {
        case let .fatal(error): return "fatal(\(String(describing: error)))"
        case let .nonFatal(error): return "nonFatal(\(String(describing: error)))"
        case .noUpdates: return "noUpdates"
        }
    }
}
