//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

class RingBufferTests: Test {
    required init() {}
    let tests = [
        RingBufferTests.testBasicInit,
        RingBufferTests.testInsertion,
        RingBufferTests.testRemove,
        RingBufferTests.testNoOverwrite
    ]

    let filename: String = __FILE__

    static func testBasicInit() throws {
        let buffer = RingBuffer<Int>(capacity: 10)
        try test.assert(buffer.capacity == 10)
    }
    
    static func testInsertion() throws {
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
    
    static func testRemove() throws {
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
    
    static func testNoOverwrite() throws {
        let buffer = RingBuffer<Int>(capacity: 3, overwrite: false)
        try test.assert(buffer.capacity == 3)
        
        buffer.insert(100)
        buffer.insert(101)
        buffer.insert(102)
        buffer.insert(103)

        try test.assert(buffer[0] == 100)
        try test.assert(buffer[1] == 101)
        try test.assert(buffer[2] == 102)
        
        try test.assert(buffer.remove() == 100)
        try test.assert(buffer[0] == nil)
        try test.assert(buffer[1] == 101)
        try test.assert(buffer[2] == 102)
        
        buffer.insert(103)
        try test.assert(buffer[0] == 103)
        try test.assert(buffer[1] == 101)
        try test.assert(buffer[2] == 102)
    }
}