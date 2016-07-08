public func foo() {
    #if !os(iOS)
    curl_global_init(Int(CURL_GLOBAL_SSL))
    #endif

    bar()
}