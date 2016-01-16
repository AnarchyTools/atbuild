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


import Foundation
import atpkg

class PackageTests: Test {
    required init() {}
    let tests = [
        PackageTests.testBasic
    ]

    let filename = __FILE__
    
    static func testBasic() throws {
        let filepath = "./atpkg/tests/collateral/basic.atpkg"

        guard let parser = Parser(filepath: filepath) else {
            try test.assert(false); return
        }
        
        let result = try parser.parse()
        guard let package = Package(type: result) else { try test.assert(false); return }
        
        try test.assert(package.name == "basic")
        try test.assert(package.version == "0.1.0-dev")
        
        try test.assert(package.tasks.count == 1)
        for (key, task) in package.tasks {
            try test.assert(key == "build")
            try test.assert(task.tool == "lldb-build")
            try test.assert(task["name"]?.string == "json-swift")
            try test.assert(task["output-type"]?.string == "lib")
            try test.assert(task["source"]?.vector?.count == 2)
            try test.assert(task["source"]?.vector?[0].string == "src/**.swift")
            try test.assert(task["source"]?.vector?[1].string == "lib/**.swift")
        }
    }
}
