You can mixin settings to tasks via command line arguments

This allows you to enable or disable certain features, or support different platforms.

```clojure
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
             }
        }
  }

  :tasks {
        :atpkg {
                :tool "atllbuild"
                :source ["atpkg/src/**.swift"]
                :name "atpkg"
                :outputType "static-library"
                ;; if `--bootstrap yes`, these additional settings will appear here
                ;; :bootstrapOnly true
                ;; :llbuildyaml "bootstrap/bootstrap-macosx-atpkg.swift-build"
        }
  }
```