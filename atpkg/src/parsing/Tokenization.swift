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

import Foundation

public enum TokenType {
    case Identifier
    case OpenParen
    case CloseParen
    case OpenBracket
    case CloseBracket
    case OpenBrace
    case CloseBrace
    case StringLiteral
    case Terminal
    case Colon
    case Comment

    case Unknown
    case EOF
}

public func ==(lhs: Token, rhs: Token) -> Bool {
    return lhs.type == rhs.type &&
           lhs.line == rhs.line &&
           lhs.column == rhs.column &&
           lhs.value == rhs.value
}

public struct Token: Equatable {
    public let value: String
    public let line: Int
    public let column: Int
    public let type: TokenType
    
    public init(type: TokenType, value: String = "", line: Int = 0, column: Int = 0) {
        self.type = type
        self.value = value
        self.line = line
        self.column = column
    }
}

func isCharacterPartOfSet(c: Character?, set: NSCharacterSet) -> Bool {
    guard let c = c else { return false }
    var isMember = true

    for utf16Component in String(c).utf16 {
        if !set.characterIsMember(utf16Component) { isMember = false; break }
    }

    return isMember
}

func isValidIdentifierSignalCharacter(c: Character?) -> Bool {
    return isCharacterPartOfSet(c, set: NSCharacterSet.letterCharacterSet()) 
}

func isValidIdenitifierCharacter(c: Character?) -> Bool {
    return isCharacterPartOfSet(c, set: NSCharacterSet.letterCharacterSet()) || c == "-" || c == "." || c == "/"
}

func isWhitespace(c: Character?) -> Bool {
    return isCharacterPartOfSet(c, set: NSCharacterSet.whitespaceCharacterSet())
}

final public class Lexer {
    var scanner: Scanner
    var current: Token? = nil
    
    var shouldStall = false
    
    public init(scanner: Scanner) {
        self.scanner = scanner
    }

    public func next() -> Token? {
        if shouldStall {
            shouldStall = false
            return current
        }
        
        func work() -> Token {
            if scanner.next() == nil { return Token(type: .EOF) }

            scanner.stall()

            while let info = scanner.next() where isWhitespace(info.character) {}
            scanner.stall()

            guard let next = scanner.next() else { return Token(type: .EOF) }

            if next.character == "\n" {
                return Token(type: .Terminal, value: "\n", line: next.line, column: next.column)
            }
            else if isValidIdentifierSignalCharacter(next.character) {
                var content = String(next.character!)
                while let info = scanner.next() where isValidIdenitifierCharacter(info.character) {
                    content.append(info.character!)
                }
                scanner.stall()

                return Token(type: .Identifier, value: content, line: next.line, column: next.column)
            }
            else if next.character == "(" {
                return Token(type: .OpenParen, value: "(", line: next.line, column: next.column)
            }
            else if next.character == ")" {
                return Token(type: .CloseParen, value: ")", line: next.line, column: next.column)
            }
            else if next.character == "[" {
                return Token(type: .OpenBracket, value: "[", line: next.line, column: next.column)
            }
            else if next.character == "]" {
                return Token(type: .CloseBracket, value: "]", line: next.line, column: next.column)
            }
            else if next.character == "{" {
                return Token(type: .OpenBrace, value: "{", line: next.line, column: next.column)
            }
            else if next.character == "}" {
                return Token(type: .CloseBrace, value: "}", line: next.line, column: next.column)
            }
            else if next.character == ":" {
                return Token(type: .Colon, value: ":", line: next.line, column: next.column)
            }
            else if next.character == ";" {
                let column = scanner.peek()!.column
                let line = scanner.peek()!.line
                var comment = ""

                while let info = scanner.next() where info.character == ";" {}
                scanner.stall()
                
                while let info = scanner.next() where info.character != "\n" {
                    comment.append(info.character!)
                }

                return Token(type: .Comment, value: comment, line: line, column: column)
            }
            else if next.character == "\"" {
                var content = ""
                while let info = scanner.next() where info.character != "\"" {
                    content.append(info.character!)
                }

                return Token(type: .StringLiteral, value: content, line: next.line, column: next.column)
            }
            else {
                return Token(type: .Unknown, value: String(next.character!), line: next.line, column: next.column)
            }
        }

        if self.current?.type == .EOF {
            self.current = nil
        }
        else {
            self.current = work()
        }
        
        return self.current
    }

    func tokenize() -> [Token] {
        var tokens = [Token]()

        while let token = self.next() { tokens.append(token) }

        return tokens
    }

    public func peek() -> Token? {
        return current
    }
    
    public func stall() {
        shouldStall = true
    }
}