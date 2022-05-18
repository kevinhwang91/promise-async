SHELL := /bin/bash
DEPS ?= build

LUA_VERSION ?= luajit 2.1.0-beta3
NVIM_BIN ?= nvim
NVIM_LUA_VERSION := $(shell $(NVIM_BIN) -v 2>/dev/null | grep -E '^Lua(JIT)?' | tr A-Z a-z)
ifdef NVIM_LUA_VERSION
LUA_VERSION ?= $(NVIM_LUA_VERSION)
endif
LUA_NUMBER := $(word 2,$(LUA_VERSION))

TARGET_DIR := $(DEPS)/$(LUA_NUMBER)

HEREROCKS ?= $(DEPS)/hererocks.py
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
HEREROCKS_ENV ?= MACOSX_DEPLOYMENT_TARGET=10.15
endif
HEREROCKS_URL ?= https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py
HEREROCKS_ACTIVE := source $(TARGET_DIR)/bin/activate

LUAROCKS ?= $(TARGET_DIR)/bin/luarocks

BUSTED ?= $(TARGET_DIR)/bin/busted
BUSTED_HELPER ?= $(PWD)/spec/fixtures.lua

LUV ?= $(TARGET_DIR)/lib/lua/$(LUA_NUMBER)/luv.so

LUA_LS ?= $(DEPS)/lua-language-server
LINT_LEVEL ?= Information

all: deps

deps: | $(HEREROCKS) $(BUSTED)

test: test_lua test_nvim

test_lua: $(BUSTED) $(LUV)
	@echo Test with $(LUA_VERSION) ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
		lua spec/init.lua --helper=$(BUSTED_HELPER) $(BUSTED_ARGS)

ifdef NVIM_LUA_VERSION
test_nvim: $(BUSTED)
	@echo Test with Neovim ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
		$(NVIM_BIN) --clean -n --headless -u spec/init.lua -- \
		--helper=$(BUSTED_HELPER) $(BUSTED_ARGS)
endif

$(HEREROCKS):
	mkdir -p $(DEPS)
	curl $(HEREROCKS_URL) -o $@

$(LUAROCKS): $(HEREROCKS)
	$(HEREROCKS_ENV) python $< $(TARGET_DIR) --$(LUA_VERSION) -r latest

$(BUSTED): $(LUAROCKS)
	$(HEREROCKS_ACTIVE) && luarocks install busted

$(LUV): $(LUAROCKS)
	@$(HEREROCKS_ACTIVE) && [[ ! $$(luarocks which luv) ]] && \
		luarocks install luv || true

lint:
	@rm -rf $(LUA_LS)
	@mkdir -p $(LUA_LS)
	@lua-language-server --check $(PWD) --checklevel=$(LINT_LEVEL) --logpath=$(LUA_LS)
	@[[ -f $(LUA_LS)/check.json ]] && { cat $(LUA_LS)/check.json 2>/dev/null; exit 1; } || true

clean:
	rm -rf $(DEPS)

.PHONY: all deps clean lint test test_nvim test_lua
