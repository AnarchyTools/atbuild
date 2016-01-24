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
import AnarchyPackage

#if os(Linux)
    import Glibc //need sleep
#endif

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
    enum Keys {
        static let Tool = "tool"
        static let Name = "name"
        static let ModuleName = "module-name"
        static let Depedencies = "dependencies"
        static let OutputType = "output-type"
        static let Sources = "sources"
        static let ConfigFile = "config-file"
        static let CompileOptions = "compile-options"
        static let LinkOptions = "link-options"
        static let LinkSDK = "link-sdk"
        static let LinkWithProduct = "link-with"
        static let SwiftPath = "swiftc-path"
        static let XCTestSupport = "xctestify"
        static let XCTestStrict = "xctest-strict"
        static let Overlays = "overlays"
    }
    
    enum OutputType {
        case Executable
        case StaticLibrary
    }
    
    enum ConfigurationFormat {
        case Yaml
    }
    
    static let defaultFormat = ConfigurationFormat.Yaml
    
    /**
     * Validates the options given to the task. If any of the options
     * are not supported, then a message is displayed and `false` is
     * return; otherwise `true` is returned.
     */
    func validateOptions(task: Task) -> Bool {
        var valid = true
        let knownOptions = [Keys.Tool,
                            Keys.Name,
                            Keys.ModuleName,
                            Keys.Depedencies,
                            Keys.OutputType,
                            Keys.Sources,
                            Keys.ConfigFile,
                            Keys.CompileOptions,
                            Keys.LinkOptions,
                            Keys.LinkSDK,
                            Keys.LinkWithProduct,
                            Keys.SwiftPath,
                            Keys.XCTestSupport,
                            Keys.XCTestStrict,
                            Keys.Overlays]
        for (key, _) in try! task.mergedConfig() {
            if !knownOptions.contains(key) {
                print("Warning: unknown option \(key) for task.")
                valid = false
            }
        }
        
        return valid
    }
    
    func run(task: Task) {
        validateOptions(task)
         //create the working directory
        let workDirectory = ".atllbuild/"
        let manager = NSFileManager.defaultManager()
        
        //NSFileManager is pretty anal about throwing errors if we try to remove something that doesn't exist, etc.
        //We just want to create a state where .atllbuild/objects and .atllbuild/llbuildtmp and .atllbuild/products exists.
        //and in particular, without erasing the product directory, since that accumulates build products across
        //multiple invocations of atllbuild.
        let _ = try? manager.removeItemAtPath(workDirectory + "/objects")
        let _ = try? manager.removeItemAtPath(workDirectory + "/llbuildtmp")
        let _ = try? manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectoryAtPath(workDirectory + "/products", withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectoryAtPath(workDirectory + "/objects", withIntermediateDirectories: false, attributes: nil)

        //parse arguments
        var linkWithProduct: [String] = []
        if let arr = task[Keys.LinkWithProduct]?.array {
            for product in arr {
                guard let p = product.string else { fatalError("non-string product \(product)") }
                linkWithProduct.append(p)
            }
        }
        let outputType: OutputType
        if task[Keys.OutputType]?.string == "static-library" {
            outputType = .StaticLibrary
        }
        else if task[Keys.OutputType]?.string == "executable" {
            outputType = .Executable
        }
        else {
            print(try! task.mergedConfig())
            fatalError("Unknown output-type \(task[Keys.OutputType])")
        }
        
        var compileOptions: [String] = []
        if let opts = task[Keys.CompileOptions]?.array {
            for o in opts {
                guard let os = o.string else { fatalError("Compile option \(o) is not a string") }
                compileOptions.append(os)
            }
        }
        var linkOptions: [String] = []
        if let opts = task[Keys.LinkOptions]?.array {
            for o in opts {
                guard let os = o.string else { fatalError("Link option \(o) is not a string") }
                linkOptions.append(os)
            }
        }
        
        guard let sourceDescriptions = task[Keys.Sources]?.array?.flatMap({$0.string}) else { fatalError("Can't find sources for \(try! task.mergedConfig()).") }
        var sources = collectSources(sourceDescriptions, task: task)
        
        //xctestify
        if task[Keys.XCTestSupport]?.bool == true {
            precondition(outputType == .Executable, "You must use outputType: executable with xctestify.")
            //inject platform-specific flags
            #if os(OSX)
                compileOptions.appendContentsOf(["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/"])
                linkOptions.appendContentsOf(["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-target", "x86_64-apple-macosx10.11", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-Xlinker", "-bundle"])
            #endif
        }
        if task[Keys.XCTestStrict]?.bool == true {
            #if os(OSX)
            //inject XCTestCaseProvider.swift
            var xcTestCaseProviderPath = "/tmp/XXXXXXX"
            var template = xcTestCaseProviderPath.cStringUsingEncoding(NSUTF8StringEncoding)!
            xcTestCaseProviderPath = String(CString: mkdtemp(&template), encoding: NSUTF8StringEncoding)!
            xcTestCaseProviderPath += "/XCTestCaseProvider.swift"
            try! SwiftBuildToolConfig.xcTestCaseProvider.writeToFile(xcTestCaseProviderPath, atomically: false, encoding: NSUTF8StringEncoding)
            sources.append(xcTestCaseProviderPath)
            #endif
        }

        guard let name = task[Keys.Name]?.string else { fatalError("No name for atllbuild task") }
        let modulename = task[Keys.ModuleName]?.string ?? name
        
        let sdk: Bool
        if task[Keys.LinkSDK]?.bool == false {
            sdk = false
        }
        else { sdk = true }
        
        let llbuildyamlpath : String

        if let value = task[Keys.ConfigFile]?.string {
            llbuildyamlpath = value
        }
        else {
            llbuildyamlpath = workDirectory + "llbuild.yaml"
        }

        let swiftCPath: String
        if let c = task[Keys.SwiftPath]?.string {
            swiftCPath = c
        }
        else {
            swiftCPath = SwiftCPath
        }
        
        let yaml = llbuildyaml(sources, workdir: workDirectory, name: name, modulename: modulename, linkSDK: sdk, compileOptions: compileOptions, linkOptions: linkOptions, outputType: outputType, linkWithProduct: linkWithProduct, swiftCPath: swiftCPath)
        let _ = try? yaml.writeToFile(llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
    }
}

extension SwiftBuildToolConfig {
    /**
     * Calculates the llbuild.yaml contents for the given configuration options
     *   - parameter sources: A resolved list of swift sources
     *   - parameter workdir: A temporary working directory for `atllbuild` to use
     *   - parameter modulename: The name of the module to be built.
     *   - returns: The string contents for llbuild.yaml suitable for processing by swift-build-tool
     */
    func llbuildyaml(sources: [String], workdir: String, name: String, modulename: String, linkSDK: Bool, compileOptions: [String], linkOptions: [String], outputType: OutputType, linkWithProduct:[String], swiftCPath: String) -> String {
        let productPath = workdir + "products/"
        //this format is largely undocumented, but I reverse-engineered it from SwiftPM.
        var yaml = "client:\n  name: swift-build\n\n"
        
        yaml += "tools: {}\n\n"

        
        yaml += "targets:\n"
        yaml += "  \"\": [<atllbuild>]\n"
        yaml += "  atllbuild: [<atllbuild>]\n"
        
        //this is the "compile" command
        
        yaml += "commands:\n"
        yaml += "  <atllbuild-swiftc>:\n"
        yaml += "     tool: swift-compiler\n"
        yaml += "     executable: \"\(swiftCPath)\"\n"
        yaml += "     inputs: \(sources)\n"
        yaml += "     sources: \(sources)\n"
        
        //swiftPM wants "objects" which is just a list of %.swift.o files.  We have to put them in a temp directory though.
        let objects = sources.map { (source) -> String in
            workdir + "objects/" + source.toNSString.lastPathComponent + ".o"
        }
        yaml += "     objects: \(objects)\n"
        //this crazy syntax is how llbuild specifies outputs
        var llbuild_outputs = ["<atllbuild-swiftc>"]
        llbuild_outputs.appendContentsOf(objects)
        yaml += "     outputs: \(llbuild_outputs)\n"
        
        switch(outputType) {
        case .Executable:
            break
        case .StaticLibrary:
            yaml += "     is-library: true\n" //I have no idea what the effect of this is, but swiftPM does it, so I'm including it.
        }
        
        yaml += "     module-name: \(modulename)\n"
        let swiftModulePath = "\(productPath + modulename).swiftmodule"
        yaml += "     module-output-path: \(swiftModulePath)\n"
        yaml += "     temps-path: \(workdir)/llbuildtmp\n"
        
        var args : [String] = []
        args.appendContentsOf(["-j8", "-D","ATBUILD","-I",workdir+"products/"])
        
        if linkSDK {
            #if os(OSX) //we don't have SDKPath on linux
            args.appendContentsOf(["-sdk", SDKPath])
            #endif
        }
        args.appendContentsOf(compileOptions)
        
        yaml += "     other-args: \(args)\n"
        
        //and this is the "link" command
        yaml += "  <atllbuild>:\n"
        switch(outputType) {
        case .Executable:
            yaml += "    tool: shell\n"
            //this crazy syntax is how sbt declares a dependency
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.appendContentsOf(objects)
            let builtProducts = linkWithProduct.map {workdir+"products/"+$0}
            llbuild_inputs.appendContentsOf(builtProducts)
            let executablePath = productPath+name
            yaml += "    inputs: \(llbuild_inputs)\n"
            yaml += "    outputs: [\"<atllbuild>\", \"\(executablePath)\"]\n"
            //and now we have the crazy 'args'
            args = [swiftCPath, "-o",executablePath]
            args.appendContentsOf(objects)
            args.appendContentsOf(builtProducts)
            args.appendContentsOf(linkOptions)
            yaml += "    args: \(args)\n"
            yaml += "    description: Linking executable \(executablePath)\n"
            return yaml
        
        case .StaticLibrary:
            yaml += "    tool: shell\n"
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.appendContentsOf(objects)
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = productPath + name + ".a"
            yaml += "    outputs: [\"<atllbuild>\", \"\(libPath)\"]\n"
            
            //build the crazy args, mostly consisting of an `ar` shell command
            var shellCmd = "rm -rf \(libPath); ar cr '\(libPath)'"
            for obj in objects {
                shellCmd += " '\(obj)'"
            }
            let args = "[\"/bin/sh\",\"-c\",\(shellCmd)]"
            yaml += "    args: \(args)\n"
            yaml += "    description: \"Linking Library:  \(libPath)\""
            return yaml
        }
     }
}

extension SwiftBuildToolConfig {
    /**
     * We inject this sourcefile in xctestify=true on OSX
     * On Linux, the API requires you to explicitly list tests
     * which is not required on OSX.  Injecting this file into test targets
     * will enforce that API on OSX as well
     */
    private static let xcTestCaseProvider: String = { () -> String in
        var s = ""
        s += "import XCTest\n"
        s += "\n"
        s += "protocol XCTestCaseProvider {\n"
        s += "    var allTests : [(String, () -> Void)] { get }\n"
        s += "}\n"
        s += "\n"
        s += "public func XCTMain(testCases: [XCTestCase]) {\n"
        s += "    fatalError(\"Can't get here.\")\n"
        s += "}\n"
        s += "\n"
        s += "extension XCTestCase {\n"
        s += "    private func implementAllTests() {\n"
        s += "        print(\"Make sure to implement allTests via\")\n"
        s += "        print(\"extension \\(self.dynamicType) : XCTestCaseProvider {\")\n"
        s += "        print(\"    var allTests : [(String, () -> Void)] {\")\n"
        s += "        print(\"        return [\")\n"
        s += "        print(\"        (\\\"testFoo\\\", testFoo)\")\n"
        s += "        print(\"        ]\")\n"
        s += "        print(\"    }\")\n"
        s += "        print(\"}\")\n"
        s += "        print(\"(Or disable xctestStrict.)\")\n"
        s += "        print(\"Cheers! -- Anarchy Tools Team\")\n"
        s += "    }\n"
        s += "    override public func tearDown() {\n"
        s += "        if let provider = self as? XCTestCaseProvider {\n"
        s += "            let contains = provider.allTests.contains({ test in\n"
        s += "                return test.0 == invocation!.selector.description\n"
        s += "            })\n"
        s += "            if !contains {\n"
        s += "               XCTFail(\"Test \\(name) is missing from \\(self.dynamicType)\")\n"
        s += "               implementAllTests()\n"
        s += "            }\n"
        s += "        }\n"
        s += "        else {\n"
        s += "            XCTFail(\"Whoops!  \\(self.dynamicType) doesn't conform to XCTestCaseProvider.\")\n"
        s += "            implementAllTests()\n"
        s += "        }\n"
        s += "        super.tearDown()\n"
        s += "    }\n"
        s += "}\n"
        s += "\n"
        return s
    }()
}

/**
 * This tool handles the production of outputs based on a specified
 * configuration file.
 */
final class SwiftBuildToolBuild: Tool {
    func run(task: Task) {
        let workDirectory = ".atllbuild/"
        let manager = NSFileManager.defaultManager()
        
        //NSFileManager is pretty anal about throwing errors if we try to remove something that doesn't exist, etc.
        //We just want to create a state where .atllbuild/objects and .atllbuild/llbuildtmp and .atllbuild/products exists.
        //and in particular, without erasing the product directory, since that accumulates build products across
        //multiple invocations of atllbuild.
        let _ = try? manager.removeItemAtPath(workDirectory + "/objects")
        let _ = try? manager.removeItemAtPath(workDirectory + "/llbuildtmp")
        let _ = try? manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectoryAtPath(workDirectory + "/products", withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectoryAtPath(workDirectory + "/objects", withIntermediateDirectories: false, attributes: nil)

        let llbuildyamlpath : String
        if let value = task[SwiftBuildToolConfig.Keys.ConfigFile]?.string {
            llbuildyamlpath = value
        }
        else {
            llbuildyamlpath = workDirectory + "llbuild.yaml"
        }
        
        let cmd = "\(SwiftBuildToolpath) -f \(llbuildyamlpath)"
        if system(cmd) != 0 {
            fatalError(cmd)
        }
    }
}

/**
 * This is a friendly front-end wrapper for both the `SwiftBuildToolBuild`
 * and `SwiftBuildToolConfig` tools.
 */
final class SwiftBuildTool: Tool {
    func run(task: Task) {
        SwiftBuildToolConfig().run(task)
        SwiftBuildToolBuild().run(task)
    }
}
