//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

/**
 * A fixed size, continuous buffer.
 */
class RingBuffer<ElementType> {
    let capacity: Int
    var buffer: [ElementType?]
    
    private var start: Int = 0
    private var end: Int = 0
    
    init(capacity: Int) {
        precondition(capacity > 1, "The capacity of the buffer must be greater than one.")
        
        self.capacity = capacity
        buffer = [ElementType?](count: capacity, repeatedValue: nil)
    }

    /**
     * Inserts an element into the buffer. When the capacity has been met,
     * the oldest item is overwritten.
     */
    func insert(element: ElementType) {
        buffer[end] = element

        if start == 0 && end == 0 {
            end = 1
        }
        else {
            end = (end + 1) % capacity
            if end == start {
                start += 1
            }
        }
    }
    
    /**
     * Removes the oldest item in the buffer.
     */
    func remove() -> ElementType? {
        let element = buffer[start]
        buffer[start] = nil

        if start != end {
            start = (start + 1) % capacity
        }
        
        return element
    }
    
    /**
     * Retrieves an item from the buffer at the given index.
     *
     * @param index The index within the buffer.
     */
    subscript(index: Int) -> ElementType? {
        precondition(index >= 0, "The index must be greater than or equal to 0.")
        precondition(index < capacity, "The index must be less than the capacity.")
        
        return buffer[index]
    }
}

/**
 * A implementation of a queue that limits the number of items stored within
 * itself. New items added after the capacity is filled overwrite the last
 * item.
 */
// struct CircularQueue<ElementType> {
//     private class _QueueData {
//         let capacity: Int
//         var items: [ElementType] = []
//     }
    
//     private let _data = _QueueData()
//     private var lastIndex: Int = 0
    
//     init(capacity: Int = 10) {
//         self.capacity = capacity
//     }
// }

