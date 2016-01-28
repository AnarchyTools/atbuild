# Overlays

You can activate settings, called "overlays", by passing them on the command line.

```bash
$ atbuild --overlay bar
```

This activates the settings for the overlay across all targets:

```clojure
(package
  :name "Foo"
  :overlays {
    :bar {
        :compileOptions ["-D" "FOO"]
    }
  }
)
```

You can add as many overlays as you like: `atbuild --overlay bar --overlay baz`.  They are processed in order.

# Task-scoped overlays

You can also only apply an overlay to a particular task.  To do this:

```clojure
(package
  :name "Foo"
  :tasks {
    :foo {
        :overlays {
            :bar {
                :compileOptions ["-D" "BAZ"]
            }
        }
    }
  }
)
```

Now when we build with `--overlay bar`, this will add `-D BAZ` to compile options for the `foo` task, but not for other tasks in our file.

# 'Always' overlay

We can use an overlay even when it was not specified on the CLI.  This way we can share common configuration options between several tasks.

```clojure
(package
  :name "Foo"
  :overlays {
    :optimized {
        :compileOptions ["-Owholemodule"] ;;whole module optimization
    }
  }
  :tasks {
    :foo {
        :overlay ["optimized"] ;;apply to this task
    }
    :baz {
        :overlay ["optimized"] ;;apply to this task too
    }
  }
)
```

# Imported overlays

Overlays can be [imported](import.md).  This allows libraries to export required compile flags to clients.

```clojure
(package
   :name "Library"
   :overlays {
    :compile-linux {
        :compileOptions ["-Xcc" "-fblocks"] ;; work around https://bugs.swift.org/browse/SR-397
    }
   }
)
```

```clojure
(package
   :name "Executable"
   :import ["Library.atpkg"]
   :tasks {
    :foo {
        :overlay ["Library.compile-linux"] ;;apply to this task
    }
)
```

# Required overlays

You can specify that an overlay must be applied to a task.

```clojure
(package
   :tasks {
    :foo {
        :required-overlays [["osx" "linux"] ["debug" "release"]] ;;at least one of osx/linux and one of debug/release must be applied
    }
)
```
