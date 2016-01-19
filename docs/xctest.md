# XCTest

atbuild is unopinionated about how you test your code; you can launch any executable as an atbuild [task](tasks.md), and use that executable to run tests.

However, if you want to use XCTest, it is tricky to configure, particularly as the implementation is quite different between platforms.  To smooth this problem out, `atbuild` includes some additonal options.

```clojure
(package
 :name "xctestexample"

     :tasks {
        ;; Define a task to build our library
        :build-lib {
            :tool "atllbuild"
            :source ["src/**.swift"]
            :outputType "static-library"
            :name "Foo"

            ;; Make sure we enable testing so that 
            ;; we can import with @testable
            :compileOptions ["-enable-testing"]
        }

        ;; Define a task to build the tests.
        ;; This is sometimes called a "test target" in Xcode.
        ;; This is primarily an executable that links our library.
        :build-tests {
            :tool "atllbuild"
            :source ["test/**.swift"]
            :outputType "executable"
            :name "footests"
            :dependencies ["build-lib"]
            :linkWithProduct["Foo.a"]

            ;; atbuild will inject platform-specific
            ;; compile options to make XCTest work
            :xctestify true

            ;; XCTest on Linux is a bit stricter
            ;; than on OSX.  Tell atbuild
            ;; we want stricter checks for API compliance
            :xctestStrict true
        }

        ;; A task to run our tests
        :run-tests {
            :dependencies ["build-tests"]

            ;; The xctestrun tool is a cross-platform XCTest runner
            :tool "xctestrun"

            ;; Tell xctestrun where we built our tests
            :testExecutable ".atllbuild/products/footests"
        }
     }
)
```

Now you can run your tests on any platform with just `atbuild run-tests`.

For more information, see a [complete example](tests/fixtures/xcs)