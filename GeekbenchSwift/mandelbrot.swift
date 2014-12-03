// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

class MandelbrotWorkload : Workload {
  var width : UInt
  var height : UInt
  var output : [UInt8]? = nil

  init(width : UInt, height : UInt) {
    self.width = width
    self.height = height
  }

  override func worker() {
    self.output = [UInt8](count: Int(self.width * self.height), repeatedValue: 0)

    // Origin
    let ro : Float = -1.5
    let co : Float = 1.0

    // Stride
    let sr = 2.0 / Float(self.width)
    let sc = -2.0 / Float(self.height)

    let w = Int(self.width)
    let h = Int(self.height)

    for x : UInt in 0..<self.width {
      for y : UInt in 0..<self.height {
        let zr0 = ro + Float(x) * sr
        let zc0 = co + Float(y) * sc
        var zr = zr0
        var zc = zc0

        var k = 0
        for _ in 0..<255 {
          var tr = zr

          zr = zr * zr - (zc * zc)
          zc = 2.0 * tr * zc
          if zr * zr + zc * zc >= 4.0 {
            break
          }

          zr += zr0
          zc += zc0

          k++
        }

        let index = Int(self.width * y + x)
        let value = UInt8(min(max(k, 0), 255))

        self.output![index] = value
      }
    }
  }

  override func reset() {
  }

  override func work() -> UInt64 {
    var work : UInt64 = 0
    for element in self.output! {
      work += UInt64(11) * UInt64(element)
    }
    return work
  }

  override func units() -> WorkloadUnits {
    return WorkloadUnits.Flops
  }

  override func name() -> String {
    return "Mandelbrot"
  }
}