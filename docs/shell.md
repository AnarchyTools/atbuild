# shell

The shell tool allows you to call a shell command.

# API

```yaml
taskname:
    tool: "shell"

    #run the following script in /bin/sh.
    #A non-zero return code indicates that build should halt.
    script: "echo hello world"
```
