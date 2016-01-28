// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

enum WorkloadUnits {
  case BytesSecond, PixelsSecond, Flops, NodesSecond

  func string() -> String {
    switch self {
    case .BytesSecond:
      return "Bytes/Second"
    case .PixelsSecond:
      return "Pixels/Second"
    case .Flops:
      return "Flops"
    case .NodesSecond:
      return "Nodes/Second"
    }
  }

  func stringFromRate(rate : Double) -> String {
    var outRate = rate
    var divisor : Double = 1000.0

    if self == .BytesSecond {
      divisor = 1024.0
    }

    let prefixes = ["", "K", "M", "G", "T"]
    var prefix = prefixes[0]

    for var i = 0; i < prefixes.count; ++i {
      prefix = prefixes[i]

      if outRate < divisor {
        break
      }

      outRate /= divisor
    }

    let outRateString = NSString(format: "%.2f", outRate)
    let units = self.string()
    return "\(outRateString) \(prefix)\(units)"
  }
}
