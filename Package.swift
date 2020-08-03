// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "JSON",
  products: [
    .library(name: "JSON", targets: ["JSON"])
  ],
  dependencies: [
    .package(name: "Benchmark", url: "https://github.com/google/swift-benchmark", .branch("master"))
  ],
  targets: [
    .target(name: "JSON", dependencies: []),
    .target(name: "Benchmarks", dependencies: ["JSON", "Benchmark"]),
    .testTarget(name: "JSONTests", dependencies: ["JSON"]),
  ]
)
