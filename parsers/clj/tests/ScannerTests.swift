//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

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