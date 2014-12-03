// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

struct Timer {
  var startTime = NSDate()

  mutating func restart() {
    startTime = NSDate()
  }

  func elapsed() -> Double {
    return -startTime.timeIntervalSinceNow
  }
}