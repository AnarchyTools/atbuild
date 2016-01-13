//
//  errors.swift
//  AnarchyToolsXcode
//
//  Created by Drew Crawford on 1/13/16.
//  Copyright © 2016 Drew Crawford. All rights reserved.
//

import Foundation

enum AnarchyBuildError : ErrorType {
    case CantParseYaml
    
    func throwMe() throws {
        throw self
    }
}