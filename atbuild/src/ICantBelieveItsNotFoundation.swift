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

//SR-138
#if os(Linux)
extension String {
    @warn_unused_result
    public func substringFromIndex(index: Index) -> String {
        return self.bridge().substringFromIndex(index._utf16Index)
    }
}
#endif
