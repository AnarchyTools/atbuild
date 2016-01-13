import Foundation

enum AnarchyBuildError : ErrorType {
    case CantParseYaml(String)
    case ExternalToolFailed(String)
}