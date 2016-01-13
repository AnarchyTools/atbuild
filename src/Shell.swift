//  main.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

///The Shell tool runs a shell script.  It expects a zero return code.
final class Shell : Tool {
    func run(args: [Yaml: Yaml]) throws {
        guard let script = args["script"]?.string else { throw AnarchyBuildError.CantParseYaml("Invalid 'script' argument to shell tool.") }
        let t = NSTask.launchedTaskWithLaunchPath("/bin/sh", arguments: ["-c",script])
        t.waitUntilExit()
        if t.terminationStatus != 0 {
            throw AnarchyBuildError.ExternalToolFailed("/bin/sh -c \(script)")
        }
    }
}