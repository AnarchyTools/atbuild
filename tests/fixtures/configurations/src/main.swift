#if ATBUILD_DEBUG
print("Debug build")
#elseif ATBUILD_RELEASE
print("Release build")
#elseif ATBUILD_TEST
print("Test build")
#elseif ATBUILD_BENCH
print("Bench build")
#elseif ATBUILD_JAMES_BOND
print("James bond build")
#endif