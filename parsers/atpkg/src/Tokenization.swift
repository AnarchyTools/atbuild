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

public enum Token {
    case Identifier(String, line: Int, column: Int)
    case OpenParen(line: Int, column: Int)
    case CloseParen(line: Int, column: Int)
    case OpenBracket(line: Int, column: Int)
    case CloseBracket(line: Int, column: Int)
    case OpenBrace(line: Int, column: Int)
    case CloseBrace(line: Int, column: Int)
    case StringLiteral(String, line: Int, column: Int)
    case Terminal(line: Int, column: Int)
    case Colon(line: Int, column: Int)
    case Comment(String, line: Int, column: Int)
    
    case Unhandled(String, line: Int, column: Int)
    
    case EOF

    var stringValue: String {
        switch self {
        case let .StringLiteral(value, _, _): return value
        default: return ""
        }
    }
    
    public static func isEqual(lhs: Token?, to rhs: Token?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        
        guard let lhs = lhs else { return false }
        guard let rhs = rhs else { return false }
        
        switch (lhs, rhs) {
        case let (.Identifier(l0, l1, l2), .Identifier(r0, r1, r2)): return l0 == r0 && l1 == r1 && l2 == r2
        case let (.StringLiteral(l0, l1, l2), .StringLiteral(r0, r1, r2)): return l0 == r0 && l1 == r1 && l2 == r2
        case let (.Comment(l0, l1, l2), .Comment(r0, r1, r2)): return l0 == r0 && l1 == r1 && l2 == r2
        case let (.Unhandled(l0, l1, l2), .Unhandled(r0, r1, r2)): return l0 == r0 && l1 == r1 && l2 == r2

        case let (.OpenParen(l0, l1), .OpenParen(r0, r1)): return l0 == r0 && l1 == r1
        case let (.CloseParen(l0, l1), .CloseParen(r0, r1)): return l0 == r0 && l1 == r1
        case let (.OpenBracket(l0, l1), .OpenBracket(r0, r1)): return l0 == r0 && l1 == r1
        case let (.CloseBracket(l0, l1), .CloseBracket(r0, r1)): return l0 == r0 && l1 == r1
        case let (.OpenBrace(l0, l1), .OpenBrace(r0, r1)): return l0 == r0 && l1 == r1
        case let (.CloseBrace(l0, l1), .CloseBrace(r0, r1)): return l0 == r0 && l1 == r1
        case let (.Terminal(l0, l1), .Terminal(r0, r1)): return l0 == r0 && l1 == r1
        case let (.Colon(l0, l1), .Colon(r0, r1)): return l0 == r0 && l1 == r1
        
        case (.EOF, .EOF): return true
        
        default: return false
        }
    }
    
    public static func isEquivalent(lhs: Token?, to rhs: Token?) -> Bool {
        if lhs == nil && rhs == nil { return true }
        
        guard let lhs = lhs else { return false }
        guard let rhs = rhs else { return false }
        
        switch (lhs, rhs) {
        case let (.Identifier(l0, _, _), .Identifier(r0, _, _)): return l0 == r0
        case let (.StringLiteral(l0, _, _), .StringLiteral(r0, _, _)): return l0 == r0
        case let (.Comment(l0, _, _), .Comment(r0, _, _)): return l0 == r0
        case let (.Unhandled(l0, _, _), .Unhandled(r0, _, _)): return l0 == r0

        case (.OpenParen, .OpenParen): return true
        case (.CloseParen, .CloseParen): return true
        case (.OpenBracket, .OpenBracket): return true
        case (.CloseBracket, .CloseBracket): return true
        case (.OpenBrace, .OpenBrace): return true
        case (.CloseBrace, .CloseBrace): return true
        case (.Terminal, .Terminal): return true
        case (.Colon, .Colon): return true
        
        case (.EOF, .EOF): return true
        
        default: return false
        }
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

public class Lexer {

    var scanner: Scanner
    var current: Token? = nil
    
    public init(scanner: Scanner) {
        self.scanner = scanner
    }

    public func next() -> Token? {
        func work() -> Token {
            if scanner.next() == nil { return .EOF }

            scanner.stall()

            while let info = scanner.next() where isWhitespace(info.character) {}
            scanner.stall()

            guard let next = scanner.next() else { return .EOF }

            if next.character == "\n" {
                return .Terminal(line: next.line, column: next.column)
            }
            else if isValidIdentifierSignalCharacter(next.character) {
                var content = String(next.character!)
                while let info = scanner.next() where isValidIdenitifierCharacter(info.character) {
                    content.append(info.character!)
                }
                scanner.stall()

                return .Identifier(content, line: next.line, column: next.column)
            }
            else if next.character == "(" {
                return .OpenParen(line: next.line, column: next.column)
            }
            else if next.character == ")" {
                return .CloseParen(line: next.line, column: next.column)
            }
            else if next.character == "[" {
                return .OpenBracket(line: next.line, column: next.column)
            }
            else if next.character == "]" {
                return .CloseBracket(line: next.line, column: next.column)
            }
            else if next.character == "{" {
                return .OpenBrace(line: next.line, column: next.column)
            }
            else if next.character == "}" {
                return .CloseBrace(line: next.line, column: next.column)
            }
            else if next.character == ":" {
                return .Colon(line: next.line, column: next.column)
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

                return .Comment(comment, line: line, column: column)
            }
            else if next.character == "\"" {
                var content = String(next.character!)
                while let info = scanner.next() where info.character != "\"" {
                    content.append(info.character!)
                }
                content.append(scanner.peek()!.character!)

                return .StringLiteral(content, line: next.line, column: next.column)
            }
            else {
                return .Unhandled(String(next.character!), line: next.line, column: next.column)
            }
        }

        if case .EOF? = self.current {
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
}