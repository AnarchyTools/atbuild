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

 /**Synthesize a module map.
 - parameter name: The name of the module to synthesize
 - parameter umbrellaHeader: A path to the umbrella header.  The path must be relative to the exported module map file.
 - returns String contents of the synthesized modulemap
 */
 private func synthesizeModuleMap(name: String, umbrellaHeader: String?) -> String {
     var s = ""
     s += "module \(name) {\n"
     if let u = umbrellaHeader {
         s += "  umbrella header \"\(u)\"\n"
     }
     s += "\n"
     s += "}\n"
     return s
 }


/**The ATllbuild tool builds a swift module via llbuild.
For more information on this tool, see `docs/attllbuild.md` */
final class ATllbuild : Tool {

    /**We inject this sourcefile in xctestify=true on OSX
    On Linux, the API requires you to explicitly list tests
    which is not required on OSX.  Injecting this file into test targets
    will enforce that API on OSX as well */
    private static let xcTestCaseProvider: String = { () -> String in
        var s = ""
        s += "import XCTest\n"
        s += "public func testCase<T: XCTestCase>(_ allTests: [(String, T -> () throws -> Void)]) -> XCTestCase {\n"
        s += "    fatalError(\"Can't get here.\")\n"
        s += "}\n"
        s += "\n"
        s += "public func XCTMain(_ testCases: [XCTestCase]) {\n"
        s += "    fatalError(\"Can't get here.\")\n"
        s += "}\n"
        s += "\n"
        return s
    }()

    enum OutputType {
        case Executable
        case StaticLibrary
        case DynamicLibrary
    }

    enum ModuleMapType {
        case None
        case Synthesized
    }

    /**
     * Calculates the llbuild.yaml contents for the given configuration options
     *   - parameter sources: A resolved list of swift sources
     *   - parameter workdir: A temporary working directory for `atllbuild` to use
     *   - parameter modulename: The name of the module to be built.
     *   - returns: The string contents for llbuild.yaml suitable for processing by swift-build-tool
     */
    func llbuildyaml(sources: [String], workdir: String, modulename: String, linkSDK: Bool, compileOptions: [String], linkOptions: [String], outputType: OutputType, linkWithProduct:[String], swiftCPath: String) -> String {
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
        llbuild_outputs.append(contentsOf: objects)
        yaml += "     outputs: \(llbuild_outputs)\n"

        switch(outputType) {
        case .Executable:
            break
        case .StaticLibrary, .DynamicLibrary:
            yaml += "     is-library: true\n" //I have no idea what the effect of this is, but swiftPM does it, so I'm including it.
        }

        yaml += "     module-name: \(modulename)\n"
        let swiftModulePath = "\(productPath + modulename).swiftmodule"
        yaml += "     module-output-path: \(swiftModulePath)\n"
        yaml += "     temps-path: \(workdir)/llbuildtmp\n"

        var args : [String] = []
        args.append(contentsOf: ["-j8", "-D","ATBUILD","-I",workdir+"products/"])

        if linkSDK {
            if let sdkPath = Platform.targetPlatform.sdkPath {
                args.append(contentsOf: ["-sdk",sdkPath])
            }
        }
        args.append(contentsOf: compileOptions)

        yaml += "     other-args: \(args)\n"

        //and this is the "link" command
        yaml += "  <atllbuild>:\n"
        switch(outputType) {
        case .Executable:
            yaml += "    tool: shell\n"
            //this crazy syntax is how sbt declares a dependency
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.append(contentsOf: objects)
            let builtProducts = linkWithProduct.map {workdir+"products/"+$0}
            llbuild_inputs.append(contentsOf: builtProducts)
            let executablePath = productPath+modulename
            yaml += "    inputs: \(llbuild_inputs)\n"
            yaml += "    outputs: [\"<atllbuild>\", \"\(executablePath)\"]\n"
            //and now we have the crazy 'args'
            args = [swiftCPath, "-o",executablePath]
            args.append(contentsOf: objects)
            args.append(contentsOf: builtProducts)
            args.append(contentsOf: linkOptions)
            yaml += "    args: \(args)\n"
            yaml += "    description: Linking executable \(executablePath)\n"
            return yaml


        case .StaticLibrary:
            yaml += "    tool: shell\n"
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.append(contentsOf: objects)
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = productPath + modulename + ".a"
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

        case .DynamicLibrary:
            yaml += "    tool: shell\n"
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.append(contentsOf: objects)
            let builtProducts = linkWithProduct.map {workdir+"products/"+$0}
            llbuild_inputs.append(contentsOf: builtProducts)
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = productPath + modulename + Platform.targetPlatform.dynamicLibraryExtension
            yaml += "    outputs: [\"<atllbuild>\", \"\(libPath)\"]\n"
            var args = [swiftCPath, "-o", libPath, "-emit-library"]
            args.append(contentsOf: objects)
            args.append(contentsOf: builtProducts)
            args.append(contentsOf: linkOptions)
            yaml += "    args: \(args)\n"
            yaml += "    description: \"Linking Library:  \(libPath)\""
            return yaml
        }
     }

