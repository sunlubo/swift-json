//
//  File.swift
//  
//
//  Created by sunlubo on 2020/8/3.
//

import Foundation
import Benchmark
import JSON

let source = #"""
   {
     "string": "hello🍎👪",
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

let benchmarks = BenchmarkSuite(
  name: "JSON Parsing", settings: Iterations(50000), WarmupIterations(1000)
) { suite in

  suite.benchmark("JSON") {
    let _ = try JSON(string: source)
  }
}

Benchmark.main([benchmarks])
