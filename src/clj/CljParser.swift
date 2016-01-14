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
    let overwrite: Bool
    
    private var start: Int! = nil
    private var end: Int! = nil
    
    init(capacity: Int, overwrite: Bool = true) {
        precondition(capacity > 1, "The capacity of the buffer must be greater than one.")
        
        self.overwrite = overwrite
        self.capacity = capacity
        buffer = [ElementType?](count: capacity, repeatedValue: nil)
    }

    /**
     * Inserts an element into the buffer. When the capacity has been met,
     * the oldest item is overwritten if `overwrite` was set to `true`.
     */
    func insert(element: ElementType) {
        if start == nil {
            buffer[0] = element
            start = 0
            end = 1
        }
        else {
            if overwrite {
                buffer[end] = element
                end = (end + 1) % capacity
                if end == start {
                    start = start + 1
                }
            }
            else {
                if start != end {
                    buffer[end] = element
                    end = (end + 1) % capacity
                }
            }
        }
    }
    
    /**
     * Removes the oldest item in the buffer.
     */
    func remove() -> ElementType? {
        if start == nil || end == nil { return nil }
        
        let element = buffer[start]
        buffer[start] = nil

        start = (start + 1) % capacity

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

