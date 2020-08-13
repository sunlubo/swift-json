//
//  JSONError.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/12.
//  Copyright © 2020 sun. All rights reserved.
//

public enum JSONError: Swift.Error {
  case invalidJSON
  case invalidObject
  case colonRequired
  case unexpectedComma
  case invalidValue
  case stringNotStarted
  case stringNotClosed
  case invalidEscape
  case unexpectedControlCharacter
  case numberWithLeadingZero
  case numberWithInvalidFraction
  case numberWithInvalidExponent
  case invalidBool
  case invalidNull
  case unexpectedEndOfFile
}
