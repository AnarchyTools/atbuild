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
    
    public init(path: String) {
        self.path = path
    }

    init?(value: ParseValue) {
        guard let str = value.stringLiteral else { return nil }
        self.path = str
    }
}

public class Dependency {
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
    
    init?(value: ParseValue) {
        guard let str = value.stringLiteral else { return nil }
        self.name = str
    }
}

public class Task {
    // The required properties.
    public var name: String

    // The optional properties. All optional properties must have a default value.
    public var dependencies: [Dependency] = []
    public var tool: String = "atllbuild"
    public var sources: [FilePath] = []
    public var bootstrapOnly: Bool = false
    public var llbuildyaml: String = ""
    public var linkSDK: Bool = false
    public var compilerOptions: [String] = []
    public var outputType: OutputType = OutputType.StaticLibrary
    public var linkWithProduct: [String] = []
    
    public init(name: String) {
        self.name = name
    }
    
    init?(value: ParseValue, name: String) {
        guard let kvp = value.map else { return nil }

        if let value = kvp["name"]?.stringLiteral { self.name = value }
        else {
            print("ERROR: Name is a required property on task.")
            return nil
        }
        
        if let value = kvp["tool"]?.stringLiteral { self.tool = value }
        if let value = kvp["bootstrapOnly"]?.boolLiteral { self.bootstrapOnly = value }
        if let value = kvp["llbuildyaml"]?.stringLiteral { self.llbuildyaml = value }
        if let value = kvp["linkSDK"]?.boolLiteral { self.linkSDK = value }
        if let value = kvp["outputType"]?.stringLiteral {
            switch value {
            case "lib": self.outputType = .StaticLibrary
            case "static-library": self.outputType = .StaticLibrary
            
            case "dylib": self.outputType = .DynamicLibrary
            case "dynamic-library": self.outputType = .DynamicLibrary
            
            case "exe": self.outputType = .Executable
            case "executable": self.outputType = .Executable
            
            default: print("ERROR: unsupported outputType: \(value), defaulting to: \(self.outputType)")
            }
        }
        
        if let values = kvp["dependencies"]?.vector {
            for value in values {
                if let dep = Dependency(value: value) { self.dependencies.append(dep) }
            }
        }

        if let values = kvp["sources"]?.vector {
            for value in values {
                if let filepath = FilePath(value: value) { self.sources.append(filepath) }
            }
        }
        if let values = kvp["source"]?.vector {
            for value in values {
                if let filepath = FilePath(value: value) { self.sources.append(filepath) }
            }
        }

        if let values = kvp["compilerOptions"]?.vector {
            for value in values {
                if let value = value.stringLiteral { self.compilerOptions.append(value) }
            }
        }

        if let values = kvp["linkWithProduct"]?.vector {
            for value in values {
                if let value = value.stringLiteral { self.linkWithProduct.append(value) }
            }
        }
    }
}

public class Package {
    // The required properties.
    public var name: String
    
    // The optional properties. All optional properties must have a default value.
    public var version: String = ""
    public var tasks: [String:Task] = [:]
    
    public init(name: String) {
        self.name = name
    }
    
    public init?(type: ParseType) {
        if type.name != "package" { return nil }
        
        if let value = type.properties["name"]?.stringLiteral { self.name = value }
        else {
            print("ERROR: No name specified for the package.")
            return nil
        }
        if let value = type.properties["version"]?.stringLiteral { self.version = value }

        if let parsedTasks = type.properties["tasks"]?.map {
            for (key, value) in parsedTasks {
                if let task = Task(value: value, name: key) {
                    self.tasks[key] = task
                }
            }
        }
    }
}