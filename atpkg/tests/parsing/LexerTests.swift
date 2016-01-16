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
import atpkg

func outputBaseline(lexer: Lexer) {
    print("--- baseline ---")
    while let token = lexer.next() {
        let type = String(reflecting: token.type).stringByReplacingOccurrencesOfString("atpkgparser.", withString: "")
        var value = ""
        
        switch token.type {
        case .Terminal: value = "\\n"
        default: value = token.value
        }
        
        let output = "try test.assert(lexer.next() == Token(type: \(type), value: \"\(value)\", line: \(token.line), column: \(token.column)))"
        print(output)
    }
    print("--- end baseline ---")
}
    
class LexerTests: Test {
    required init() {}
    let tests = [
        LexerTests.testBasic
    ]

    let filename = __FILE__
        
    static func testBasic() throws {
        let filepath = "./atpkg/tests/collateral/basic.atpkg"

        let content: String = try NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) as String
        let scanner = Scanner(content: content)
        let lexer = Lexer(scanner: scanner)
        
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Comment, value: " This is the most basic of sample files.", line: 0, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 1, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenParen, value: "(", line: 2, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "package", line: 2, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 2, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 3, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "name", line: 3, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "basic", line: 3, column: 8))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 3, column: 15))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 4, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "version", line: 4, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "0.1.0-dev", line: 4, column: 11))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 4, column: 22))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 5, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 6, column: 2))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "tasks", line: 6, column: 3))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBrace, value: "{", line: 6, column: 9))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 6, column: 10))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "build", line: 6, column: 11))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBrace, value: "{", line: 6, column: 17))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 6, column: 18))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "tool", line: 6, column: 19))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lldb-build", line: 6, column: 24))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 6, column: 36))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 7, column: 18))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "name", line: 7, column: 19))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "json-swift", line: 7, column: 24))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 7, column: 36))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 8, column: 18))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "output-type", line: 8, column: 19))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lib", line: 8, column: 31))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 8, column: 37))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Colon, value: ":", line: 9, column: 18))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Identifier, value: "source", line: 9, column: 19))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.OpenBracket, value: "[", line: 9, column: 26))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "src/**.swift", line: 9, column: 28))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.StringLiteral, value: "lib/**.swift", line: 9, column: 43))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBracket, value: "]", line: 9, column: 58))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBrace, value: "}", line: 9, column: 59))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseBrace, value: "}", line: 9, column: 60))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 9, column: 61))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.CloseParen, value: ")", line: 10, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 10, column: 1))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Terminal, value: "\n", line: 11, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.Comment, value: " End of the sample.", line: 12, column: 0))
        try test.assert(lexer.next() == Token(type: atpkg.TokenType.EOF, value: "", line: 0, column: 0))
    }
}