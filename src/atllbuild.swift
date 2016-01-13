import Foundation

final class ATllbuild : Tool {
    
    func collectSources(sourceDescriptions: [String]) -> [String] {
        var sources : [String] = []
        for description in sourceDescriptions {
            if description.hasSuffix("**.swift") {
                let basepath = String(Array(description.characters)[0..<description.characters.count - 9])
                let manager = NSFileManager.defaultManager()
                let enumerator = manager.enumeratorAtPath(basepath)!
                while let source = enumerator.nextObject() as? String {
                    if source.hasSuffix("swift") {
                        sources.append(manager.currentDirectoryPath + "/" + basepath + "/" + source)
                    }
                }
            }
            else {
                sources.append(description)
            }
        }
        return sources
    }
    
    func llbuildyaml(sources: [String], workdir: String, modulename: String) -> String {
        //this format is largely undocumented, but I reverse-engineered it from SwiftPM.
        var yaml = "client:\n  name: swift-build\n\n"
        
        yaml += "tools: {}\n\n"

        
        yaml += "targets:\n"
        yaml += "  \"\": [<atllbuild>]\n"
        yaml += "  atllbuild: [<atllbuild>]\n"
        
        
        yaml += "commands:\n"
        yaml += "  <atllbuild-swiftc>:\n"
        yaml += "     tool: swift-compiler\n"
        #if os(OSX)
        yaml += "     executable: \"/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc\"\n"
        #else
            Unsupported!
        #endif
        yaml += "     inputs: \(sources)\n"
        yaml += "     outputs: [<atllbuild>]\n"
        yaml += "     sources: \(sources)\n"
        
        //swiftPM wants "objects" which is just a list of %.swift.o files.  We have to put them in a temp directory though.
        let objects = sources.map { (source) -> String in
            workdir + (source as NSString).lastPathComponent + ".o"
        }
        yaml += "     objects: \(objects)\n"
        
        yaml += "     module-name: \(modulename)\n"
        yaml += "     temps-path: \(workdir)/llbuildtmp\n"
        
        var args : [String] = []
        #if os(OSX)
        args.appendContentsOf(["-j8","-sdk","/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk"])
        #endif
        
        yaml += "     other-args: \(args)\n"

        return yaml
    }
    
    func run(args: [Yaml : Yaml]) throws {
        //parse arguments
        guard let sourceDescriptions = args["source"]?.array?.flatMap({$0.string}) else { throw AnarchyBuildError.CantParseYaml("Can't find sources for atllbuild.") }
                let sources = collectSources(sourceDescriptions)

        guard let name = args["name"]?.string else { throw AnarchyBuildError.CantParseYaml("No name for atllbuild task") }
        //create the working directory
        let workDirectory = NSFileManager.defaultManager().currentDirectoryPath + "/.atllbuild/"
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(workDirectory) {
            try manager.removeItemAtPath(workDirectory)
        }
        try manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        
        //emit the llbuild.yaml
        let llbuildyamlpath = workDirectory + "llbuild.yaml"
        try llbuildyaml(sources, workdir: workDirectory, modulename: name).writeToFile(llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
        
        //now we try running sbt
        //todo: don't hardcode this
        let sbtpath : String
        #if os(OSX)
            sbtpath = "/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool"
        #else
            Unsupported!
        #endif
        let sbt = NSTask.launchedTaskWithLaunchPath(sbtpath, arguments: ["-f",llbuildyamlpath])
        sbt.waitUntilExit()
    }
}