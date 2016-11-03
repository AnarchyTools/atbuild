// Copyright (c) 2016 Anarchy Tools Contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if os(OSX)
import Darwin
#else
import Glibc
#endif
import atfoundation
public var environment: [String: String] {
    var r: [String: String] = [:]
    let e = _environment()!
    var i = 0
    while e[i] != nil {
        let keyv = e[i]!
        let keyvalue_ = String(validatingUTF8: keyv)!
        let keyvalue = keyvalue_.split(string: "=", maxSplits: 1)
        let key = keyvalue[0]
        let value = keyvalue[1]
        r[key] = value
        i += 1
    }
    return r
}
