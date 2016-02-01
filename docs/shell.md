# shell

The shell tool allows you to call a shell command.

# API

```clojure
:taskname {
    :tool "shell"

    ;;run the following script in /bin/sh.
    ;;A non-zero return code indicates that build should halt.
    :script "echo hello world"
}
```

# Environment variables

## `ATBUILD_USER_PATH`

The `ATBUILD_USER_PATH` contains the path to a "user" directory.  You can use this directory however you like.

The directory is preserved across all tasks that are part of the same dependency chain, and is cleared between invocations to `atbuild`.

A common use of the `ATBUILD_USER_PATH` is to specify include information; see atllbuild's `includeWithUser` [documentation](/docs/atllbuild.md) for more information.
