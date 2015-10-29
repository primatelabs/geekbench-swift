// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

struct Matrix {
  var N : Int
  var M : [Float32]

  init(matrixSize : Int) {
    self.N = matrixSize
    self.M = [Float32](count: matrixSize * matrixSize, repeatedValue: 0)
  }

  subscript(i1: Int, i2: Int) -> Float32 {
    get {
      return M[i1 * N + i2]
    }

    set(newValue) {
      M[i1 * N + i2] = newValue
    }
  }
}

final class SGEMMWorkload : Workload {
  var matrixSize : Int = 0
  var blockSize : Int = 0
  final var A : Matrix
  final var B : Matrix
  final var C : Matrix

  init(matrixSize : Int, blockSize : Int) {
    self.matrixSize = matrixSize
    self.blockSize = blockSize

    A = Matrix(matrixSize: matrixSize)
    B = Matrix(matrixSize: matrixSize)
    C = Matrix(matrixSize: matrixSize)
  }
  
  override func worker() {
    for var i = 0; i < matrixSize; i += blockSize {
      for var j = 0; j < matrixSize; j += blockSize {
        for var k = 0; k < matrixSize; k += blockSize {

          let ib = min(matrixSize, i + blockSize)
          let jb = min(matrixSize, j + blockSize)
          let kb = min(matrixSize, k + blockSize)

          for var i0 = i; i0 < ib; ++i0 {
            for var j0 = j; j0 < jb; ++j0 {

              let c = C[i0, j0]

              var scratch = c

              for var k0 = k; k0 < kb; ++k0 {

                let a = A[i0, k0]
                let b = B[j0, k0]

                scratch += a * b
              }

//              C[i0, j0] = scratch
            }
          }

        }
      }
    }
  }

  override func reset() {
    for i in 0..<self.matrixSize {
      for j in 0..<self.matrixSize {
//        let index = self.matrixSize * i + j
        let value = Float((i + j * self.matrixSize) % 10)
//        A[i, j] = value
//        B[i, j] = value
//        C[i, j] = 0.0
      }
    }
  }

  override func work() -> UInt64 {
    let N = UInt64(matrixSize)
    return 2 * N * N * N
  }

  override func units() -> WorkloadUnits {
    return WorkloadUnits.Flops
  }

  override func name() -> String {
    return "SGEMM"
  }
}
