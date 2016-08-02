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
import atpkg
import atfoundation

class PackageAtbin:Tool {
    private enum Options: String {
        case Name = "name"
        case Platforms = "platforms"
        case AtllbuildTask = "atllbuild-task"
        case Compress = "compress"
    }

    func run(task: Task) {

        guard let n_ = task[Options.Name.rawValue] else {
            fatalError("No \(Options.Name.rawValue) for \(task)")
        }
        guard case .StringLiteral(let name) = n_ else {
            fatalError("Non-string \(Options.Name.rawValue) for \(task)")
        }

        guard let t_ = task[Options.AtllbuildTask.rawValue] else {
            fatalError("No \(Options.AtllbuildTask.rawValue) for \(task)")
        }
        guard case .StringLiteral(let atllbuildTaskName) = t_ else {
            fatalError("Non-string \(Options.AtllbuildTask.rawValue) for \(task)")
        }
        guard let atllbuildTask = task.package.tasks[atllbuildTaskName]  else {
            fatalError("Unknown atllbuild task \(atllbuildTaskName) for \(task)")
        }

        //rm atbin if exists
        let atbinPath = Path("bin/\(name).atbin")
        let _ = try? FS.removeItem(path: atbinPath, recursive: true)
        try! FS.createDirectory(path: atbinPath, intermediate: true)

        //create working directory for lipo
        let workDir = Path(".atllbuild/lipo/")
        try! FS.createDirectory(path: workDir, intermediate: true)

        //restore old platform before leaving
        let oldPlatform = Platform.targetPlatform
        defer { Platform.targetPlatform = oldPlatform }

        guard case .some(.StringLiteral(let outputTypeString)) = atllbuildTask[ATllbuild.Options.OutputType.rawValue] else {
            fatalError("No \(ATllbuild.Options.OutputType.rawValue) for \(atllbuildTask) ")
        }

        guard let outputType = ATllbuild.OutputType(rawValue: outputTypeString) else {
            fatalError("Unknown \(ATllbuild.Options.OutputType.rawValue) \(outputTypeString)")
        }


        guard case .some(.StringLiteral(let outputName)) = atllbuildTask[ATllbuild.Options.Name.rawValue] else {
            fatalError("No \(ATllbuild.Options.Name.rawValue) for \(atllbuildTask)")
        }

        //for clarity, in the code below, we use moduleName when we refer to modules
        //and outputName when we refer to the atbin output.
        //by definition, the atbin output is the module name, but we might change this definition.  Who knows.
        let moduleName = outputName

        let payloadFileName: String
        switch(outputType) {
            case .DynamicLibrary:
            payloadFileName = "\(moduleName)\(Platform.targetPlatform.dynamicLibraryExtension)"
            case .StaticLibrary:
            payloadFileName = "\(moduleName).a"
            case .Executable:
            if case.some(.StringLiteral(let e)) = atllbuildTask[ATllbuild.Options.ExecutableName.rawValue] {
                payloadFileName = e
            }
            else  { payloadFileName = moduleName }
        }

        guard case .some(.Vector(let platformArray)) = task[Options.Platforms.rawValue] else {
            fatalError("No \(Options.Platforms.rawValue) for \(task)")
        }

        var requestedBuildPlatforms : [String] = []
        for requestedPlatform in platformArray {
            guard case .StringLiteral(let p) = requestedPlatform else {
                fatalError("Non-string platform \(requestedPlatform)")
            }
            requestedBuildPlatforms.append(p)
        }

        let targetPlatforms: [Platform]
        if requestedBuildPlatforms == ["all"] {
            targetPlatforms = Platform.targetPlatform.allPlatforms
        }else {
            targetPlatforms = Platform.targetPlatform.allPlatforms.filter({requestedBuildPlatforms.contains($0.description)})
        } 

        if targetPlatforms.count == 0 {
            print("Warning: The intersection of \(requestedBuildPlatforms) and \(Platform.targetPlatform.allPlatforms) is the empty set; won't build atbin")
            return
        }
        //iterate through supported platforms
        for platform in targetPlatforms {
            Platform.targetPlatform = platform
            //run the underlying atbuild task
            TaskRunner.runTask(task: atllbuildTask, package: task.package, force: true)

            //copy payload to lipo location
            try! FS.copyItem(from: Path(".atllbuild/products/\(payloadFileName)"), to: workDir.join(Path("\(payloadFileName).\(Platform.targetPlatform)")))

            let modulePath = Path(".atllbuild/products/\(moduleName).swiftmodule")
            if FS.fileExists(path: modulePath) {
                try! FS.copyItem(from: modulePath, to: atbinPath.join(Path("\(platform).swiftmodule")))
            }

            let docPath = Path(".atllbuild/products/\(moduleName).swiftdoc")
            if FS.fileExists(path: docPath) {
                try! FS.copyItem(from: docPath, to: atbinPath.join(Path("\(platform).swiftdoc")))
            }

            let moduleMapPath = Path(".atllbuild/products/\(moduleName).modulemap")
            if FS.fileExists(path: moduleMapPath) {
                try! FS.copyItem(from: moduleMapPath, to: atbinPath.join(Path("module.modulemap")))
            }
        }

        //lipo outputs
        switch(oldPlatform) {
            case .Linux:
            //no lipo, only one arch anyway
            try! FS.copyItem(from: workDir.join(Path("\(payloadFileName).\(Platform.targetPlatform)")), to: atbinPath.join(Path(payloadFileName)))

            case .OSX, .iOS, .iOSGeneric:
            var lipoCmd = "lipo -output bin/\(name).atbin/\(payloadFileName) -create "
            for platform in targetPlatforms {
                lipoCmd += "-arch \(platform.architecture) .atllbuild/lipo/\(payloadFileName).\(platform) "
            }
            anarchySystem(lipoCmd, environment: [:])
        }

        //generate compiled.atpkg
        var s = ""
        s += "(package\n"
        s += ":name \"\(name)\"\n"
        s += ":payload \"\(payloadFileName)\"\n"
        s += ":platforms ["
        for platform in targetPlatforms {
            s += "\"\(platform)\" "
        }
        s += "]\n"
        s += ":type \"\(outputType.rawValue)\"\n"
        s += ")\n"
        try! s.write(to: atbinPath.join(Path("compiled.atpkg")))

        if task[Options.Compress.rawValue]?.bool == true {

            let tarxz: String
            if let v = task.package.version {
                tarxz = "bin/\(name)-\(v)-\(Platform.targetPlatform).atbin.tar.xz"
            }
            else {
                tarxz = "bin/\(name)-\(Platform.targetPlatform).atbin.tar.xz"
            }
             
            let cmd: String
            switch Platform.hostPlatform {
                case .OSX:
                let fc = currentConfiguration.fastCompile == true
                let compressionLevel = fc ? "0" :"9"
                cmd = "tar c --options \"xz:compression-level=\(compressionLevel)\" -Jf \(tarxz) bin/\(name).atbin -C bin"
                case .Linux:
                let fc = currentConfiguration.fastCompile == true
                let compressionLevel = fc ? "0" :"8"
                cmd = "XZ_OPT=-\(compressionLevel) tar cJf \(tarxz) bin/\(name).atbin -C bin"
                default:
                fatalError("Unsupported host platform \(Platform.hostPlatform)")
            }
            anarchySystem(cmd, environment: [:])
        }
    }
}