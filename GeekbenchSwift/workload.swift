// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

class Workload  {
  func worker() {
    fatalError("Implementer must override")
  }

  func reset() {
    fatalError("Implementer must override")
  }

  func work() -> UInt64 {
    fatalError("Implementer must override")
  }

  func units() -> WorkloadUnits {
    fatalError("Implementer must override")
  }

  func name() -> String {
    fatalError("Implementer must override")
  }

  func run() -> WorkloadResult {
    var result = WorkloadResult()
    result.workloadName = self.name()
    result.workloadUnits = self.units()

    for _ in 1...8 {
      self.reset()

      var timer = Timer()
      self.worker()
      let elapsed = timer.elapsed()

      result.runtimes.append(elapsed)
      result.rates.append(Double(self.work()) / elapsed)
    }

    return result
  }
}