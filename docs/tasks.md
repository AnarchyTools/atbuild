# Tasks

All tasks have the following options:

```clojure
taskname: {
    ;;the name of a tool.  Valid tools are shell, atllbuild, nop
    :tool "tool"

    ;;What other tasks should run before this one.
    :dependency []
}
```
