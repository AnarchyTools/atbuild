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