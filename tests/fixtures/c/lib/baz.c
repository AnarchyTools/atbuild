#include "baz.h"
void baz() {
    #ifndef NO_CURL_AVAILABLE
    curl_global_init(CURL_GLOBAL_SSL);
    #endif
}