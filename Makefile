# Makefile for building port binaries
#
# Makefile targets:
#
# all/install   build and install the NIF
# clean         clean build products and intermediates
#
# Variables to override:
#
# MIX_APP_PATH  path to the build directory
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# LDFLAGS	linker flags for linking all binaries

PREFIX = $(MIX_APP_PATH)/priv
BUILD  = $(MIX_APP_PATH)/obj

DEFAULT_TARGETS ?= $(PREFIX) $(PREFIX)/dev_bridge

CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter -pedantic

# Enable for debug messages
# CFLAGS += -DDEBUG

CFLAGS += -std=gnu99

ifeq ($(origin CROSSCOMPILE), undefined)
SUDO_ASKPASS ?= /usr/bin/ssh-askpass
SUDO ?= true

# If not cross-compiling, then run sudo and suid the port binary
# so that it's possible to debug
update_perms = \
	echo "Not crosscompiling. To test locally, the port binary may need extra permissions.";\
	echo "Set SUDO=sudo to set permissions. The default is to skip this step.";\
	echo "SUDO_ASKPASS=$(SUDO_ASKPASS)";\
	echo "SUDO=$(SUDO)";\
	SUDO_ASKPASS=$(SUDO_ASKPASS) $(SUDO) -- sh -c 'chown root:root $(1); chmod +s $(1)'
else
# If cross-compiling, then permissions need to be set some build system-dependent way
update_perms =
endif

calling_from_make:
	mix compile

all: install

install: $(BUILD) $(DEFAULT_TARGETS)

$(BUILD)/%.o: src/%.c
	@echo " CC $(notdir $@)"
	$(CC) -c $(CFLAGS) -o $@ $<

$(PREFIX)/dev_bridge: $(BUILD)/dev_bridge.o $(BUILD)/eframer.o
	@echo " LD $(notdir $@)"
	$(CC) $^ $(LDFLAGS) -o $@
	$(call update_perms, $@)

$(PREFIX) $(BUILD):
	mkdir -p $@

clean:
	$(RM) $(PREFIX)/dev_bridge $(BUILD)/*.o

.PHONY: all clean calling_from_make install

# Don't echo commands unless the caller exports "V=1"
${V}.SILENT:
