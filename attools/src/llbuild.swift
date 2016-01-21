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

#if os(Linux)
    import Glibc //need sleep
#endif


/**
 * This is a representation of the package file format used by llbuild.
 */
struct SwiftBuildToolPackageFileFormat {
    
    /*
     * NOTE!!! The Swift Build Tool's file format is a super big unknown
     * at the moment. It's not document and YAML is the only the initial
     * implementation for the sake of getting off the ground quickly.
     * This stuff is likely to change a lot over the course of Swift
     * development.
     */
    
    struct Client {
        var name: String
    }
    
    struct Target {
        var tool: String
        var sources: [String]? = nil
        var outputs: [String]? = nil
        var objects: [String]? = nil
        var moduleName: String? = nil
        var moduleOutputPath: String? = nil
        var tempsPath: String? = nil
        var otherArgs: [String]? = nil
    }
    
    var client: Client
    var targets: [String:[String]]
    var commands: [String:Target]
}

extension SwiftBuildToolPackageFileFormat {
    /**
     * Returns the YAML representation of the package file.
     */
    func toYaml(indent: String = "  ") -> String {
        func appendIndent(inout str: String, indentLevel: Int) {
            for _ in 0..<indentLevel {
                str += indent
            }
        }
        func appendValue(inout str: String, name: String, value: String?, indentLevel: Int) {
            if let value = value {
                appendString(&str, value: "\(name): \(value)", indentLevel: indentLevel)
            }
        }
        func appendMap(inout str: String, map: [String:[String]], indentLevel: Int) {
            for (key, value) in map {
                appendList(&str, name: key, items: value, indentLevel: indentLevel)
            }
        }
        func appendList(inout str: String, name: String, items: [String]?, indentLevel: Int) {
            if let items = items {
                
                let name = name == "" ? "\"\"" : name
                
                if items.count == 0 {
                    appendValue(&str, name: name, value: "[]", indentLevel: indentLevel)
                }
                else if items.count == 1 {
                    appendValue(&str, name: name, value: "[\(items[0])]", indentLevel: indentLevel)
                }
                else {
                    appendString(&str, value: "\(name):", indentLevel: indentLevel)
                    for item in items {
                        appendIndent(&str, indentLevel: indentLevel + 1)
                        str += "- \(item)\n"
                    }
                }
            }
        }
        func appendString(inout str: String, value: String, indentLevel: Int) {
            appendIndent(&str, indentLevel: indentLevel)
            str += "\(value)\n"
        }
        
        var string = ""
        
        string = "client:\n"
        appendValue(&string, name: "name", value: client.name, indentLevel: 1)
        
        string += "\n"
        
        string += "targets:\n"
        appendMap(&string, map: targets, indentLevel: 1)
        
        string += "\n"
        
        string += "commands:\n"
        for (name, target) in commands {
            let indentLevel = 1

            appendString(&string, value: "\(name):", indentLevel: indentLevel)
            
            appendValue(&string, name: "tool", value: target.tool, indentLevel: indentLevel + 1)
            appendList(&string, name: "sources", items: target.sources, indentLevel: indentLevel + 1)
            appendList(&string, name: "outputs", items: target.outputs, indentLevel: indentLevel + 1)
            appendList(&string, name: "objects", items: target.objects, indentLevel: indentLevel + 1)
            appendValue(&string, name: "module-name", value: target.moduleName, indentLevel: indentLevel + 1)
            appendValue(&string, name: "module-output-path", value: target.moduleOutputPath, indentLevel: indentLevel + 1)
            appendValue(&string, name: "temps-path", value: target.tempsPath, indentLevel: indentLevel + 1)
            appendList(&string, name: "other-args", items: target.otherArgs, indentLevel: indentLevel + 1)
        }
        
        return string
    }
}

/**
 * The `llbuild.swift` file contains all of the tools necessary to work
 * with the swift-build-tool (llbuild) low-level build system. There are
 * three tools contained here:
 *
 *    1. llbuild-config - this tool is reponsible for generate the build
 *       configuration file necessary for llbuild to consume.
 *    2. llbuild-build - this tool is responsible for consuming a build
 *       configuration file and producing the appropriate outputs.
 *    3. llbuild - this is a wrapper tool that provides a simple syntax
 *       to merge the previous two tools together.
 */

/**
 * This tool handles the generation of the configuration file for the
 * llbuild tool (`swift-build-tool`).
 */
final class SwiftBuildToolConfig: Tool {
    enum ConfigurationFormat {
        case Yaml
    }
    
    static let defaultFormat = ConfigurationFormat.Yaml
    
    /**
     * Validates the options given to the task. If any of the options
     * are not supported, then a message is displayed and `false` is
     * return; otherwise `true` is returned.
     */
    func validateOptions(task: ConfigMap) -> Bool {
        var valid = true
        let knownOptions = ["tool",
                            "name",
                            "dependencies",
                            "output-type",
                            "source",
                            "llbuild-config",
                            "compile-options",
                            "link-options",
                            "link-sdk",
                            "link-with-product",
                            "swiftc-path",
                            "xctestify",
                            "xctest-strict"]
        for (key, _) in task {
            if !knownOptions.contains(key) {
                print("Warning: unknown option \(key) for task.")
                valid = false
            }
        }
        
        return valid
    }
    
