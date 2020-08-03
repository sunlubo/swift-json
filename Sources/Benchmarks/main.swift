//
//  File.swift
//  
//
//  Created by sunlubo on 2020/8/3.
//

import Foundation
import Benchmark
import JSON

benchmark("parse json") {
  // let source = try String(contentsOf: URL(string: "file:///Users/sun/Desktop/SwiftDOM/SwiftDOM/JSON.json")!)
  let source = #"""
     {
       "string": "hello",
       "int": 100,
       "float": -3.14159265354,
       "bool_true": true,
       "bool_false": false,
       "array": [1, 2, 3, 4, 5],
       "null": null,
       "object": {
         "key": "value"
       }
     }
    """#
  // let source = "[]"
  let _ = try JSON(string: source)
  // let _ = try JSONSerialization.jsonObject(with: source.data(using: .utf8)!, options: .init())
  // var printer = PrettyPrinter(json: json)
  // printer.print()
}

Benchmark.main()

// name       time    std        iterations
// ----------------------------------------
// parse json 4510 ns ±  49.46 %     277708

// name       time     std        iterations
// -----------------------------------------
// parse json 27353 ns ±  22.41 %      47774
