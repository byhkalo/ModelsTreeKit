//
//  Error.swift
//  SessionSwift
//
//  Created by aleksey on 14.10.15.
//  Copyright © 2015 aleksey chernish. All rights reserved.
//

import Foundation

public protocol ErrorCodesList {
  
  static func allCodes() -> [ErrorCode]
  
}

public protocol ErrorCode {
  
  var rawValue: Int { get }
  
}

public protocol ErrorDomain {
  
  var rawValue: String { get }
  
}

public struct Error: ErrorType {
  
  public var hashValue: Int {
    return (code.rawValue.hashValue + domain.rawValue.hashValue).hashValue
  }
  
  let domain: ErrorDomain
  let code: ErrorCode
  
  public init(domain: ErrorDomain, code: ErrorCode) {
    self.domain = domain
    self.code = code
  }
  
  public func localizedDescription() -> String {
    return NSLocalizedString(descriptionString(), comment: "")
  }
  
  public func fullDescription() -> String {
    return descriptionString() + ": " + localizedDescription()
  }
  
  private func descriptionString() -> String {
    return "\(domain.rawValue).\(code.rawValue)"
  }
  
}

extension Error: Hashable, Equatable {
  
}

public func ==(a: Error, b: Error) -> Bool {
  return a.code.rawValue == b.code.rawValue && a.domain.rawValue == b.domain.rawValue
}