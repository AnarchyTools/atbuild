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

public enum OutputType {
    case Executable
    case StaticLibrary
    case DynamicLibrary
}

public class FilePath {
    public var path: String
    
    public var expandedItems: [String] {
        get { return [] }
    }
    
    public init(path: String) {
        self.path = path
    }
}

public class Dependency {
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
}

public class Task {
    // The required properties.
    public var name: String

    // The optional properties. All optional properties must have a default value.
    public var dependencies: [Dependency] = []
    public var tool: String = "atllbuild"
    public var source: [FilePath] = []
    public var version: String = ""
    public var bootstrapOnly: Bool = false
    public var llbuildyaml: String = ""
    public var linkSDK: Bool = false
    public var compilerOptions: [String] = []
    public var outputType: OutputType = OutputType.StaticLibrary
    public var linkWithProduct: [String] = []
    
    public init(name: String) {
        self.name = name
    }
}

public class Package {
    public var name: String
    public var tasks: [Task] = []
    
    public init(name: String) {
        self.name = name
    }
}