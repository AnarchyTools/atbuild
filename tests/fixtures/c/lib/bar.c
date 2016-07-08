#include "baz.h"
void bar() {
    printf("hello from C");
    baz();
    //compile error if we don't get GOT_OPTIONS
    #ifndef GOT_OPTIONS
    #error didn't get options
    #endif
}