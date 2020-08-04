//
//  JSON.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/3.
//  Copyright © 2020 sun. All rights reserved.
//

public indirect enum JSON {
  case object([String: JSON])
  case array([JSON])
  case string(String)
  case number(Double)
  case bool(Bool)
  case null
}

extension JSON {

  public init(string: String) throws {
    var parser = Parser(source: string)
    self = try parser.parse()
  }
}

extension JSON {
  enum Token: Equatable {
    case leftBrace
    case rightBrace
    case leftBrack
    case rightBrack
    case colon
    case comma
    case string(String)
    case number(Double, String)
    case bool(Bool)
    case null
    case eof
  }
}

extension JSON {
  enum Error: Swift.Error {
    case invalidCharacter(Character)
    case invalidObject(Token)
    case invalidArray(Token)
    case invalidNumber(String)
    case invalidToken(Token)
    case unexpectedEOF
  }
}

extension JSON {
  struct Lexer {
    var bytes: Array<UInt8>
    var index: Array<UInt8>.Index

    init(source: String) {
      var string = source
      self.bytes = string.withUTF8(Array.init(_:))
      self.index = bytes.startIndex
    }

    mutating func lex() throws -> Token {
      while index < bytes.endIndex {
        defer {
          bytes.formIndex(after: &index)
        }

        switch bytes[index] {
        case let byte where byte.isWhitespace:
          continue
        case .leftBrace:
          return .leftBrace
        case .rightBrace:
          return .rightBrace
        case .leftBrack:
          return .leftBrack
        case .rightBrack:
          return .rightBrack
        case .colon:
          return .colon
        case .comma:
          return .comma
        case .quote:
          return try lexString(index)
        case .zero ... .nine, .minus:
          return try lexNumber(index)
        case .t, .f:
          return try lexBool(index)
        case .n:
          return try lexNull(index)
        case let byte:
          throw Error.invalidCharacter(Character(Unicode.Scalar(byte)))
        }
      }

      return .eof
    }

    /// Lex a string literal.
    ///
    /// string-literal ::= '"' [^"\n\f\v\r]* '"'
    mutating func lexString(_ start: Int) throws -> Token {
      bytes.formIndex(after: &index)
      while index < bytes.endIndex {
        switch bytes[index] {
        case .quote:
          return .string(
            String(decoding: bytes[bytes.index(after: start)..<index], as: Unicode.UTF8.self))
        case .backslash:
          bytes.formIndex(after: &index)
          if bytes[index] == .x || bytes[index] == .zero || bytes[index] == .space
            || bytes[index] == .newLine
          {
            throw Error.invalidCharacter(Character(Unicode.Scalar(bytes[index])))
          }
        case .horizontalTab, .newLine:
          throw Error.invalidCharacter(Character(Unicode.Scalar(bytes[index])))
        default:
          ()
        }
        bytes.formIndex(after: &index)
      }
      throw Error.unexpectedEOF
    }

    /// Lex a number literal.
    ///
    /// number-literal ::= integer-literal | float-literal
    /// integer-literal ::= digit+
    /// float-literal ::= [-+]?digit+[.]digit*([eE][-+]?digit+)?
    /// digit ::= [0-9]
    mutating func lexNumber(_ start: Int) throws -> Token {
      bytes.formIndex(after: &index)
      while index < bytes.endIndex,
        (bytes[index] >= .zero && bytes[index] <= .nine)
          || [.plus, .minus, .period, .e, .E].contains(bytes[index])
      {
        bytes.formIndex(after: &index)
      }

      guard bytes[start] != .zero || index - start == 1 || bytes[start + 1] == .period else {
        throw Error.invalidCharacter(Character(Unicode.Scalar(bytes[start])))
      }

      let string = String(decoding: bytes[start..<index], as: Unicode.UTF8.self)
      if let value = Double(string) {
        bytes.formIndex(before: &index)
        return .number(value, string)
      }
      throw Error.invalidNumber(string)
    }

    mutating func lexBool(_ start: Int) throws -> Token {
      while index < bytes.endIndex, [.t, .r, .u, .e, .f, .a, .l, .s].contains(bytes[index]) {
        bytes.formIndex(after: &index)
      }
      if let value = Bool(String(decoding: bytes[start..<index], as: Unicode.UTF8.self)) {
        bytes.formIndex(before: &index)
        return .bool(value)
      }
      throw Error.unexpectedEOF
    }

    mutating func lexNull(_ start: Int) throws -> Token {
      while index < bytes.endIndex, [.n, .u, .l].contains(bytes[index]) {
        bytes.formIndex(after: &index)
      }
      if String(decoding: bytes[start..<index], as: Unicode.UTF8.self) == "null" {
        bytes.formIndex(before: &index)
        return .null
      }
      throw Error.unexpectedEOF
    }
  }
}

extension JSON {
  struct Parser {
    var lexer: Lexer

    init(source: String) {
      self.lexer = Lexer(source: source)
    }

    mutating func parse() throws -> JSON {
      let json: JSON
      switch try lexer.lex() {
      case .leftBrace:
        json = try parseObject()
      case .leftBrack:
        json = try parseArray()
      case let token:
        throw Error.invalidToken(token)
      }
      if try lexer.lex() != .eof {
        throw Error.invalidToken(Token.eof)
      }
      return json
    }

    mutating func parseObject() throws -> JSON {
      var object = [String: JSON]()
      var token = try lexer.lex()
      while token != .eof {
        switch token {
        case .rightBrace:
          return .object(object)
        case .comma:
          token = try lexer.lex()
          if object.isEmpty || token == .comma || token == .rightBrace {
            throw Error.invalidObject(token)
          }
          continue
        case .string(let key):
          token = try lexer.lex()
          if token != .colon {
            throw Error.invalidObject(token)
          }
          token = try lexer.lex()
          object[key] = try parseValue(token)
        default:
          throw Error.invalidObject(token)
        }
        token = try lexer.lex()
      }
      throw Error.invalidObject(token)
    }

    mutating func parseArray() throws -> JSON {
      var array = [JSON]()

      var token = try lexer.lex()
      while token != .eof {
        switch token {
        case .rightBrack:
          return .array(array)
        case .comma:
          token = try lexer.lex()
          if array.isEmpty || token == .rightBrack {
            throw Error.invalidArray(token)
          }
          continue
        default:
          array.append(try parseValue(token))
        }
        token = try lexer.lex()
      }
      throw Error.invalidArray(token)
    }

    mutating func parseValue(_ token: Token) throws -> JSON {
      switch token {
      case .leftBrace:
        return try parseObject()
      case .leftBrack:
        return try parseArray()
      case .string(let value):
        return .string(value)
      case .number(let value, _):
        return .number(value)
      case .bool(let value):
        return .bool(value)
      case .null:
        return .null
      default:
        throw Error.invalidToken(token)
      }
    }
  }
}
