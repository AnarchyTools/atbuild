//  Nop.swift
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

import Foundation

///Nop is a tool that has no effect
final class Nop: Tool {
    func run(args: [Yaml : Yaml]) throws {
        //nothing
    }
}