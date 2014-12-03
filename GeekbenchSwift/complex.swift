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
