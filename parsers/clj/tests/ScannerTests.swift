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

class ScannerTests: Test {
    required init() {}
    let tests = [
        ScannerTests.testBasicClj
    ]

    let filename = __FILE__
        
    static func testBasicClj() throws {
        let filepath = "./parsers/clj/tests/collateral/basic.clj"
        
        let content: String = try NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) as String
        let scanner = Scanner(content: content)
        try test.assert(scanner.next()?.character == ";")
        try test.assert(scanner.next()?.character == ";")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "T")
        try test.assert(scanner.next()?.character == "h")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == " ")
        try test.assert(scanner.next()?.character == "i")
        try test.assert(scanner.next()?.character == "s")
        
        scanner.stall()
        try test.assert(scanner.next()?.character == "s")
        try test.assert(scanner.next()?.character == " ")

        try test.assert(scanner.peek()?.character == " ")
        try test.assert(scanner.next()?.character == "t")
    }
}