    func run(package: Package, task: ConfigMap) {
        let workingDirectory = StandardizedToolPaths.CurrentDirectory
        let manager = NSFileManager.defaultManager()
        
        print("config!!")
        
        //NSFileManager is pretty anal about throwing errors if we try to remove something that doesn't exist, etc.
        //We just want to create a state where .atllbuild/objects and .atllbuild/llbuildtmp and .atllbuild/products exists.
        //and in particular, without erasing the product directory, since that accumulates build products across
        //multiple invocations of atllbuild.
        // let _ = try? manager.removeItemAtPath(workDirectory + "/objects")
        // let _ = try? manager.removeItemAtPath(workDirectory + "/llbuildtmp")
        // let _ = try? manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        // let _ = try? manager.createDirectoryAtPath(workDirectory + "/products", withIntermediateDirectories: false, attributes: nil)
        // let _ = try? manager.createDirectoryAtPath(workDirectory + "/objects", withIntermediateDirectories: false, attributes: nil)

        // //parse arguments
        // var linkWithProduct: [String] = []
        // if let arr = task["linkWithProduct"]?.vector {
        //     for product in arr {
        //         guard let p = product.string else { fatalError("non-string product \(product)") }
        //         linkWithProduct.append(p)
        //     }
        // }
        // let outputType: OutputType
        // if task["outputType"]?.string == "static-library" {
        //     outputType = .StaticLibrary
        // }
        // else if task["outputType"]?.string == "executable" {
        //     outputType = .Executable
        // }
        // else {
        //     fatalError("Unknown outputType \(task["outputType"])")
        // }
        
        // var compileOptions: [String] = []
        // if let opts = task["compileOptions"]?.vector {
        //     for o in opts {
        //         guard let os = o.string else { fatalError("Compile option \(o) is not a string") }
        //         compileOptions.append(os)
        //     }
        // }
        // var linkOptions: [String] = []
        // if let opts = task["linkOptions"]?.vector {
        //     for o in opts {
        //         guard let os = o.string else { fatalError("Link option \(o) is not a string") }
        //         linkOptions.append(os)
        //     }
        // }
        
        // guard let sourceDescriptions = task["source"]?.vector?.flatMap({$0.string}) else { fatalError("Can't find sources for atllbuild.") }
        // var sources = collectSources(sourceDescriptions, task: task)
        
        // //xctestify
        // if task["xctestify"]?.bool == true {
        //     precondition(outputType == .Executable, "You must use outputType: executable with xctestify.")
        //     //inject platform-specific flags
        //     #if os(OSX)
        //         compileOptions.appendContentsOf(["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/"])
        //         linkOptions.appendContentsOf(["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-target", "x86_64-apple-macosx10.11", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-Xlinker", "-bundle"])
        //     #endif
        // }
        // if task["xctestStrict"]?.bool == true {
        //     #if os(OSX)
        //     //inject XCTestCaseProvider.swift
        //     var xcTestCaseProviderPath = "/tmp/XXXXXXX"
        //     var template = xcTestCaseProviderPath.cStringUsingEncoding(NSUTF8StringEncoding)!
        //     xcTestCaseProviderPath = String(CString: mkdtemp(&template), encoding: NSUTF8StringEncoding)!
        //     xcTestCaseProviderPath += "/XCTestCaseProvider.swift"
        //     try! ATllbuild.xcTestCaseProvider.writeToFile(xcTestCaseProviderPath, atomically: false, encoding: NSUTF8StringEncoding)
        //     sources.append(xcTestCaseProviderPath)
        //     #endif
        // }

        // guard let name = task["name"]?.string else { fatalError("No name for atllbuild task") }
        
        // let bootstrapOnly: Bool

        // if task["bootstrapOnly"]?.bool == true {
        //     bootstrapOnly = true
        // }
        // else {
        //     bootstrapOnly = false
        // }
        
        // let sdk: Bool
        // if task["linkSDK"]?.bool == false {
        //     sdk = false
        // }
        // else { sdk = true }
        
        // let llbuildyamlpath : String

        // if let value = task["llbuildyaml"]?.string {
        //     llbuildyamlpath = value
        // }
        // else {
        //     llbuildyamlpath = workDirectory + "llbuild.yaml"
        // }

        // let swiftCPath: String
        // if let c = task["swiftCPath"]?.string {
        //     swiftCPath = c
        // }
        // else {
        //     swiftCPath = SwiftCPath
        // }
        
        // let yaml = llbuildyaml(sources, workdir: workDirectory, modulename: name, linkSDK: sdk, compileOptions: compileOptions, linkOptions: linkOptions, outputType: outputType, linkWithProduct: linkWithProduct, swiftCPath: swiftCPath)
        // let _ = try? yaml.writeToFile(llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
    }
}

/**
 * This tool handles the production of outputs based on a specified
 * configuration file.
 */
final class SwiftBuildToolBuild: Tool {
    func run(package: Package, task: ConfigMap) {
        
    }
}

/**
 * This is a friendly front-end wrapper for both the `SwiftBuildToolBuild`
 * and `SwiftBuildToolConfig` tools.
 */
final class SwiftBuildTool: Tool {
    func run(package: Package, task: ConfigMap) {
        
    }
}
