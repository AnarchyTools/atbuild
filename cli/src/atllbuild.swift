//  atllbuild.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

/**The ATllbuild tool builds a swift module via llbuild.
For more information on this tool, see `docs/attllbuild.md` */
final class ATllbuild : Tool {
    
    enum OutputType {
        case Executable
        case StaticLibrary
    }
    
    /**This function resolves wildcards in source descriptions to complete values
- parameter sourceDescriptions: a descriptions of sources such as ["src/**.swift"] */
- returns: A list of resolved sources such as ["src/a.swift", "src/b.swift"]
*/
    func collectSources(sourceDescriptions: [String]) -> [String] {
        var sources : [String] = []
        for description in sourceDescriptions {
            if description.hasSuffix("**.swift") {
                let basepath = String(Array(description.characters)[0..<description.characters.count - 9])
                let manager = NSFileManager.defaultManager()
                let enumerator = manager.enumeratorAtPath(basepath)!
                while let source = enumerator.nextObject() as? String {
                    if source.hasSuffix("swift") {
                        sources.append(basepath + "/" + source)
                    }
                }
            }
            else {
                sources.append(description)
            }
        }
        return sources
    }
    
    /**Calculates the llbuild.yaml contents for the given configuration options
- parameter sources: A resolved list of swift sources
- parameter workdir: A temporary working directory for `atllbuild` to use
- parameter modulename: The name of the module to be built.
- returns: The string contents for llbuild.yaml suitable for processing by swift-build-tool */
    func llbuildyaml(sources: [String], workdir: String, modulename: String, linkSDK: Bool, compileOptions: [String], outputType: OutputType) -> String {
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
        yaml += "     executable: \"\(SwiftCPath)\"\n"
        yaml += "     inputs: \(sources)\n"
        yaml += "     sources: \(sources)\n"
        
        //swiftPM wants "objects" which is just a list of %.swift.o files.  We have to put them in a temp directory though.
        let objects = sources.map { (source) -> String in
            workdir + (source as NSString).lastPathComponent + ".o"
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
        yaml += "     module-output-path: \(workdir + modulename).swiftmodule\n"
        yaml += "     temps-path: \(workdir)/llbuildtmp\n"
        
        var args : [String] = []
        args.appendContentsOf(["-j8"])
        
        if linkSDK {
            args.appendContentsOf(["-sdk", SDKPath])
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
            yaml += "    inputs: \(llbuild_inputs)\n"
            yaml += "    outputs: [\"<atllbuild>\", \"\(workdir + modulename)\"]\n"
            //and now we have the crazy 'args'
            args = [SwiftCPath, "-o",workdir + modulename]
            args.appendContentsOf(objects)
            yaml += "    args: \(args)\n"
            
            yaml += "    description: Linking executable \(modulename)\n"
        
        case .StaticLibrary:
            yaml += "    tool: shell\n"
            var llbuild_inputs = ["<atllbuild-swiftc>"]
            llbuild_inputs.appendContentsOf(objects)
            yaml += "    inputs: \(llbuild_inputs)\n"
            let libPath = "\(workdir + modulename).a"
            yaml += "    outputs: [\"<atllbuild>\", \"\(libPath)\"]\n"
            
            //build the crazy args, mostly consisting of an `ar` shell command
            var shellCmd = "rm -rf \(libPath); ar cr '\(libPath)'"
            for obj in objects {
                shellCmd += " '\(obj)'"
            }
            let args = "[\"/bin/sh\",\"-c\",\(shellCmd)]"
            yaml += "    args: \(args)\n"
            yaml += "    description: \"Linking Library:  \(libPath)\""
        }
        
        
        return yaml
    }
    
    func run(args: [Yaml : Yaml]) throws {
        //create the working directory
        let workDirectory = ".atllbuild/"
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(workDirectory) {
            try manager.removeItemAtPath(workDirectory)
        }
        try manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        
        //parse arguments
        let outputType: OutputType
        if args["outputType"]?.string == "static-library" {
            outputType = .StaticLibrary
        }
        else if args["outputType"]?.string == "executable" {
            outputType = .Executable
        }
        else {
            throw AnarchyBuildError.CantParseYaml("Unknown outputType \(args["outputType"])")
        }
        
        var compileOptions: [String] = []
        if let opts = args["compileOptions"]?.array {
            for o in opts {
                guard let os = o.string else { throw AnarchyBuildError.CantParseYaml("Compile option \(o) is not a string") }
                compileOptions.append(os)
            }
        }
        guard let sourceDescriptions = args["source"]?.array?.flatMap({$0.string}) else { throw AnarchyBuildError.CantParseYaml("Can't find sources for atllbuild.") }
                let sources = collectSources(sourceDescriptions)

        guard let name = args["name"]?.string else { throw AnarchyBuildError.CantParseYaml("No name for atllbuild task") }
        
        let bootstrapOnly: Bool

        if args["bootstrapOnly"]?.bool == true {
            bootstrapOnly = true
        }
        else {
            bootstrapOnly = false
        }
        
        let sdk: Bool
        if args["linkSDK"]?.bool == false {
            sdk = false
        }
        else { sdk = true }
        
        let llbuildyamlpath : String

        if args ["llbuildyaml"]?.string != nil {
            llbuildyamlpath = args["llbuildyaml"]!.string!
        }
        else {
            llbuildyamlpath = workDirectory + "llbuild.yaml"
        }
        
        try llbuildyaml(sources, workdir: workDirectory, modulename: name, linkSDK: sdk, compileOptions: compileOptions, outputType: outputType).writeToFile(llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
        if bootstrapOnly { return }
        
        //now we try running sbt
        let args = ["-f",llbuildyamlpath]
        let sbt = NSTask.launchedTaskWithLaunchPath(SwiftBuildToolpath, arguments: args)
        sbt.waitUntilExit()
        if sbt.terminationStatus != 0 {
            throw AnarchyBuildError.ExternalToolFailed("\(SwiftBuildToolpath) " + args.joinWithSeparator(" "))
        }
    }
}