//
//  UInt8+ASCII.swift
//  swift-json
//
//  Created by sunlubo on 2020/8/3.
//  Copyright © 2020 sun. All rights reserved.
//

extension UInt8 {
  /// '\t'
  static let horizontalTab: UInt8 = 0x09
  /// '\n'
  static let newLine: UInt8 = 0x0a
  /// '\r'
  static let carriageReturn: UInt8 = 0x0d
  /// ' '
  static let space: UInt8 = 0x20
  /// "
  static let quote: UInt8 = 0x22
  /// +
  static let plus: UInt8 = 0x2b
  /// ,
  static let comma: UInt8 = 0x2c
  /// -
  static let minus: UInt8 = 0x2d
  /// .
  static let period: UInt8 = 0x2e
  /// 0
  static let zero: UInt8 = 0x30
  /// 9
  static let nine: UInt8 = 0x39
  /// :
  static let colon: UInt8 = 0x3a
  /// E
  static let E: UInt8 = 0x45
  /// [
  static let leftBrack: UInt8 = 0x5b
  /// \
  static let backslash: UInt8 = 0x5C
  /// ]
  static let rightBrack: UInt8 = 0x5d
  /// _
  static let underscore: UInt8 = 0x5f
  /// a
  static let a: UInt8 = 0x61
  /// b
  static let b: UInt8 = 0x62
  /// e
  static let e: UInt8 = 0x65
  /// f
  static let f: UInt8 = 0x66
  /// l
  static let l: UInt8 = 0x6c
  /// n
  static let n: UInt8 = 0x6e
  /// r
  static let r: UInt8 = 0x72
  /// s
  static let s: UInt8 = 0x73
  /// t
  static let t: UInt8 = 0x74
  /// u
  static let u: UInt8 = 0x75
  /// x
  static let x: UInt8 = 0x78
  /// z
  static let z: UInt8 = 0x7a
  /// {
  static let leftBrace: UInt8 = 0x7b
  /// }
  static let rightBrace: UInt8 = 0x7d

  /// Returns whether or not the given byte can be considered UTF8 whitespace
  var isWhitespace: Bool {
    self == .horizontalTab || self == .newLine || self == .carriageReturn || self == .space
  }
}
