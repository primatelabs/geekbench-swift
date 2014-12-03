// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation


let workloadFactories = [
  {() -> Workload in return MandelbrotWorkload(width: 800, height: 800) },
  {() -> Workload in return SGEMMWorkload(matrixSize: 896, blockSize: 512 / sizeof(Float32)) },
  {() -> Workload in return SFFTWorkload(size: 8 * 1024 * 1024, chunkSize: 4096)},
  {() -> Workload in return FibonacciWorkload(n: 36)},
]


func printResult(result : WorkloadResult) {
  println(result.workloadName)
  for (rate, runtime) in Zip2(result.rates, result.runtimes) {
    let rateString = result.workloadUnits.stringFromRate(rate)
    println("  \(rateString) (\(runtime) seconds)")
  }

  let minRate = result.rates.reduce(Double.infinity, { min($0, $1) })
  let maxRate = result.rates.reduce(0, { max($0, $1) })
  let avgRate = result.rates.reduce(0, { $0 + $1 }) / Double(result.rates.count)

  let minString = result.workloadUnits.stringFromRate(minRate)
  let maxString = result.workloadUnits.stringFromRate(maxRate)
  let avgString = result.workloadUnits.stringFromRate(avgRate)

  println()
  println("  Min rate: \(minString)")
  println("  Max rate: \(maxString)")
  println("  Avg rate: \(avgString)")
  println()
}

func main() {
  for workloadFactory in workloadFactories {
    var workload = workloadFactory()
    let result = workload.run()
    printResult(result)
  }
}

main()
