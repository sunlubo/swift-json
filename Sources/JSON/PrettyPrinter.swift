//
//  PrettyPrinter.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/3.
//  Copyright © 2020 sun. All rights reserved.
//

public struct PrettyPrinter {
  var json: JSON
  var indention: Int
  var content: String

  public init(json: JSON) {
    self.json = json
    self.indention = 0
    self.content = ""
  }

  mutating func write(_ string: String) {
    content.append(string)
  }

  public mutating func print() {
    json.render(into: &self)
    Swift.print(content)
  }
}

extension JSON {

  func render(into stream: inout PrettyPrinter) {
    switch self {
    case .object(let object):
      stream.write("{")
      stream.write("\n")
      for (index, (key, value)) in object.enumerated() {
        if index != 0 {
          stream.write(",")
          stream.write(" ")
          stream.write("\n")
        }
        stream.indention += 2
        stream.write(String(repeating: " ", count: stream.indention))
        stream.write("\"")
        stream.write(key)
        stream.write("\"")
        stream.write(":")
        stream.write(" ")
        value.render(into: &stream)
        stream.indention -= 2
      }
      stream.write("\n")
      stream.write(String(repeating: " ", count: stream.indention))
      stream.write("}")
    case .array(let array):
      stream.write("[")
      stream.write("\n")
      for (index, value) in array.enumerated() {
        if index != 0 {
          stream.write(",")
          stream.write(" ")
        }
        stream.indention += 2
        stream.write(String(repeating: " ", count: stream.indention))
        value.render(into: &stream)
        stream.indention -= 2
      }
      stream.write("\n")
      stream.write(String(repeating: " ", count: stream.indention))
      stream.write("]")
    case .string(let value):
      stream.write("\"")
      stream.write(value)
      stream.write("\"")
    case .number(let value):
      stream.write(value.description)
    case .bool(let value):
      stream.write(value.description)
    case .null:
      stream.write("null")
    }
  }
}
