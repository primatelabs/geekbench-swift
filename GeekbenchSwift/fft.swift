// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.
import Foundation

struct Complex : Printable {
    internal var real : Float32
    internal var imaginary : Float32
    var description: String {
        return String(format: "(%.5f, %.5fi)", real, imaginary)
    }
    
    init() {
        self.real = 0
        self.imaginary = 0
    }
    
    init(real : Float32, imaginary : Float32) {
        self.real = real
        self.imaginary = imaginary
    }
    
    mutating func assign(real : Float32, imaginary : Float32) {
        self.real = real
        self.imaginary = imaginary
    }
    
    mutating func assign(rhs : Complex) {
        self.real = rhs.real
        self.imaginary = rhs.imaginary
    }
    
    mutating func add(rhs : Complex) {
        self.real += rhs.real
        self.imaginary += rhs.imaginary
    }
    
    mutating func subtract(rhs : Complex) {
        self.real -= rhs.real
        self.imaginary -= rhs.imaginary
    }
}

func * (left : Complex, right : Complex) -> Complex {
    return Complex(real: left.real * right.real - left.imaginary * right.imaginary,
        imaginary: left.real * right.imaginary + left.imaginary * right.real)
}

func + (left : Complex, right : Complex) -> Complex {
    return Complex(real: left.real + right.real, imaginary: left.imaginary + right.imaginary)
}

func - (left : Complex, right : Complex) -> Complex {
    return Complex(real: left.real - right.real, imaginary: left.imaginary - right.imaginary)
}


final class SFFTWorkload : Workload {
  let pi = Float32(acos(-1.0))

  var size : Int
  var chunkSize : Int
  var input : [Complex] = []
  var output : [Complex] = []
  var wFactors : [Complex] = []

  init(size : Int, chunkSize : Int) {
    self.size = size
    self.chunkSize = chunkSize

    self.input = [Complex](count: size, repeatedValue: Complex())
    self.output = [Complex](count: size, repeatedValue: Complex())
    

    // Precompute w factors
    self.wFactors.reserveCapacity(chunkSize)
    var theta : Float32 = 0
    var mult : Float32 = -2.0 * self.pi / Float32(chunkSize)
    for i in 0..<chunkSize {
      self.wFactors.append(Complex(real: cos(theta) as Float32, imaginary: sin(theta) as Float32))
      theta += mult
    }

  }

  override func worker() {
    for chunkOrigin in stride(from: 0, to: self.size, by: self.chunkSize) {
      reorderInputIntoOutput(chunkOrigin)
      executeInplaceFFTOnOutput(chunkOrigin)
    }

  }

  func reorderInputIntoOutput(chunkOrigin : Int) {
    let chunkSize = UInt32(self.chunkSize)

    // Right shift requred to account for unused leading zeros in the UInt32
    let shiftCorrection = countLeadingZeros(chunkSize) + 1

    for i in 0..<chunkSize {
      var o = i
      // Reverse the bits of o
      o = (o & 0x55555555) << 1 | (o & 0xAAAAAAAA) >> 1
      o = (o & 0x33333333) << 2 | (o & 0xCCCCCCCC) >> 2
      o = (o & 0x0F0F0F0F) << 4 | (o & 0xF0F0F0F0) >> 4
      o = (o & 0x00FF00FF) << 8 | (o & 0xFF00FF00) >> 8
      o = (o & 0x0000FFFF) << 16 | (o & 0xFFFF0000) >> 16

      o >>= shiftCorrection

      self.output[Int(o)].assign(self.input[chunkOrigin + Int(i)])
    }
  }

  func executeInplaceFFTOnOutput(chunkOrigin : Int) {
    
    self.output.withUnsafeMutableBufferPointer { (inout output:UnsafeMutableBufferPointer<Complex>)->() in
        self.fftWithOrigin(0, size: self.chunkSize, wStep: 1, output: &output)
    }
  }

    func fftWithOrigin(origin : Int, size : Int,  wStep : Int, inout output:UnsafeMutableBufferPointer<Complex>) {
        
    if size == 4 {
      fft4WithOrigin(origin, output: &output)
      return
    }

    let m = size / 2
    fftWithOrigin(origin, size: m, wStep: 2 * wStep, output: &output)
    fftWithOrigin(origin + m, size: m, wStep: 2 * wStep, output: &output)

    var wIndex = 0
    for offset in 0..<m {
      let butterflyTop = origin + offset
      let a = output[butterflyTop]
      let b = self.wFactors[wIndex] * output[butterflyTop + m]

      output[butterflyTop] = a + b
      output[butterflyTop + m] = a - b

      wIndex += wStep
    }
  }

  // Compute the bottom 2 stages of the FFT recursion (FFTs of length 4 and 2)
    func fft4WithOrigin(origin : Int, inout output:UnsafeMutableBufferPointer<Complex>) {
    
    var s0 = output[origin]
    var s1 = output[origin + 1]
    var t0 = output[origin + 2]
    var t1 = output[origin + 3]
    var tmp0 = Complex()
    var tmp1 = Complex()

    // FFT length = 2
    tmp0.assign(s0)
    s0.add(s1)
    s1.assign(tmp0 - s1)

    tmp1.assign(t0)
    t0.add(t1)
    t1.assign(tmp1 - t1)

    // FFT length = 4
    tmp0.assign(s0)
    tmp1.assign(s1)
    t1.assign(t1.imaginary, imaginary: -t1.real)
    s0.add(t0)
    s1.add(t1)
    t0.assign(tmp0 - t0)
    t1.assign(tmp1 - t1)

    output[origin] = s0;
    output[origin + 1] = s1;
    output[origin + 2] = t0;
    output[origin + 3] = t1;
  }

  func countLeadingZeros(value : UInt32) -> UInt32 {
    // This algorithm is from Hacker's Delight: http://www.hackersdelight.org/hdcodetxt/nlz.c.txt
    var nlz : UInt32 = 0
    var x = value

    if x == 0 {
      return 32
    }

    if x <= 0x0000FFFF {
      nlz += 16
      x <<= 16
    }
    if x <= 0x00FFFFFF {
      nlz += 8
      x <<= 8
    }
    if x <= 0x0FFFFFFF {
      nlz += 4
      x <<= 4
    }
    if x <= 0x3FFFFFFF {
      nlz += 2
      x <<= 2
    }
    if x <= 0x7FFFFFFF {
      ++nlz
    }
    return nlz
  }

  override func reset() {
    for i in 0..<size {
      let thetar = 2.0 * self.pi * Float32(i) / Float32(size)
      let thetai = 2.0 * self.pi * Float32(i + size) / Float32(size)
      input[i] = Complex(real: sin(11 * thetar), imaginary: sin(11 * thetai))
    }
  }

  override func work() -> UInt64 {
    let chunks = size / chunkSize

    let lc = log(Float32(self.chunkSize))
    let l2 = log(Float32(2.0))
    let floatOps = Float32(chunks * 5 * self.chunkSize) * lc / l2

    return UInt64(floatOps)
  }

  override func units() -> WorkloadUnits {
    return WorkloadUnits.Flops
  }

  override func name() -> String {
    return "FFT"
  }
}
