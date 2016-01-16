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

final public class Task {
    public var key: String = ""
    public var dependencies: [String] = []
    public var tool: String = "atllbuild"
    
    private var kvp: [String:ParseValue]

    init?(value: ParseValue, name: String) {
        guard let kvp = value.map else { return nil }
        
        self.kvp = kvp
        self.key = name
        self.tool = kvp["tool"]?.string ?? self.tool
        
        if let values = kvp["dependencies"]?.vector {
            for value in values {
                if let dep = value.string { self.dependencies.append(dep) }
            }
        }
    }
    
    public subscript(key: String) -> ParseValue? {
        return kvp[key]
    }
}

final public class Package {
    // The required properties.
    public var name: String
    
    // The optional properties. All optional properties must have a default value.
    public var version: String = ""
    public var tasks: [String:Task] = [:]
    
    public init(name: String) {
        self.name = name
    }
    
    public convenience init?(filepath: String) {
        guard let parser = Parser(filepath: filepath) else { return nil }
        
        do {
            let result = try parser.parse()
            self.init(type: result)
        }
        catch {
            print("error: \(error)")
            return nil
        }
    }
    
    public init?(type: ParseType) {
        if type.name != "package" { return nil }
        
        if let value = type.properties["name"]?.string { self.name = value }
        else {
            print("ERROR: No name specified for the package.")
            return nil
        }
        if let value = type.properties["version"]?.string { self.version = value }

        if let parsedTasks = type.properties["tasks"]?.map {
            for (key, value) in parsedTasks {
                if let task = Task(value: value, name: key) {
                    self.tasks[key] = task
                }
            }
        }
    }
}