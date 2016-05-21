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

public enum Configuration  {
    ///Built-in configurations

    ///The default configuration.
    ///Choose settings suitable for interactive debugging, like O0, -g, etc.
    ///Generally, operations that slow down compile times should be avoided.
    case Debug

    ///A configuration appropriate for distribution.
    ///Choose settings suitable for final, production-quality software.
    case Release

    ///A configuration appropriate for unit (correctness) tests.
    case Test

    ///A configuration appropriate for performance-sensitive tests or benchmarks
    case Benchmark

    ///A "plain" or "no-magic" configuration
    ///Do not assume anything about the user's intent
    ///Provide only default behavior
    case None

    ///Like "None", but with a custom name.
    case User(String)

    public init(string: String) {
        if string == "debug" { self = .Debug }
        else if string == "release" { self = .Release }
        else if string == "test" { self = .Test }
        else if string == "bench" { self = .Benchmark }
        else if string == "none" { self = .None }
        else {self = .User(string)}
    }
}

extension Configuration:CustomStringConvertible {
    public var description: String {
        switch(self) {
            case .Debug: return "debug"
            case .Release: return "release"
            case .Test: return "test" 
            case .Benchmark: return "benchmark"
            case .None: return "none"
            case .User(let str): return str
        }
    }
}

/// The default configuration is Debug
///- warning: Switching on this value directly is discouraged; instead switch on one of its ivars.
public var currentConfiguration = Configuration.Debug

///Helper configuration options
///The following options may be more convenient than working with configurations directly
extension Configuration {

    ///Whether tools should produce optimized software
    var optimize: Bool? {
        switch(self) {
            case .Benchmark, .Release: return true
            case .Debug, .Test: return false
            case .User, .None: return nil
        }
    }

    ///Whether tools should prefer compile speed over compile quality
    var fastCompile: Bool? {
        switch(self) {
            case .Debug, .Test: return true
            case .Release, .Benchmark: return false
            case .User, .None: return nil
        }
    }

    ///Whether tools should compile "for testing".
    ///This value is appropriate for deciding whether to compile tests at all, or whether `-enable-testing` should be used
    var testingEnabled: Bool? {
        switch(self) {
            case .Benchmark, .Test: return true
            case .Debug, .Release: return false
            case .User, .None: return nil
        }
    }

    ///Whether tools are explicitly asked to compile "without magic"
    var noMagic: Bool? {
        switch(self) {
            case .Debug, .Release, .Benchmark, .Test: return false
            case .None: return true
            case .User: return nil
        }
    }
}