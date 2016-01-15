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