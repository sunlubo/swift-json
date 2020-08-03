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
  case float(Float)
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
    case number(Float, String)
    case bool(Bool)
    case null
    case eof

    var id: Int {
      switch self {
      case .leftBrace:
        return 0
      case .rightBrace:
        return 1
      case .leftBrack:
        return 2
      case .rightBrack:
        return 3
      case .colon:
        return 4
      case .comma:
        return 5
      case .string:
        return 6
      case .number:
        return 7
      case .bool:
        return 8
      case .null:
        return 9
      case .eof:
        return 10
      }
    }
  }
}

extension JSON {
  enum Error: Swift.Error {
    case invalidCharacter(Character)
    case invalidNumber(String)
    case invalidToken(Token)
    case unexpectedEOF
  }
}

// https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form
// https://my.liyunde.com/backus-naur-form-bnf/
// https://en.wikipedia.org/wiki/JSON
extension JSON {
  struct Lexer {
    var source: String
    var index: String.Index

    init(source: String) {
      self.source = source
      self.index = source.startIndex
    }

    mutating func lex() throws -> Token {
      while index < source.endIndex {
        defer {
          source.formIndex(after: &index)
        }

        switch source[index] {
        case let char where char.isWhitespace && char.isASCII:
          continue
        case "{":
          return .leftBrace
        case "}":
          return .rightBrace
        case "[":
          return .leftBrack
        case "]":
          return .rightBrack
        case ":":
          return .colon
        case ",":
          return .comma
        case "n":
          return try lexNull(index)
        case "t", "f":
          return try lexBool(index)
        case "\"":
          return try lexString(index)
        case let char where char == "-" || (char.isNumber && char.isASCII):
          return try lexNumber(index)
        case let char:
          throw Error.invalidCharacter(char)
        }
      }

      return .eof
    }

    /// Lex a number literal.
    ///
    /// number-literal ::= integer-literal | float-literal
    /// integer-literal ::= digit+
    /// float-literal ::= [-+]?digit+[.]digit*([eE][-+]?digit+)?
    /// digit ::= [0-9]
    mutating func lexNumber(_ start: String.Index) throws -> Token {
      var nextIndex = source.index(after: index)
      while nextIndex < source.endIndex,
        source[nextIndex].isASCII
          && (source[nextIndex].isNumber || source[nextIndex] == "." || source[nextIndex] == "e"
            || source[nextIndex] == "+" || source[nextIndex] == "-")
      {
        source.formIndex(after: &index)
        source.formIndex(after: &nextIndex)
      }

      let string = String(source[start...index])
      if let value = Float(string) {
        return .number(value, string)
      }
      throw Error.invalidNumber(string)
    }

    /// Lex a string literal.
    ///
    /// string-literal ::= '"' [^"\n\f\v\r]* '"'
    mutating func lexString(_ start: String.Index) throws -> Token {
      while index < source.endIndex {
        source.formIndex(after: &index)
        if source[index] == "\"" {
          return .string(String(source[source.index(after: start)..<index]))
        }
      }
      throw Error.unexpectedEOF
    }

    mutating func lexNull(_ start: String.Index) throws -> Token {
      while index < source.endIndex, ["n", "u", "l", "l"].contains(source[index]) {
        source.formIndex(after: &index)
      }
      if source[start..<index] == "null" {
        return .null
      }
      throw Error.unexpectedEOF
    }

    mutating func lexBool(_ start: String.Index) throws -> Token {
      while index < source.endIndex,
        ["t", "r", "u", "e", "f", "a", "l", "s"].contains(source[index])
      {
        source.formIndex(after: &index)
      }
      if let value = Bool(String(source[start..<index])) {
        return .bool(value)
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
      switch try lexer.lex() {
      case .leftBrace:
        return try parseObject()
      case .leftBrack:
        return try parseArray()
      case let token:
        throw Error.invalidToken(token)
      }
    }

    mutating func parseObject() throws -> JSON {
      var object = [String: JSON]()

      var token = try lexer.lex()
      while token != .eof && token != .rightBrace {
        guard case .string(let key) = token else {
          throw Error.invalidToken(token)
        }

        token = try lexer.lex()
        guard token == .colon else {
          throw Error.invalidToken(token)
        }

        token = try lexer.lex()
        switch token {
        case .leftBrace:
          object[key] = try parseObject()
        case .leftBrack:
          object[key] = try parseArray()
        case .string(let value):
          object[key] = .string(value)
        case .number(let value, _):
          object[key] = .float(value)
        case .bool(let value):
          object[key] = .bool(value)
        case .null:
          object[key] = .null
        default:
          ()
        }
        token = try lexer.lex()
        while token != .eof, token.id != 6 {
          token = try lexer.lex()
        }
      }
      return .object(object)
    }

    mutating func parseArray() throws -> JSON {
      var array = [JSON]()

      var token = try lexer.lex()
      while token != .eof && token != .rightBrack {
        switch token {
        case .leftBrace:
          array.append(try parseObject())
        case .leftBrack:
          array.append(try parseArray())
        case .string(let value):
          array.append(.string(value))
        case .number(let value, _):
          array.append(.float(value))
        case .bool(let value):
          array.append(.bool(value))
        case .null:
          array.append(.null)
        default:
          ()
        }
        token = try lexer.lex()
        while token != .eof, token != .comma && token != .rightBrack {
          token = try lexer.lex()
        }
      }
      return .array(array)
    }
  }
}
