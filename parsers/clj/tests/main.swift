//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

// NOTE: This is the crappiest test thing ever... but it works for now.

extension String : ErrorType {}

enum test {
    static func assert(condition: Bool, functionName: String = __FUNCTION__) throws {
        print("  \(functionName): \(condition ? "PASSED" : "**FAILED**")")
        if !condition { throw "clj.tests.failed" }
    }
}

protocol Test {
    init()
    func runTests()
    
    var tests: [() throws -> ()] { get }
    var filename: String { get }
}

extension Test {
    func runTests() {
        print("Tests for \(__FILE__)")
        for test in tests {
            let _ = try? test()
        }
    }
}

print()

let tests: [Test] = [
    // NOTE: Add your test classes here...
    
    RingBufferTests(),
    ScannerTests()
]

for test in tests {
    test.runTests()
}

print()