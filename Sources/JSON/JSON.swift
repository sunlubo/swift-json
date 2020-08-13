//
//  JSON.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/3.
//  Copyright © 2020 sun. All rights reserved.
//

// https://en.wikipedia.org/wiki/JSON
// https://tools.ietf.org/html/rfc8259
public indirect enum JSON {
  case object([String: JSON])
  case array([JSON])
  case string(String)
  case number(String)
  case bool(Bool)
  case null

  public init(string: String) throws {
    var string = string
    self = try string.withUTF8 { ptr in
      try JSON(bytes: ptr)
    }
  }

  public init<C: Collection>(bytes: C) throws where C.Element == UInt8 {
    let parser = JSONParser(bytes: bytes)
    self = try parser.parse()
  }
}
