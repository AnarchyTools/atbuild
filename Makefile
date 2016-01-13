ARCH         = x86_64

CONFIG       = debug
PLATFORM = macosx
ROOT_DIR            = $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR           = $(ROOT_DIR)/bin
SRC_DIR = $(ROOT_DIR)/src
MODULE_NAME  = atbuild


## BUILD LOCATIONS ##
PLATFORM_BUILD_DIR    = $(BUILD_DIR)/$(MODULE_NAME)/bin/$(CONFIG)/$(PLATFORM)
PLATFORM_OBJ_DIR      = $(BUILD_DIR)/$(MODULE_NAME)/obj/$(CONFIG)/$(PLATFORM)
PLATFORM_TEMP_DIR     = $(BUILD_DIR)/$(MODULE_NAME)/tmp/$(CONFIG)/$(PLATFORM)

##  System Config ##

SDK_PATH     = $(shell xcrun --show-sdk-path -sdk $(PLATFORM))


TOOLCHAIN           = Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM)
TOOLCHAIN_PATH      = $(shell xcode-select --print-path)/$(TOOLCHAIN)

LDFLAGS      = -syslibroot $(SDK_PATH) -lSystem -arch $(ARCH) \
				-macosx_version_min 10.11.0 \
			   	-no_objc_category_merging -L $(TOOLCHAIN_PATH) \
				-rpath $(TOOLCHAIN_PATH)

SOURCE = $(notdir $(wildcard $(SRC_DIR)/*.swift))
tool: setup $(SOURCE) link

SWIFT = $(shell xcrun -f swift) -frontend -c -color-diagnostics
LD           = $(shell xcrun -f ld)

%.swift:
	$(SWIFT) $(CFLAGS) -primary-file $(SRC_DIR)/$@ \
		$(addprefix $(SRC_DIR)/,$(filter-out $@,$(SOURCE))) -sdk $(SDK_PATH) \
		-module-name $(MODULE_NAME) -o $(PLATFORM_OBJ_DIR)/$*.o -emit-module \
		-emit-module-path $(PLATFORM_OBJ_DIR)/$*~partial.swiftmodule

main.swift:
	$(SWIFT) $(CFLAGS) -primary-file $(SRC_DIR)/main.swift \
		$(addprefix $(SRC_DIR)/,$(filter-out $@,$(SOURCE))) -sdk $(SDK_PATH) \
		-module-name $(MODULE_NAME) -o $(PLATFORM_OBJ_DIR)/main.o -emit-module \
		-emit-module-path $(PLATFORM_OBJ_DIR)/main~partial.swiftmodule

link:
	echo "linkstep" $(PLATFORM_OBJ_DIR)
	$(LD) $(LDFLAGS) $(wildcard $(PLATFORM_OBJ_DIR)/*.o) \
		-o $(PLATFORM_BUILD_DIR)/$(OBJ_PRE)$(MODULE_NAME)$(OBJ_EXT)

setup:
	$(shell mkdir -p $(PLATFORM_OBJ_DIR))
	$(shell mkdir -p $(PLATFORM_BUILD_DIR))


clean:
	rm -rf $(BUILD_DIR)
