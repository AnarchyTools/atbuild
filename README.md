# atbuild

The Anarchy Tools Build Tool.

# Building

To build atbuild "from scratch", simply `./bootstrap.sh`.

Then you can check the program was built successfully:

```bash
$ ./atbuild --help
atbuild - Anarchy Tools Build Tool 0.1.0-dev
https://github.com/AnarchyTools
© 2016 Anarchy Tools Contributors.

Usage:
atbuild [task]
    task: ["default", "helloworld", "bootstrap"]
```

# Configuration

```bash
$ atbuild
$ atbuild build
$ atbuild build-tests
$ atbuild run-tests
```

The configuration file defines *tasks*, which are entrypoints on the CLI.  If no task is specified, we run a task called `default`.

Configurations look like this:

```bash
$ atbuild run-tests --platform linux
```

A complete build.atpkg example is below.

```clojure
;; This is a comment

(package
  :name "atbuild"

  ;;These "tasks" are just entrypoints on the CLI.
  ;;For example, `atbuild run-tests` runs the `run-tests` task.
  :tasks {

            :atbuild {
                :tool "atllbuild" ;;The tool for this task.  atllbuild compiles a swift project.  
                                  ;; For more information, see docs/attlbuild.md
                :source ["atbuild/src/**.swift"]
                :name "atbuild"
                :outputType "executable"
                :linkWithProduct ["attools.a" "atpkg.a"]
                :dependencies ["attools" "atpkg"]
            }

            :atpkg {
                :tool "atllbuild"
                :source ["atpkg/src/**.swift"]
                :name "atpkg"
                :outputType "static-library"
            }
                  
            :attools {
                :tool "atllbuild"
                :source ["attools/src/**.swift"]
                :name "attools"
                :outputType "static-library"
            }

            :atpkg-tests {
                :tool "atllbuild"
                :dependencies ["atpkg"]
                :source ["atpkg/tests/**.swift"]
                :name "atpkgtests"
                :outputType "executable"
                :linkWithProduct ["atpkg.a"]
            }

            :run-atpkg-tests {
                :tool "shell"
                :dependencies ["atpkg-tests"]
                :script "./.atllbuild/products/atpkgtests"
            }

            :run-tests {
                :dependencies ["run-atpkg-tests"]
                :tool "nop"
            }
    }

  ;;These configurations "override" task configurations when activated.
  ;;You activate a configuration via `atbuild --name [value]`
  :configurations {
        ;;Create a configuration called "bootstrap"
        :bootstrap {
             ;;If bootstrap is yes
             :yes {
                :atpkg { ;;specify additional options for atpkg
                  :bootstrapOnly true
                  :llbuildyaml "bootstrap/bootstrap-macosx-atpkg.swift-build"
                }
                :attools { ;;specify additional options for attools
                  :bootstrapOnly true
                  :llbuildyaml "bootstrap/bootstrap-macosx-attools.swift-build"
                }
                :atbuild { ;;specify additional options for atbuild
                  :bootstrapOnly true
                  :llbuildyaml "bootstrap/bootstrap-macosx-attools.swift-build"
                }
             }
        }
  }

)

```

The package file is a set of metadata to describe how the build process should work, and push all the actual work out to separate tools. There are a set of tools that are built-in that provide some of the standard behavior we want to support. At the same time, there are extension points to defining new tools as well. These tools can be defined within the package file or within source code for more advanced tools.

