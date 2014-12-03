// Copyright (c) 2014 Primate Labs Inc.
// Use of this source code is governed by the 2-clause BSD license that
// can be found in the LICENSE file.

import Foundation

struct WorkloadResult {
  var workloadName = ""
  var runtimes : [Double] = []
  var rates : [Double] = []
  var workloadUnits = WorkloadUnits.BytesSecond
}