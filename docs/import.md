You can import tasks in remote files.

This is useful to depend on tasks specified in another package.

```clojure
(package
  :name "atbuild"

  ;; import all the tasks in `atpkg/build.atpkg`.
  ;; These will be imported as `packagename.taskname`.
  ;; Since you cannot declare packages with periods manually, this 
  ;; cannot conflict with any current tasks
  :import ["atpkg/build.atpkg"]

  ;; We can then depend on a target from the remote package in our current one

  :tasks {
        :mytask {
            :tool "atllbuild"
            :source ["src/**.swift]
            :name "mytask"
            :outputType "executable"
            :dependencies ["atpkg.atpkg"]
        }
  }
)
```

You can also reference remote tasks on the command line by providing their fully-qualified name:

```bash
$ atbuild atpkg.atpkg
$ atbuild mytask
$ atbuild atbuild.mytask #equivalent to previous line
```

Packages are imported in a flat topology; if `a` imports `b` and `b` imports `c`, use `c.taskname` to refer to the task, not `b.c.taskname` or `a.b.c.taskname`.

# Implementation note

Remote packages may have paths specified in a key, like "source".  *Quite possibly, these keys should be interpreted relative to the path the task was declared in, NOT the working directory.*

To support this, `Task` has a property `importedPath` that tools may want to use.