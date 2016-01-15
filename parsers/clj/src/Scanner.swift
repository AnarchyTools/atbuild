//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

struct ScannerInfo {
    let character: Character?
    let line: Int
    let column: Int
}

class Scanner {
    
    var content: String
    var index: String.Index
    var current: ScannerInfo? = nil

    private var shouldStall = false

    var line: Int = 0
    var column: Int = 0 

    init(content: String) {
        self.content = content
        self.index = content.startIndex
        self._defaults()
    }

    func _defaults() {
        self.index = content.startIndex
        self.line = 0
        self.column = 0
        self.shouldStall = false
        self.current = nil
   }

    func stall() {
        shouldStall = true
    }

    func next() -> ScannerInfo? {
        if shouldStall {
            shouldStall = false
            return current
        }
        
        if index == content.endIndex {
            current = nil 
        }
        else {
            current = ScannerInfo(character: content[index], line: line, column: column)
            index = index.successor()

            if current?.character == "\n" {
                line += 1
                column = 0 
            }
            else {
                column += 1
            }
        }

        return current 
    }

    func peek() -> ScannerInfo? {
        return current
    }
}