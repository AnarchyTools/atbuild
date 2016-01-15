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

import atpkgmodel
import Foundation

public enum PackageParserError: ErrorType {
    case PackageFileDoesNotExist(filename: String)
    case MissingPackageDeclaration
    case InvalidPackageFile
    case UnexpectedToken(expected: Token, actual: Token)
    case MissingToken(expected: Token)
}

extension Lexer {
    func parseableNext() -> Token? {
        while true {
            guard let token = self.next() else { return nil }
            if case .Comment = token {}
            else if case .Terminal = token {}
            else { return self.peek() }
        }
    }
    
    func take(expected: Token) throws {
        guard let token = self.parseableNext() else { throw PackageParserError.MissingToken(expected: expected) }
        if !Token.isEquivalent(expected, to: token) { throw PackageParserError.UnexpectedToken(expected: expected, actual: token) }
    }
}

public func parsePackageDefinition(filepath: String) throws -> Package {
    guard let content: String = try? NSString(contentsOfFile: filepath, encoding: NSUTF8StringEncoding) as String else {
        throw PackageParserError.PackageFileDoesNotExist(filename: filepath)
    }
    
    let scanner = Scanner(content: content)
    let lexer = Lexer(scanner: scanner)
    
    try lexer.take(.OpenParen(line: 0, column: 0))
    try lexer.take(.Identifier("package", line: 0, column: 0))

    // TODO: Parse the properties of the package definition.
    
    try lexer.take(.CloseParen(line: 0, column: 0))
    try lexer.take(.EOF)
    
    let package = Package(name: "nope")
    return package
}
