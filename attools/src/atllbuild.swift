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

import atfoundation
import atpkg

 /**Synthesize a module map.
 - parameter name: The name of the module to synthesize
 - parameter umbrellaHeader: A path to the umbrella header.  The path must be relative to the exported module map file.
 - parameter headers: A list of headers to import.  The path must be relative to the exported module map file.
 - returns String contents of the synthesized modulemap
 */
 private func synthesizeModuleMap(name: String, umbrellaHeader: String?, headers: [String], link: [String]) -> String {
     var s = ""
     s += "module \(name) {\n"
     if let u = umbrellaHeader {
         s += "  umbrella header \"\(u)\"\n"
     }
     for header in headers {
        s += "  header \"\(header)\"\n"
     }
     for l in link {
        s += "  link \"\(l)\"\n"
     }
     s += "\n"
     s += "}\n"
     return s
 }

 private struct Atbin {
    let manifest: Package
    let path: Path

    var name: String { return manifest.name }

    init(path: Path) {
        self.path = path
        self.manifest = try! Package(filepath: path.appending("compiled.atpkg"), overlay: [], focusOnTask: nil)
    }

    var linkDirective: String {
        return path.appending(self.manifest.payload!).description
    }

    var moduleName: String {
        let n = self.manifest.payload!
        if n.hasSuffix(".a") {
            return n.subString(toIndex: n.characters.index(n.characters.endIndex, offsetBy: -2))
        }
        if n.hasSuffix(".dylib") {
            return n.subString(toIndex: n.characters.index(n.characters.endIndex, offsetBy: -6))
        }
        if n.hasSuffix(".so") {
            return n.subString(toIndex: n.characters.index(n.characters.endIndex, offsetBy: -3))
        }
        fatalError("Unknown payload \(n)")
    }

    var swiftModule: Path? {
        let modulePath = self.path + (Platform.targetPlatform.description + ".swiftmodule")
        if FS.fileExists(path: modulePath) { return modulePath }
        return nil
    }

    var clangModule: Path? {
        let modulePath = self.path + "module.modulemap"
        if FS.fileExists(path: modulePath) { return modulePath }
        return nil
    }

    var swiftDoc: Path? {
        let docPath = Path(Platform.targetPlatform.description + ".swiftDoc")
        if FS.fileExists(path: docPath) { return docPath }
        return nil
    }
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
        s += "public func testCase<T: XCTestCase>(_ allTests: [(String, (T) -> () throws -> Void)]) -> XCTestCase {\n"
        s += "    fatalError(\"Can't get here.\")\n"
        s += "}\n"
        s += "\n"
        s += "public func XCTMain(_ testCases: [XCTestCase]) {\n"
        s += "    fatalError(\"Can't get here.\")\n"
        s += "}\n"
        s += "\n"
        return s
    }()

    enum OutputType: String {
        case Executable = "executable"
        case StaticLibrary = "static-library"
        case DynamicLibrary = "dynamic-library"
    }

    enum ModuleMapType {
        case None
        case Synthesized
    }

    /**
     * Calculates the llbuild.yaml contents for the given configuration options
     *   - parameter swiftSources: A resolved list of swift sources
     *   - parameter workdir: A temporary working directory for `atllbuild` to use
     *   - parameter modulename: The name of the module to be built.
     *   - parameter executableName: The name of the executable to be built.  Typically the same as the module name.
     *   - parameter enableWMO: Whether to use `enable-whole-module-optimization`, see https://github.com/aciidb0mb3r/swift-llbuild/blob/cfd7aa4e6e14797112922ae12ae7f3af997a41c6/docs/buildsystem.rst
     *   - returns: The string contents for llbuild.yaml suitable for processing by swift-build-tool
     */
    private func llbuildyaml(swiftSources: [Path], cSources: [Path], workdir: Path, modulename: String, linkSDK: Bool, compileOptions: [String], cCompileOptions: [String], linkOptions: [String], outputType: OutputType, linkWithProduct:[String], linkWithAtbin:[Atbin], swiftCPath: Path, executableName: String, enableWMO: Bool) -> String {
        let productPath = workdir.appending("products")
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
        let inputs = String.join(parts: swiftSources.map { path in path.description }, delimiter: "\", \"")
        yaml += "     inputs: [\"\(inputs)\"]\n"
        yaml += "     sources: [\"\(inputs)\"]\n"

        //swiftPM wants "objects" which is just a list of %.swift.o files.  We have to put them in a temp directory though.
        var objects = swiftSources.map { (source) -> String in
            workdir.appending("objects").appending(source.basename() + ".o").description
        }
        yaml += "     objects: \(objects)\n"
        //this crazy syntax is how llbuild specifies outputs
        var llbuild_outputs = ["<atllbuild-swiftc>"]
        llbuild_outputs.append(contentsOf: objects)
        yaml += "     outputs: \(llbuild_outputs)\n"

        yaml += "     enable-whole-module-optimization: \(enableWMO ? "true" : "false")\n"
        yaml += "     num-threads: 8\n"

        switch(outputType) {
        case .Executable:
            break
        case .StaticLibrary, .DynamicLibrary:
            yaml += "     is-library: true\n" //I have no idea what the effect of this is, but swiftPM does it, so I'm including it.
        }

        yaml += "     module-name: \(modulename)\n"
        let swiftModulePath = productPath.appending(modulename + ".swiftmodule")
        yaml += "     module-output-path: \(swiftModulePath)\n"
        yaml += "     temps-path: \(workdir)/llbuildtmp\n"

        var args : [String] = []
        args += ["-j8", "-D", "ATBUILD", "-I", workdir.appending("products").description + "/"]

        if linkSDK {
            if let sdkPath = Platform.targetPlatform.sdkPath {
                if swiftCPath.description.contains(string: "Xcode.app") {
                    //evil evil hack
                    args += ["-sdk","/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"]
                }
                else { args += ["-sdk", sdkPath] }
                
            }
        }
        args += compileOptions

        yaml += "     other-args: \(args)\n"


        var llbuild_inputs = ["<atllbuild-swiftc>"]

        //the "C" commands
        for source in cSources {
            let cmdName = "<atllbuild-\(source.basename().split(character: ".")[0])>"
            yaml += "  \(cmdName):\n"
            yaml += "    tool: shell\n"
            yaml += "    inputs: [\"\(source)\"]\n"
            let c_object = workdir.appending("objects").appending(source.basename() + ".o").description
            yaml += "    outputs: [\"\(c_object)\"]\n"
            var cargs = ["clang","-c",source.description,"-o",c_object]
            cargs += cCompileOptions
            yaml += "    args: \(cargs)\n"

            //add c_objects to our link step
            objects += [c_object]
            llbuild_inputs += [cmdName]
        }

        //and this is the "link" command
        yaml += "  <atllbuild>:\n"
        switch(outputType) {
        case .Executable:
            yaml += "    tool: shell\n"
            //this crazy syntax is how sbt declares a dependency
            llbuild_inputs += objects
            var builtProducts = linkWithProduct.map { (workdir + ("products/"+$0)).description }
            builtProducts += linkWithAtbin.map {$0.linkDirective}
            llbuild_inputs += builtProducts
            let executablePath = productPath.appending(executableName)
            yaml += "    inputs: \(llbuild_inputs)\n"
            yaml += "    outputs: [\"<atllbuild>\", \"\(executablePath)\"]\n"
            //and now we have the crazy 'args'
            args = [swiftCPath.description, "-o", executablePath.description]
            args += objects
            args += builtProducts
            args += linkOptions
            yaml += "    args: \(args)\n"
            yaml += "    description: Linking executable \(executablePath)\n"
            return yaml


        case .StaticLibrary:
            yaml += "    tool: shell\n"
            llbuild_inputs.append(contentsOf: objects)
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = productPath.appending(modulename + ".a")
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
            llbuild_inputs += objects
            var builtProducts = linkWithProduct.map { (workdir + ("products/"+$0)).description }
            builtProducts += linkWithAtbin.map {$0.linkDirective}
            llbuild_inputs += builtProducts
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = productPath.appending(modulename + Platform.targetPlatform.dynamicLibraryExtension)
            yaml += "    outputs: [\"<atllbuild>\", \"\(libPath)\"]\n"
            var args = [swiftCPath.description, "-o", libPath.description, "-emit-library"]
            args += objects
            args += builtProducts
            args += linkOptions
            yaml += "    args: \(args)\n"
            yaml += "    description: \"Linking Library:  \(libPath)\""
            return yaml
        }
     }

    enum Options: String {
        case Tool = "tool"
        case Name = "name"
        case Dependencies = "dependencies"
        case OutputType = "output-type"
        case Source = "sources"
        case BootstrapOnly = "bootstrap-only"
        case llBuildYaml = "llbuildyaml"
        case CompileOptions = "compile-options"
        case CCompileOptions = "c-compile-options"
        case LinkOptions = "link-options"
        case LinkSDK = "link-sdk"
        case LinkWithProduct = "link-with-product"
        case LinkWithAtbin = "link-with-atbin"
        case XCTestify = "xctestify"
        case XCTestStrict = "xctest-strict"
		case IncludeWithUser = "include-with-user"
        case PublishProduct = "publish-product"
        case UmbrellaHeader = "umbrella-header"
        case ModuleMap = "module-map"
        case ModuleMapLink = "module-map-link"
        case WholeModuleOptimization = "whole-module-optimization"
        case Framework = "framework"
        case ExecutableName = "executable-name"
        case Bitcode = "bitcode"
        case Magic = "magic"


        static var allOptions : [Options] {
            return [
                Name,
                Dependencies,
                OutputType,
                Source,
                BootstrapOnly,
                llBuildYaml,
                CompileOptions,
                CCompileOptions,
                LinkOptions,
                LinkSDK,
                LinkWithProduct,
				LinkWithAtbin,
                XCTestify,
                XCTestStrict,
				IncludeWithUser,
                PublishProduct,
				UmbrellaHeader,
                ModuleMap,
                ModuleMapLink,
                WholeModuleOptimization,
                Framework,
                ExecutableName,
                Bitcode,
                Magic
            ]
        }
    }

    func run(task: Task) {

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
        let workDirectory = Path(".atllbuild")

        //NSFileManager is pretty anal about throwing errors if we try to remove something that doesn't exist, etc.
        //We just want to create a state where .atllbuild/objects and .atllbuild/llbuildtmp and .atllbuild/products exists.
        //and in particular, without erasing the product directory, since that accumulates build products across
        //multiple invocations of atllbuild.
        if CommandLine.arguments.contains("--clean") {
            let _ = try? FS.removeItem(path: workDirectory.appending("objects"), recursive: true)
            let _ = try? FS.removeItem(path: workDirectory.appending("llbuildtmp"), recursive: true)
        }
        let _ = try? FS.removeItem(path: workDirectory.appending("include"), recursive: true)



        let _ = try? FS.createDirectory(path: workDirectory)
        let _ = try? FS.createDirectory(path: workDirectory.appending("products"))
        let _ = try? FS.createDirectory(path: workDirectory.appending("objects"))
        let _ = try? FS.createDirectory(path: workDirectory.appending("include"))

        ///MARK: parse arguments
        var linkWithProduct: [String] = []
        if let arr_ = task[Options.LinkWithProduct.rawValue] {
            guard let arr = arr_.vector else {
                fatalError("Non-vector link directive \(arr_)")
            }
            for product in arr {
                guard var p = product.string else { fatalError("non-string product \(product)") }
                if p.hasSuffix(".dynamic") {
                    p.replace(searchTerm: ".dynamic", replacement: Platform.targetPlatform.dynamicLibraryExtension)
                }
                linkWithProduct.append(p)
            }
        }

        ///DEPRECATED PRODUCT CHECK
        if let arr_ = task["link-with"] {
            print("Warning: link-with is deprecated; please use link-with-product or link-with-atbin")
            sleep(5)
            guard let arr = arr_.vector else {
                fatalError("Non-vector link directive \(arr_)")
            }
            for product in arr {
                guard var p = product.string else { fatalError("non-string product \(product)") }
                if p.hasSuffix(".dynamic") {
                    p.replace(searchTerm: ".dynamic", replacement: Platform.targetPlatform.dynamicLibraryExtension)
                }
                linkWithProduct.append(p)
            }
        }

        var linkWithAtbin: [Atbin] = []
        if let arr_ = task[Options.LinkWithAtbin.rawValue] {
            guard let arr = arr_.vector else {
                fatalError("Non-vector link directive \(arr_)")
            }
            for product in arr {
                guard var p = product.string else { fatalError("non-string product \(product)") }
                linkWithAtbin.append(Atbin(path: task.importedPath.appending(p)))
            }
        }

        guard case .some(.StringLiteral(let outputTypeString)) = task[Options.OutputType.rawValue] else {
            fatalError("No \(Options.OutputType.rawValue) for task \(task)")
        }
        guard let outputType = OutputType(rawValue: outputTypeString) else {
            fatalError("Unknown \(Options.OutputType.rawValue) \(outputTypeString)")
        }

        var compileOptions: [String] = []
        if let opts = task[Options.CompileOptions.rawValue]?.vector {
            for o in opts {
                guard let os = o.string else { fatalError("Compile option \(o) is not a string") }
                compileOptions.append(os)
            }
        }

        var cCompileOptions: [String] = []
        if let opts = task[Options.CCompileOptions.rawValue]?.vector {
            for o in opts {
                guard let os = o.string else { fatalError("C compile option \(o) is not a string")}
                cCompileOptions.append(os)
            }
        }

        //copy the atbin module / swiftdoc into our include directory
        let includeAtbinPath = workDirectory + "include/atbin"
        let _ = try? FS.createDirectory(path: includeAtbinPath, intermediate: true)
        for atbin in linkWithAtbin {
            if let path = atbin.swiftModule {
                try! FS.copyItem(from: path, to: Path("\(includeAtbinPath)/\(atbin.moduleName).swiftmodule"))
            }
        }
        if linkWithAtbin.count > 0 { compileOptions.append(contentsOf: ["-I",includeAtbinPath.description])}

        if let includePaths = task[Options.IncludeWithUser.rawValue]?.vector {
            for path_s in includePaths {
                guard let path = path_s.string else { fatalError("Non-string path \(path_s)") }
                compileOptions.append("-I")
                compileOptions.append((userPath() + path).description)
            }
        }
        var linkOptions: [String] = []
        if let opts = task[Options.LinkOptions.rawValue]?.vector {
            for o in opts {
                guard let os = o.string else { fatalError("Link option \(o) is not a string") }
                linkOptions.append(os)
            }
        }

        let bitcode: Bool
        //do we have an explicit bitcode setting?
        if let b = task[Options.Bitcode.rawValue] {
            bitcode = b.bool!
        }
        else {
            bitcode = false
        }

        //separate sources
        guard let sourceDescriptions = task[Options.Source.rawValue]?.vector?.flatMap({$0.string}) else { fatalError("Can't find sources for atllbuild.") }

        var sources = collectSources(sourceDescriptions: sourceDescriptions, taskForCalculatingPath: task)

        let cSources = sources.filter({$0.description.hasSuffix(".c")})
        
        //todo: enable by default for iOS, but we can't due to SR-1493
        if bitcode {
            compileOptions.append("-embed-bitcode")
            linkOptions.append(contentsOf: ["-embed-bitcode"])
            if cSources.count > 0 {
                print("Warning: bitcode is not supported for C sources")
            }
        }



        //check for modulemaps
        /*per http://clang.llvm.org/docs/Modules.html#command-line-parameters, pretty much
        the only way to do this is to create a file called `module.modulemap`.  That
        potentially conflicts with other modulemaps, so we give it its own directory, namespaced
        by the product name. */
        func installModuleMap(moduleMapPath: Path, productName: String) {
           let includePathName = workDirectory + "include/\(productName)"
            let _ = try? FS.createDirectory(path: includePathName, intermediate: true)
            do {
                try FS.copyItem(from: moduleMapPath, to: includePathName.appending("module.modulemap"))
            } catch {
                fatalError("Could not copy modulemap to \(includePathName): \(error)")
            }
            compileOptions.append(contentsOf: ["-I", includePathName.description])
        }
        for product in linkWithProduct {
            let productName = product.split(character: ".")[0]
            let moduleMapPath = workDirectory + "products/\(productName).modulemap"
            if FS.fileExists(path: moduleMapPath) {
                installModuleMap(moduleMapPath: moduleMapPath, productName: productName)
            }
        }

        for product in linkWithAtbin {
            if let moduleMapPath = product.clangModule {
                installModuleMap(moduleMapPath: moduleMapPath, productName: product.name)
            }
        }


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

                case .iOS, .iOSGeneric:
                fatalError("\(Options.XCTestify.rawValue) is not supported for iOS")
            }
        }
        if task[Options.XCTestStrict.rawValue]?.bool == true {
            switch Platform.targetPlatform {
            case .OSX:
                //inject XCTestCaseProvider.swift
                do {
                    let xcTestCaseProviderPath = try FS.temporaryDirectory(prefix: "XCTestCase")
                    do {
                        try ATllbuild.xcTestCaseProvider.write(to: xcTestCaseProviderPath.appending("XCTestCaseProvider.swift"))
                        sources.append(xcTestCaseProviderPath.appending("XCTestCaseProvider.swift"))
                    } catch {
                        print(xcTestCaseProviderPath)
                        fatalError("Could not inject XCTestCaseProvider: \(error)")
                    }
                } catch {
                    fatalError("Could not create temp dir for XCTestCaseProvider: \(error)")
                }
                

            case .Linux:
                break

                case .iOS, .iOSGeneric:
                fatalError("\(Options.XCTestStrict.rawValue) is not supported for iOS")
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

        let executableName: String
        if let e = task[Options.ExecutableName.rawValue]?.string { 
            precondition(outputType == .Executable, "Must use \(Options.OutputType.rawValue) 'executable' when using \(Options.ExecutableName.rawValue)")
            executableName = e 
        }
        else { executableName = name }

        if task[Options.Framework.rawValue]?.bool == true {
            #if !os(OSX)
            fatalError("\(Options.Framework.rawValue) is not supported on this host.")
            #endif
            linkOptions.append("-Xlinker")
            linkOptions.append("-install_name")
            linkOptions.append("-Xlinker")
            switch(Platform.targetPlatform) {
                case .OSX:
                linkOptions.append("@rpath/\(name).framework/Versions/A/\(name)")
                case .iOS(let arch):
                linkOptions.append("@rpath/\(name).framework/\(name)")
                default:
                fatalError("\(Options.Framework.rawValue) not supported when targeting \(Platform.targetPlatform)")
            }
            
        }

        let hSources = sources.filter({$0.description.hasSuffix(".h")}).map({$0.description})
        let umbrellaHeader = task[Options.UmbrellaHeader.rawValue]?.string

        var moduleMapLinks: [String] = []
        if let links = task[Options.ModuleMapLink.rawValue]?.vector {
            precondition(moduleMap == .Synthesized, ":\(Options.ModuleMap.rawValue) \"synthesized\" must be used with the \(Options.ModuleMapLink.rawValue) option")
            for link in links {
                guard case .StringLiteral(let l) = link else {
                    fatalError("Non-string \(Options.ModuleMapLink.rawValue) \(link)")
                }
                moduleMapLinks.append(l)
            }
        }

        if hSources.count > 0 || umbrellaHeader != nil { //we need to import the underlying module
            precondition(moduleMap == .Synthesized, ":\(Options.ModuleMap.rawValue) \"synthesized\" must be used with the \(Options.UmbrellaHeader.rawValue) option or when compiling C headers")
            let umbrellaHeaderArg: String?
            if umbrellaHeader != nil { umbrellaHeaderArg = "Umbrella.h" } else {umbrellaHeaderArg = nil}
            //add ../../ to hsources to get out from inside workDirectory/include
            let relativeHSources = hSources.map({"../../" + $0})
            let s = synthesizeModuleMap(name: name, umbrellaHeader: umbrellaHeaderArg, headers: relativeHSources, link: moduleMapLinks)
            do {
                try s.write(to: workDirectory + "include/module.modulemap")
                if let u = umbrellaHeader {
                    try FS.copyItem(from: task.importedPath + u, to: workDirectory + "include/Umbrella.h")
                }
                
            } catch {
                fatalError("Could not synthesize module map during build: \(error)")
            }
            compileOptions.append("-I")
            compileOptions.append(workDirectory.appending("include").description + "/")
            compileOptions.append("-import-underlying-module")
        }

        //inject target

        switch(Platform.targetPlatform) {
            case .iOS(let arch):
            let targetTuple = ["-target",Platform.targetPlatform.targetTriple]
            compileOptions.append(contentsOf: targetTuple)
            linkOptions.append(contentsOf: targetTuple)
            cCompileOptions.append(contentsOf: targetTuple)
            cCompileOptions.append(contentsOf: ["-isysroot",Platform.targetPlatform.sdkPath!])
            linkOptions.append(contentsOf: ["-Xlinker", "-syslibroot","-Xlinker",Platform.targetPlatform.sdkPath!])
            case .OSX, .Linux:
                break //not required
            case .iOSGeneric:
                fatalError("Generic platform iOS cannot be used with atllbuild; choose a specific platform or use atbin")
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

        let llbuildyamlpath : Path

        if let value = task[Options.llBuildYaml.rawValue]?.string {
            llbuildyamlpath = Path(value)
        }
        else {
            llbuildyamlpath = workDirectory.appending("llbuild.yaml")
        }
        let swiftCPath = findToolPath(toolName: "swiftc")

        var enableWMO: Bool
        if let wmo = task[Options.WholeModuleOptimization.rawValue]?.bool {
            enableWMO = wmo
            //we can't deprecate WMO due to a bug in swift-preview-1 that prevents it from being useable in some cases on Linux
        }
        else { enableWMO = false }

        // MARK: Configurations

        if currentConfiguration.testingEnabled == true {
            compileOptions.append("-enable-testing")
        }

        //"stripped" is implemented as "included" here, that is a bug
        //see https://github.com/AnarchyTools/atbuild/issues/73
        if currentConfiguration.debugInstrumentation == .Included || currentConfiguration.debugInstrumentation == .Stripped {
            compileOptions.append("-g")
            cCompileOptions.append("-g")
        }

        if currentConfiguration.optimize == true {
            compileOptions.append("-O")
            cCompileOptions.append("-Os")
            switch(Platform.buildPlatform) {
                case .Linux:
                //don't enable WMO on Linux
                //due to bug in swift-preview-1
                break
                default:
                enableWMO = true
            }
        }
        if task[Options.Magic.rawValue] != nil {
            print("Warning: Magic is deprecated.  Please migrate to --configuration none.  If --configuration none won't work for your usecase, file a bug at https://github.com/AnarchyTools/atbuild/issues")
            sleep(5)
        }

        if currentConfiguration.fastCompile==false  && task[Options.Magic.rawValue]?.bool != false {
            switch(Platform.buildPlatform) {
                case .OSX:
                linkOptions.append(contentsOf: ["-Xlinker","-dead_strip"])
                default:
                break
            }
        }

        switch(currentConfiguration) {
            case .Debug:
            compileOptions.append("-DATBUILD_DEBUG")
            cCompileOptions.append("-DATBUILD_DEBUG")
            case .Release:
            compileOptions.append("-DATBUILD_RELEASE")
            cCompileOptions.append("-DATBUILD_RELEASE")
            case .Benchmark:
            compileOptions.append("-DATBUILD_BENCH")
            cCompileOptions.append("-DATBUILD_BENCH")

            case .Test:
            compileOptions.append("-DATBUILD_TEST")
            cCompileOptions.append("-DATBUILD_TEST")
            case .None:
            break //too much magic to insert an arg in this case
            case .User(let str):
            compileOptions.append("-DATBUILD_\(str)")
            cCompileOptions.append("-DATBUILD_\(str)")
        }

        // MARK: emit llbuildyaml 

        //separate sources
        let swiftSources = sources.filter({$0.description.hasSuffix(".swift")})

        if hSources.count > 0 {
            precondition(moduleMap == .Synthesized,"Use :\(Options.ModuleMap.rawValue) \"synthesized\" when compiling C headers")
        }


        let yaml = llbuildyaml(swiftSources: swiftSources,cSources: cSources, workdir: workDirectory, modulename: name, linkSDK: sdk, compileOptions: compileOptions, cCompileOptions: cCompileOptions, linkOptions: linkOptions, outputType: outputType, linkWithProduct: linkWithProduct, linkWithAtbin: linkWithAtbin, swiftCPath: swiftCPath, executableName: executableName, enableWMO: enableWMO)
        let _ = try? yaml.write(to: llbuildyamlpath)
        if bootstrapOnly { return }

        //MARK: execute build

        switch moduleMap {
        case .None:
            break
        case .Synthesized:
            // "public" modulemap
            let s = synthesizeModuleMap(name: name, umbrellaHeader: nil, headers: [], link: moduleMapLinks)
            do {
                try s.write(to: workDirectory + "products/\(name).modulemap")
            } catch {
                fatalError("Could not write synthesized module map: \(error)")
            }
        }

        let cmd = "\(findToolPath(toolName: "swift-build-tool")) -f \(llbuildyamlpath)"
        anarchySystem(cmd, environment: [:])
        if task[Options.PublishProduct.rawValue]?.bool == true {
            do {
                if !FS.isDirectory(path: Path("bin")) {
                    try FS.createDirectory(path: Path("bin"))
                }
                try FS.copyItem(from: workDirectory + "products/\(name).swiftmodule", to: Path("bin/\(name).swiftmodule"))
                try FS.copyItem(from: workDirectory + "products/\(name).swiftdoc", to: Path("bin/\(name).swiftdoc"))
                switch outputType {
                case .Executable:
                    try FS.copyItem(from: workDirectory + "products/\(executableName)", to: Path("bin/\(executableName)"))
                case .StaticLibrary:
                    try FS.copyItem(from: workDirectory + "products/\(name).a", to: Path("bin/\(name).a"))
                case .DynamicLibrary:
                    try FS.copyItem(from: workDirectory + ("products/\(name)" + Platform.targetPlatform.dynamicLibraryExtension) , to: Path("bin/\(name)" + Platform.targetPlatform.dynamicLibraryExtension))
                }
                switch moduleMap {
                case .None:
                    break
                case .Synthesized:
                    try FS.copyItem(from: workDirectory + "products/\(name).modulemap", to: Path("bin/\(name).modulemap"))
                }
            } catch {
                print("Could not publish product: \(error)")
            }
        }

    }
}
