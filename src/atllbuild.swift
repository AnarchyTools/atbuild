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
                        sources.append(source)
                    }
                }
            }
            else {
                sources.append(description)
            }
        }
        return sources
    }
    
    func llbuildyaml(sources: [String]) -> String {
        //this format is largely undocumented, but I reverse-engineered it from SwiftPM.
        var yaml = "client:\n  name: swift-build\n\n"
        yaml += "targets:\n"
        yaml += "  \"\": []\n"
        return yaml
    }
    
    func run(args: [Yaml : Yaml]) throws {
        //parse sources
        guard let sourceDescriptions = args["source"]?.array?.flatMap({$0.string}) else { throw AnarchyBuildError.CantParseYaml("Can't find sources for atllbuild.") }
                let sources = collectSources(sourceDescriptions)

        
        //create the working directory
        let workDirectory = NSFileManager.defaultManager().currentDirectoryPath + "/.atllbuild/"
        let manager = NSFileManager.defaultManager()
        if manager.fileExistsAtPath(workDirectory) {
            try manager.removeItemAtPath(workDirectory)
        }
        try manager.createDirectoryAtPath(workDirectory, withIntermediateDirectories: false, attributes: nil)
        
        //emit the llbuild.yaml
        let llbuildyamlpath = workDirectory + "llbuild.yaml"
        try llbuildyaml(sources).writeToFile(llbuildyamlpath, atomically: false, encoding: NSUTF8StringEncoding)
        
        //now we try running sbt
        //todo: don't hardcode this
        let sbt = NSTask.launchedTaskWithLaunchPath("/Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swift-build-tool", arguments: ["-f",llbuildyamlpath])
        sbt.waitUntilExit()
    }
}