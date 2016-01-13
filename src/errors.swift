//  errors
//  © 2016 Anarchy Tools Contributors.
//  This file is part of atbuild.  It is subject to the license terms in the LICENSE
//  file found in the top level of this distribution
//  No part of atbuild, including this file, may be copied, modified,
//  propagated, or distributed except according to the terms contained
//  in the LICENSE file.

enum AnarchyBuildError : ErrorType {
    case CantParseYaml(String) ///There is a problem with your yaml file.
    case ExternalToolFailed(String) ///An external tool returned a non-zero status code.  The string should contain the entire invocation of the tool, so the user can debug.
}