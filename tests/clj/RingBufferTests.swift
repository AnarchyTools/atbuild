//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

extension String: ErrorType {}

enum test {
    static func assert(condition: Bool, functionName: String = __FUNCTION__) throws {
        print("  \(functionName): \(condition ? "PASSED" : "**FAILED**")")
        if !condition { throw "clj.tests.failed" }
    }
}

class RingBufferTests: Test {
    required init() {}
    func runTests() {
        print("Tests for \(__FILE__)")
        
        let tests = [
            testBasicInit,
            testInsertion,
            testRemove
        ]

        for test in tests {
            let _ = try? test()
        }
    }
    
    func testBasicInit() throws {
        let buffer = RingBuffer<Int>(capacity: 10)
        try test.assert(buffer.capacity == 10)
    }
    
    func testInsertion() throws {
        let buffer = RingBuffer<Int>(capacity: 3)
        try test.assert(buffer.capacity == 3)
        
        buffer.insert(100)
        try test.assert(buffer[0] == 100)
        
        buffer.insert(101)
        try test.assert(buffer[1] == 101)
        
        buffer.insert(102)
        try test.assert(buffer[2] == 102)
        
        buffer.insert(103)
        try test.assert(buffer[0] == 103)
    }
    
    func testRemove() throws {
        let buffer = RingBuffer<Int>(capacity: 3)
        try test.assert(buffer.capacity == 3)
        
        buffer.insert(100)
        try test.assert(buffer[0] == 100)
        
        try test.assert(buffer.remove() == 100)
        try test.assert(buffer[0] == nil)
        try test.assert(buffer[1] == nil)
        try test.assert(buffer[2] == nil)

        buffer.insert(100)
        buffer.insert(101)
        try test.assert(buffer[0] == nil)
        try test.assert(buffer[1] == 100)
        try test.assert(buffer[2] == 101)
        try test.assert(buffer.remove() == 100)
        try test.assert(buffer.remove() == 101)
        
        try test.assert(buffer.remove() == nil)
        try test.assert(buffer.remove() == nil)
        
        buffer.insert(100)
        buffer.insert(101)
        try test.assert(buffer[0] == 100)
        try test.assert(buffer[1] == 101)
        try test.assert(buffer[2] == nil)
    }
}