    private enum Options: String {
        case Tool = "tool"
        case Name = "name"
        case Dependencies = "dependencies"
        case OutputType = "output-type"
        case Source = "sources"
        case BootstrapOnly = "bootstrap-only"
        case llBuildYaml = "llbuildyaml"
        case CompileOptions = "compile-options"
        case LinkOptions = "link-options"
        case LinkSDK = "link-sdk"
        case LinkWithProduct = "link-with"
        case SwiftCPath = "swiftc-path"
        case XCTestify = "xctestify"
        case XCTestStrict = "xctest-strict"
		case IncludeWithUser = "include-with-user"
        case PublishProduct = "publish-product"
        case UmbrellaHeader = "umbrella-header"
        case ModuleMap = "module-map"
        case WholeModuleOptimization = "whole-module-optimization"
        case Framework = "framework"


        static var allOptions : [Options] {
            return [
                Name,
                Dependencies,
                OutputType,
                Source,
                BootstrapOnly,
                llBuildYaml,
                CompileOptions,
                LinkOptions,
                LinkSDK,
                LinkWithProduct,
                SwiftCPath,
                XCTestify,
                XCTestStrict,
				IncludeWithUser,
                PublishProduct,
				UmbrellaHeader,
                WholeModuleOptimization,
                Framework
            ]
        }
    }

    func run(task: Task, toolchain: String) {
        run(task: task, toolchain: toolchain, wmoHack: false)
    }

