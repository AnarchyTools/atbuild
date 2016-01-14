//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

enum test {
    static func assert(condition: Bool, functionName: String = __FUNCTION__) {
        print("  \(functionName): \(condition ? "PASSED" : "**FAILED**")")
    }
}

class SizedQueueTests {
    required init() {}
    
    func runTests() {
        print("Tests for \(__FILE__)")
        testBasicInit()
    }
    
    func testBasicInit() {
        let queue = SizedQueue<String>()
        
        test.assert(10 == queue.maximumNumberOfItems)
    }
}