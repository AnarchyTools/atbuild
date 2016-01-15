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

class LexerTests: Test {
    required init() {}
    let tests = [
        LexerTests.testBasicClj
    ]

    let filename = __FILE__
        
    static func testBasicClj() throws {
        let filepath = "./parsers/clj/tests/collateral/basic.clj"

        let content: String = try NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) as String
        let scanner = Scanner(content: content)
        let lexer = Lexer(scanner: scanner)
        
        try test.assert(Token.isEqual(lexer.next(), to: Token.Comment(" This is the most basic of sample files.", line: 0, column: 0)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 1, column: 0)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.OpenParen(line: 2, column: 0)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("project", line: 2, column: 1)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 2, column: 8)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 3, column: 2)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("name", line: 3, column: 3)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"basic\"", line: 3, column: 8)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 3, column: 15)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 4, column: 2)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("version", line: 4, column: 3)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"0.1.0-dev\"", line: 4, column: 11)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 4, column: 22)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 5, column: 2)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 6, column: 2)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("tasks", line: 6, column: 3)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.OpenBrace(line: 6, column: 9)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 6, column: 10)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("build", line: 6, column: 11)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.OpenBrace(line: 6, column: 17)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 6, column: 18)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("tool", line: 6, column: 19)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"lldb-build\"", line: 6, column: 24)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 6, column: 36)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 7, column: 18)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("name", line: 7, column: 19)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"json-swift\"", line: 7, column: 24)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 7, column: 36)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 8, column: 18)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("output-type", line: 8, column: 19)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"lib\"", line: 8, column: 31)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 8, column: 37)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Colon(line: 9, column: 18)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Identifier("source", line: 9, column: 19)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.OpenBracket(line: 9, column: 26)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.StringLiteral("\"src/**.swift\"", line: 9, column: 28)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.CloseBracket(line: 9, column: 43)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.CloseBrace(line: 9, column: 44)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.CloseBrace(line: 9, column: 45)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 9, column: 46)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.CloseParen(line: 10, column: 0)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.Terminal(line: 10, column: 1)))
        try test.assert(Token.isEqual(lexer.next(), to: Token.EOF))
    }
}