    func run(task: Task, toolchain: String, wmoHack : Bool = false) {

        //warn if we don't understand an option
        var knownOptions = Options.allOptions.map({$0.rawValue})
        for option in Task.Option.allOptions.map({$0.rawValue}) {
            knownOptions.append(option)
        }
        for key in task.allKeys {
            if !knownOptions.contains(key) {
                print("Warning: unknown option \(key) for task \(task.qualifiedName)")
            }
        }

        //create the working directory
        let workDirectory = ".atllbuild/"
        let manager = NSFileManager.defaultManager()

        //NSFileManager is pretty anal about throwing errors if we try to remove something that doesn't exist, etc.
        //We just want to create a state where .atllbuild/objects and .atllbuild/llbuildtmp and .atllbuild/products exists.
        //and in particular, without erasing the product directory, since that accumulates build products across
        //multiple invocations of atllbuild.
        if Process.arguments.contains("--clean") {
            let _ = try? manager.removeItem(atPath: workDirectory + "/objects")
            let _ = try? manager.removeItem(atPath: workDirectory + "/llbuildtmp")
        }
        let _ = try? manager.removeItem(atPath: workDirectory + "/include")



        let _ = try? manager.createDirectory(atPath: workDirectory, withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectory(atPath: workDirectory + "/products", withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectory(atPath: workDirectory + "/objects", withIntermediateDirectories: false, attributes: nil)
        let _ = try? manager.createDirectory(atPath: workDirectory + "/include", withIntermediateDirectories: false, attributes: nil)

        //parse arguments
        var linkWithProduct: [String] = []
        if let arr_ = task[Options.LinkWithProduct.rawValue] {
            guard let arr = arr_.vector else {
                fatalError("Non-vector link directive \(arr_)")
            }
            for product in arr {
                guard var p = product.string else { fatalError("non-string product \(product)") }
                if p.hasSuffix(".dynamic") {
                    p = p.replacingOccurrences(of: ".dynamic", with: Platform.targetPlatform.dynamicLibraryExtension)
                }
                linkWithProduct.append(p)
            }
        }

        let outputType: OutputType
        if task[Options.OutputType.rawValue]?.string == "static-library" {
            outputType = .StaticLibrary
        }
        else if task[Options.OutputType.rawValue]?.string == "executable" {
            outputType = .Executable
        }
        else if task[Options.OutputType.rawValue]?.string == "dynamic-library" {
            outputType = .DynamicLibrary
        }
        else {
            fatalError("Unknown \(Options.OutputType.rawValue) \(task["outputType"])")
        }

        var compileOptions: [String] = []
        if let opts = task[Options.CompileOptions.rawValue]?.vector {
            for o in opts {
                guard let os = o.string else { fatalError("Compile option \(o) is not a string") }
                compileOptions.append(os)
            }
        }

        if wmoHack {
            compileOptions.append("-whole-module-optimization")
        }

        if let includePaths = task[Options.IncludeWithUser.rawValue]?.vector {
            for path_s in includePaths {
                guard let path = path_s.string else { fatalError("Non-string path \(path_s)") }
                compileOptions.append("-I")
                compileOptions.append(userPath() + "/" + path)
            }
        }
        var linkOptions: [String] = []
        if let opts = task[Options.LinkOptions.rawValue]?.vector {
            for o in opts {
                guard let os = o.string else { fatalError("Link option \(o) is not a string") }
                linkOptions.append(os)
            }
        }

        //check for modulemaps
        for product in linkWithProduct {
            let productName = product.componentsSeparated(by: ".")[0]
            let moduleMapPath = workDirectory + "/products/\(productName).modulemap"
            if manager.fileExists(atPath: moduleMapPath) {
                /*per http://clang.llvm.org/docs/Modules.html#command-line-parameters, pretty much
                the only way to do this is to create a file called `module.modulemap`.  That
                potentially conflicts with other modulemaps, so we give it its own directory, namespaced
                by the product name. */
                let pathName = workDirectory + "/include/\(productName)"
                try! manager.createDirectory(atPath: pathName, withIntermediateDirectories:false, attributes: nil)
                try! manager.copyItemAtPath_SWIFTBUG(srcPath: moduleMapPath, toPath: pathName + "/module.modulemap")
                compileOptions.append(contentsOf: ["-I",pathName])
            }
        }

        guard let sourceDescriptions = task[Options.Source.rawValue]?.vector?.flatMap({$0.string}) else { fatalError("Can't find sources for atllbuild.") }
        var sources = collectSources(sourceDescriptions: sourceDescriptions, taskForCalculatingPath: task)

        //xctestify
        if task[Options.XCTestify.rawValue]?.bool == true {
            precondition(outputType == .Executable, "You must use :\(Options.OutputType.rawValue) executable with xctestify.")
            //inject platform-specific flags
            switch(Platform.targetPlatform) {
                case .OSX:
                compileOptions.append(contentsOf: ["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/"])
                linkOptions.append(contentsOf: ["-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-target", "x86_64-apple-macosx10.11", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/", "-Xlinker", "-bundle"])
                
                case .Linux:
                break
            }
        }
        if task[Options.XCTestStrict.rawValue]?.bool == true {
            switch Platform.targetPlatform {
                case .OSX:
                //inject XCTestCaseProvider.swift
                var xcTestCaseProviderPath = "/tmp/XXXXXXX"
                var template = xcTestCaseProviderPath.cString(using: NSUTF8StringEncoding)!
                xcTestCaseProviderPath = String(cString: mkdtemp(&template), encoding: NSUTF8StringEncoding)!

                xcTestCaseProviderPath += "/XCTestCaseProvider.swift"

                try! ATllbuild.xcTestCaseProvider.write(toFile: xcTestCaseProviderPath, atomically: false, encoding: NSUTF8StringEncoding)
                sources.append(xcTestCaseProviderPath)
                
                case .Linux:
                break
            }
        }
        let moduleMap: ModuleMapType
        if task[Options.ModuleMap.rawValue]?.string == "synthesized" {
            moduleMap = .Synthesized
        }
        else {
            moduleMap = .None
        }

        guard let name = task[Options.Name.rawValue]?.string else { fatalError("No name for atllbuild task") }

        if task[Options.Framework.rawValue]?.bool == true {
            #if !os(OSX)
            fatalError("\(Options.Framework.rawValue) is not supported on this platform.")
            #endif
            linkOptions.append("-Xlinker")
            linkOptions.append("-install_name")
            linkOptions.append("-Xlinker")
            linkOptions.append("@rpath/\(name).framework/Versions/A/\(name)")
        }

        if let umbrellaHeader = task[Options.UmbrellaHeader.rawValue]?.string {
            precondition(moduleMap == .Synthesized, ":\(Options.UmbrellaHeader.rawValue) \"synthesized\" must be used with the \(Options.UmbrellaHeader.rawValue) option")
            let s = synthesizeModuleMap(name: name, umbrellaHeader: "Umbrella.h")
            try! s.write(toFile: workDirectory+"/include/module.modulemap", atomically: false, encoding: NSUTF8StringEncoding)
            try! manager.copyItemAtPath_SWIFTBUG(srcPath: task.importedPath + umbrellaHeader, toPath: workDirectory + "/include/Umbrella.h")
            compileOptions.append("-I")
            compileOptions.append(workDirectory + "/include/")
            compileOptions.append("-import-underlying-module")
        }

        let bootstrapOnly: Bool

        if task[Options.BootstrapOnly.rawValue]?.bool == true {
            bootstrapOnly = true
            //update the build platform to be the one passed on the CLI
            Platform.buildPlatform = Platform.targetPlatform
        }
        else {
            bootstrapOnly = false
        }

        ///The next task will not be bootstrapped.
        defer { Platform.buildPlatform = Platform.hostPlatform }
        
        let sdk: Bool
        if task[Options.LinkSDK.rawValue]?.bool == false {
            sdk = false
        }
        else { sdk = true }

        let llbuildyamlpath : String

        if let value = task[Options.llBuildYaml.rawValue]?.string {
            llbuildyamlpath = value
        }
        else {
            llbuildyamlpath = workDirectory + "llbuild.yaml"
        }
        let swiftCPath: String
        if let c = task[Options.SwiftCPath.rawValue]?.string {
            print("Warning: \(Options.SwiftCPath.rawValue) is deprecated and will be removed in a future release of atbuild.  Use --toolchain to specify a different toolchain, or --platform when bootstrapping to a different platform.")
            swiftCPath = c
        }
        else {
            swiftCPath = findToolPath(toolName: "swiftc",toolchain: toolchain)
        }

        let yaml = llbuildyaml(sources: sources, workdir: workDirectory, modulename: name, linkSDK: sdk, compileOptions: compileOptions, linkOptions: linkOptions, outputType: outputType, linkWithProduct: linkWithProduct, swiftCPath: swiftCPath)
        let _ = try? yaml.write(toFile: llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
        if bootstrapOnly { return }

        switch moduleMap {
                case .None:
                break
                case .Synthesized:
                let s = synthesizeModuleMap(name: name, umbrellaHeader: nil)
                try! s.write(toFile: workDirectory + "/products/\(name).modulemap", atomically: false, encoding: NSUTF8StringEncoding)
        }

        //SR-566
        let cmd = "\(findToolPath(toolName: "swift-build-tool",toolchain: toolchain)) -f \(llbuildyamlpath)"
        anarchySystem(cmd)
        if task[Options.PublishProduct.rawValue]?.bool == true {
            if !manager.fileExists(atPath: "bin") {
                try! manager.createDirectory(atPath: "bin", withIntermediateDirectories: false, attributes: nil)
            }
            try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name).swiftmodule", toPath: "bin/\(name).swiftmodule")
            try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name).swiftdoc", toPath: "bin/\(name).swiftdoc")
            switch outputType {
            case .Executable:
                try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name)", toPath: "bin/\(name)")
            case .StaticLibrary:
                try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name).a", toPath: "bin/\(name).a")
            case .DynamicLibrary:
                try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name)\(Platform.targetPlatform.dynamicLibraryExtension)", toPath: "bin/\(name)\(Platform.targetPlatform.dynamicLibraryExtension)")
            }
            switch moduleMap {
                case .None:
                break
                case .Synthesized:
                try! copyByOverwriting(fromPath: "\(workDirectory)/products/\(name).modulemap", toPath: "bin/\(name).modulemap")
            }
        }

        if task[Options.WholeModuleOptimization.rawValue]?.bool == true && !wmoHack {
            print("Work around SR-881")
            run(task: task, toolchain: toolchain, wmoHack: true)
        }

    }
}

private func copyByOverwriting(fromPath: String, toPath: String) throws {
    let manager = NSFileManager.defaultManager()
    if manager.fileExists(atPath: toPath) {
        try manager.removeItem(atPath: toPath)
    }
    try! manager.copyItemAtPath_SWIFTBUG(srcPath: fromPath, toPath: toPath)
}