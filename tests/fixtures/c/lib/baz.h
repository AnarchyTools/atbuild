#if __arm64__
#define NO_CURL_AVAILABLE
#endif

#ifndef NO_CURL_AVAILABLE
#include <curl/curl.h>
#endif

void baz();