# atllbuild

The `atllbuild` tool uses the [`swift-llbuild`](https://github.com/apple/swift-llbuild) project to compile a swift module.

## API

```clojure
:tasks {

  :build {
    :tool "atllbuild"

    ;;Name of the module to build
    :name "build"

    ;;Type of build.  "library" and "executable" are supported.
    :output-type "library" 

    ;;walk the src directory and recursively find all swift files
    :source ["src/**.swift"]

    ;;If true, we don't build, we only output llbuild.yaml  False is the default value.
    :bootstrapOnly: false
    ;;Path to emit llbuild.yaml
    :llbuildyaml "llbuild.yaml"

    ;;Provide an array of compile options.  NOTHING IS IMPOSSIBLE
    :compileOptions []

    :linkSDK true #Whether to link the platform SDK.  True is the default value.

    ;;A product from another atllbuild task to link with.
    ;;You should supply a filename here, like "yaml.a".
    ;;Note that this is for linking dependencies built by atllbuild; 
    ;;or other libraries, you should use UNSUPPORTED https://github.com/AnarchyTools/atbuild/issues/13
    :linkWithProduct ["attools.a" "atpkg.a"]

    ;;The path to swiftC.  By default, we guess based on your platform
    swiftCPath:"/usr/local/bin/swiftc"
  }
}
        
```

## Implementation

The `atllbuild` tool emits an `llbuild.yaml` file.  This is undocumented, but we [reverse-engineered the format from SwiftPM](https://github.com/apple/swift-package-manager).  You can see an example in our [repository](/llbuild.yaml).  Essentially, this file contains the compile/link commands for building the swift module.

Finally, we call `swift-build-tool -f /path/to/llbuild.yaml`.

## Boostrapping

In addition to building, we can choose to (only) emit the llbuild.yaml file, and save it for compiling later.

This is how we bootstrap atbuild, by creating an llbuild.yaml on a working machine and then using swift-build-tool on a new machine.  For this reason, the `llbuild.yaml` file in this repository must be kept up to date.