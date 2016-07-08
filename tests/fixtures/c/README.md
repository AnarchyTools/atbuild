This tests C project support.  Some notes:

* Link with libcurl, which means libcurl-dev must be installed on your system.  This also tests the module-map-link option.
* We also test C/iOS support, however libcurl is not available on that platform.  So we just disable everything curl-related
