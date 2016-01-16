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

public enum ParseError: ErrorType {
    case InvalidPackageFile
    case ExpectedTokenType(TokenType, Token?)
    case InvalidTokenForValueType(Token?)
}

public enum ParseValue {
    case StringLiteral(String)
    case IntegerLiteral(Int)
    case FloatLiteral(Double)
    case BoolLiteral(Bool)
    
    case Map([String:ParseValue])
    case Vector([ParseValue])
}

extension ParseValue {
    public var stringLiteral: String? {
        if case let .StringLiteral(value) = self { return value }
        return nil
    }
    
    public var integerLiteral: Int? {
        if case let .IntegerLiteral(value) = self { return value }
        return nil
    }

    public var floatLiteral: Double? {
        if case let .FloatLiteral(value) = self { return value }
        return nil
    }

    public var boolLiteral: Bool? {
        if case let .BoolLiteral(value) = self { return value }
        return nil
    }
    
    public var map: [String:ParseValue]? {
        if case let .Map(value) = self { return value }
        return nil
    }
    
    public var vector: [ParseValue]? {
        if case let .Vector(value) = self { return value }
        return nil
    }
}


public class ParseType {
    public var name: String = ""
    public var properties: [String:ParseValue] = [:]
}

public class Parser {
    let lexer: Lexer
    
    private func next() -> Token? {
        while true {
            guard let token = lexer.next() else { return nil }
            if token.type != .Comment && token.type != .Terminal {
                return lexer.peek()
            }
        }
    }
    
    public init?(filepath: String) {
        guard let content = try? NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) else {
            return nil
        }
        
        let scanner = Scanner(content: content as String)
        self.lexer = Lexer(scanner: scanner)
    }
    
    public func parse() throws -> ParseType {
        guard let token = next() else { throw ParseError.InvalidPackageFile }
        
        if token.type == .OpenParen {
            return try parseType()
        }
        else {
            throw ParseError.ExpectedTokenType(.OpenParen, token)
        }
    }
    
    private func parseType() throws -> ParseType {
        let type = ParseType()
        type.name = try parseIdentifier()
        
        type.properties = try parseKeyValuePairs()
        return type
    }
    
    private func parseKeyValuePairs() throws -> [String:ParseValue] {
        var pairs: [String:ParseValue] = [:]

        while let token = next() where token.type != .CloseParen && token.type != .CloseBrace {
            lexer.stall()
            
            let key = try parseKey()
            let value = try parseValue()
            
            pairs[key] = value
        }
        lexer.stall()

        return pairs
    }
    
    private func parseKey() throws -> String {
        let colon = next()
        if colon?.type != .Colon { throw ParseError.ExpectedTokenType(.Colon, lexer.peek()) }
        
        return try parseIdentifier()
    }
    
    private func parseIdentifier() throws -> String {
        guard let identifier = next() else { throw ParseError.ExpectedTokenType(.Identifier, lexer.peek()) }
        if identifier.type != .Identifier { throw ParseError.ExpectedTokenType(.Identifier, lexer.peek()) }
        
        return identifier.value
    }
    
    private func parseValue() throws -> ParseValue {
        guard let token = next() else { throw ParseError.InvalidTokenForValueType(nil) }
        
        switch token.type {
        case .OpenBrace: lexer.stall(); return try parseMap()
        case .OpenBracket: lexer.stall(); return try parseVector()
        case .StringLiteral: return .StringLiteral(token.value)
        case .Identifier where token.value == "true": return .BoolLiteral(true)
        case .Identifier where token.value == "false": return .BoolLiteral(false)
        default: throw ParseError.InvalidTokenForValueType(token)
        }
    }
    
    private func parseVector() throws -> ParseValue {
        if let token = next() where token.type != .OpenBracket { throw ParseError.ExpectedTokenType(.OpenBracket, token) }
        var items: [ParseValue] = []
        
        while let token = next() where token.type != .CloseBracket {
            lexer.stall()
            items.append(try parseValue())
        }
        lexer.stall()

        if let token = next() where token.type != .CloseBracket { throw ParseError.ExpectedTokenType(.CloseBracket, token) }

        return .Vector(items)
    }
    
    private func parseMap() throws -> ParseValue {
        if let token = next() where token.type != .OpenBrace { throw ParseError.ExpectedTokenType(.OpenBrace, token) }
        let items = try parseKeyValuePairs()
        if let token = next() where token.type != .CloseBrace { throw ParseError.ExpectedTokenType(.CloseBrace, token) }
        
        return .Map(items)
    }
}
