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
    
    public convenience init?(filepath: String, configurations: [String: String] = [:]) {
        guard let parser = Parser(filepath: filepath) else { return nil }
        
        do {
            let result = try parser.parse()
            self.init(type: result, configurations: configurations)
        }
        catch {
            print("error: \(error)")
            return nil
        }
    }
    
    public init?(type: ParseType, configurations: [String: String]) {
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

        //swap in configurations
        for requestedConfiguration in configurations.keys {
            let requestedConfigurationValue = configurations[requestedConfiguration]!
            //find the overrides specific to this configuration
            guard let parsedConfigurations = type.properties["configurations"]?.map else {
                fatalError("You requested configuration --\(requestedConfiguration) but no configurations were present in the package file.")
            }
            guard let parsedConfiguration = parsedConfigurations[requestedConfiguration]?.map else {
                fatalError("You requested configuration --\(requestedConfiguration) but we only have \(Array(parsedConfigurations.keys))")
            }
            guard let overrideSpecifications = parsedConfiguration[requestedConfigurationValue]?.map else {
                fatalError("You requested configuration --\(requestedConfiguration) \(requestedConfigurationValue) but we only have \(Array(parsedConfiguration.keys))")
            }
            for taskSpec in overrideSpecifications.keys {
                guard let overrideSpecification = overrideSpecifications[taskSpec]?.map else {
                    fatalError("Cannot get override specification for --\(requestedConfiguration) \(requestedConfigurationValue)")
                }
                if let task = tasks[taskSpec] {
                    for(k,v) in overrideSpecification {
                        task.kvp[k] = v
                    }
                }
                else {
                    fatalError("Global configurations not implemented; can't configure option \(requestedConfigurationValue) for non-task spec \(taskSpec)")
                }
            }
        }
    }
}