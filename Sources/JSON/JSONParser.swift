//
//  JSONParser.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/12.
//  Copyright © 2020 sun. All rights reserved.
//

final class JSONParser {
  var bytes: Array<UInt8>
  var index: Array<UInt8>.Index

  init<C: Collection>(bytes: C) where C.Element == UInt8 {
    self.bytes = Array(bytes)
    self.index = self.bytes.startIndex
  }

  var current: UInt8? {
    index < bytes.endIndex ? bytes[index] : nil
  }

  func advance(_ n: Int = 1) {
    bytes.formIndex(&index, offsetBy: n)
  }
}

extension JSONParser {

  func parse() throws -> JSON {
    skipWhitespace()
    guard let byte = current else {
      throw JSONError.invalidJSON
    }

    let json: JSON
    switch byte {
    case .leftBrace:
      json = try parseObject()
    case .leftBrack:
      json = try parseArray()
    default:
      throw JSONError.invalidJSON
    }

    skipWhitespace()
    if index != bytes.endIndex {
      throw JSONError.invalidJSON
    }

    return json
  }

  /// Parse the JSON object.
  ///
  ///     object := '{' whitespace | (whitespace string whitespace ':' value ','?)* '}'
  func parseObject() throws -> JSON {
    advance()
    skipWhitespace()
    var object = [String: JSON]()
    while let byte = current {
      switch byte {
      case .rightBrace:
        advance()
        return .object(object)
      case .comma:
        advance()
        skipWhitespace()
        if object.isEmpty || current == .rightBrace {
          throw JSONError.unexpectedComma
        }
      case .quote:
        let key = try parseString() as String
        skipWhitespace()
        guard current == .colon else {
          throw JSONError.colonRequired
        }
        advance()
        skipWhitespace()
        object[key] = try parseValue()
        skipWhitespace()
      default:
        throw JSONError.stringNotStarted
      }
    }

    throw JSONError.unexpectedEndOfFile
  }

  /// Parse the JSON array.
  ///
  ///     array := '[' whitespace | (value ','?)* ']'
  func parseArray() throws -> JSON {
    advance()
    skipWhitespace()
    var array = [JSON]()
    while let byte = current {
      switch byte {
      case .rightBrack:
        advance()
        return .array(array)
      case .comma:
        advance()
        skipWhitespace()
        if array.isEmpty || current == .rightBrack {
          throw JSONError.unexpectedComma
        }
      default:
        array.append(try parseValue())
        skipWhitespace()
      }
    }

    throw JSONError.unexpectedEndOfFile
  }

  /// Parse the JSON value.
  ///
  ///     value := whitespace object | array | string | number | bool | null whitespace
  func parseValue() throws -> JSON {
    guard let byte = current else {
      throw JSONError.unexpectedEndOfFile
    }
    switch byte {
    case .leftBrace:
      return try parseObject()
    case .leftBrack:
      return try parseArray()
    case .quote:
      return try parseString()
    case .minus, .zero ... .nine:
      return try parseNumber()
    case .t, .f:
      return try parseBool()
    case .n:
      return try parseNull()
    default:
      throw JSONError.invalidValue
    }
  }

  func parseString() throws -> JSON {
    .string(try parseString())
  }

  /// Parse the JSON string.
  ///
  ///     string := '"' (xxx)* '"'
  func parseString() throws -> String {
    advance()
    let start = index
    while let byte = current {
      switch byte {
      case .quote:
        let string = String(decoding: bytes[start..<index], as: Unicode.UTF8.self)
        advance()
        return string
      case .backslash:
        advance()
        guard let byte = current,
          byte == .quote
            || byte == .solidus
            || byte == .backslash
            || byte == .b
            || byte == .f
            || byte == .n
            || byte == .r
            || byte == .t
            || byte == .u
        else {
          throw JSONError.invalidEscape
        }
        advance()
      case .null ... .unitSeparator:
        throw JSONError.unexpectedControlCharacter
      default:
        advance()
      }
    }

    throw JSONError.stringNotClosed
  }

  /// Parse the JSON number.
  ///
  ///     number ::= '-'? 0 | [1-9]+ fraction? exponent?
  ///     fraction := '.' digit+
  ///     exponent := 'e' | 'E' ('-' | '+')? digit+
  ///     digit := [0-9]
  ///     digit_1 := [1-9]
  func parseNumber() throws -> JSON {
    let start = index
    // -
    if current == .minus {
      advance()
    }
    // 0
    if current == .zero {
      advance()
      if let byte = current, byte >= .zero && byte <= .nine {
        throw JSONError.numberWithLeadingZero
      }
    }
    // 1 - 9
    while let byte = current, byte >= .zero && byte <= .nine {
      advance()
    }

    // fraction
    if current == .period {
      advance()
      guard let byte = current, byte >= .zero && byte <= .nine else {
        throw JSONError.numberWithInvalidFraction
      }
      while let byte = current, byte >= .zero && byte <= .nine {
        advance()
      }
    }

    // exponent
    if current == .e || current == .E {
      advance()
      if current == .minus || current == .plus {
        advance()
      }
      guard let byte = current, byte >= .zero && byte <= .nine else {
        throw JSONError.numberWithInvalidExponent
      }
      while let byte = current, byte >= .zero && byte <= .nine {
        advance()
      }
    }

    let string = String(decoding: bytes[start..<index], as: Unicode.UTF8.self)
    return .number(string)
  }

  /// Parse the JSON bool.
  ///
  ///     bool := 'true' | 'false'
  func parseBool() throws -> JSON {
    if bytes.distance(from: index, to: bytes.endIndex) >= 4,
      bytes[index] == .t,
      bytes[bytes.index(index, offsetBy: 1)] == .r,
      bytes[bytes.index(index, offsetBy: 2)] == .u,
      bytes[bytes.index(index, offsetBy: 3)] == .e
    {
      advance(4)
      return .bool(true)
    }

    if bytes.distance(from: index, to: bytes.endIndex) >= 5,
      bytes[index] == .f,
      bytes[bytes.index(index, offsetBy: 1)] == .a,
      bytes[bytes.index(index, offsetBy: 2)] == .l,
      bytes[bytes.index(index, offsetBy: 3)] == .s,
      bytes[bytes.index(index, offsetBy: 4)] == .e
    {
      advance(5)
      return .bool(false)
    }

    throw JSONError.invalidBool
  }

  /// Parse the JSON null.
  ///
  ///     null := 'null'
  func parseNull() throws -> JSON {
    if bytes.distance(from: index, to: bytes.endIndex) >= 4,
      bytes[index] == .n,
      bytes[bytes.index(index, offsetBy: 1)] == .u,
      bytes[bytes.index(index, offsetBy: 2)] == .l,
      bytes[bytes.index(index, offsetBy: 3)] == .l
    {
      advance(4)
      return .null
    }

    throw JSONError.invalidNull
  }

  /// Skip whitespace.
  ///
  ///     whitespace := (0x09 | 0x0A | 0x0D | 0x20)*
  func skipWhitespace() {
    while let byte = current, byte.isWhitespace {
      advance()
    }
  }
}
