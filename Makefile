# Top Level Makefile for Flashfore AD5M Klipper Mod
SHELL := /bin/bash
BUILD := build_scripts/build.sh
VARIANTS = lite klipperscreen guppyscreen

CONFIGS_DIR := build_scripts/buildroot/configs
AVAILABLE_PLUGINS := $(patsubst $(CONFIGS_DIR)/plugin-%,%,$(wildcard $(CONFIGS_DIR)/plugin-*))

PLUGINS = $(strip $(WITH_PLUGINS))

INVALID_PLUGINS = $(filter-out $(AVAILABLE_PLUGINS), $(PLUGINS))
ifneq ($(INVALID_PLUGINS),)
$(error Unknown plugins: $(INVALID_PLUGINS))
endif

# MCU selection. Both boards default to the MCU the printer ships with;
# MCU sets them at once, EBOARD_MCU / MAINBOARD_MCU override a single board.
MCU_CONFIGS_DIR := build_scripts/components/mcu_configs
AVAILABLE_MCUS := $(sort $(patsubst $(MCU_CONFIGS_DIR)/eboard_%,%,$(wildcard $(MCU_CONFIGS_DIR)/eboard_*)))
DEFAULT_MCU := stm32f103

MCU ?= $(DEFAULT_MCU)
EBOARD_MCU ?= $(MCU)
MAINBOARD_MCU ?= $(MCU)

INVALID_MCUS = $(filter-out $(AVAILABLE_MCUS), $(sort $(EBOARD_MCU) $(MAINBOARD_MCU)))
ifneq ($(INVALID_MCUS),)
$(error Unknown MCUs: $(INVALID_MCUS))
endif

export EBOARD_MCU MAINBOARD_MCU

all: packages checksums
packages: sdk $(VARIANTS) uninstall

# SDK targets
sdk: sdk_package

sdk_prepare:
	$(BUILD) prepare_sdk

sdk_build: sdk_prepare
	$(BUILD) build_sdk

sdk_rebuild: sdk_prepare
	$(BUILD) rebuild_sdk

sdk_package: sdk_build
	$(BUILD) package_sdk

sdk_clean:
	$(BUILD) clean_sdk

# Variant targets
define VARIANT_RULES

$(1): $(1)_package

$(1)_prepare:
	$(BUILD) prepare_variant $(1)

$(1)_build: sdk_build $(1)_prepare
	$(BUILD) build_variant $(1)

$(1)_rebuild: sdk_build $(1)_prepare
	$(BUILD) rebuild_variant $(1)

$(1)_package: $(1)_build
	$(BUILD) package_variant $(1)

$(1)_clean:
	$(BUILD) clean_variant $(1)

endef

$(foreach variant,$(VARIANTS),$(eval $(call VARIANT_RULES,$(variant))))

# Misc targets
uninstall: uninstall_package

uninstall_package:
	$(BUILD) package_uninstall

checksums: packages
	$(BUILD) checksums

# Helper targets
.PHONY: help

help:
	@echo "Flashforge AD5M Klipper Mod Build System"
	@echo "========================================"
	@echo ""
	@echo "DESCRIPTION:"
	@echo "  This build system creates KlipperMod packages for Flashforge AD5M printers."
	@echo "  It supports multiple variants and optional plugins that can be embedded"
	@echo "  into the build through configuration fragments."
	@echo ""
	@echo "AVAILABLE VARIANTS:"
	@echo "  $(VARIANTS)"
	@echo ""
	@echo "AVAILABLE PLUGINS:"
	@echo "  $(AVAILABLE_PLUGINS)"
	@echo ""
	@echo "AVAILABLE MCUS:"
	@echo "  $(AVAILABLE_MCUS) (default: $(DEFAULT_MCU))"
	@echo ""
	@echo "MAIN TARGETS:"
	@echo "  all                    - Build all variants and create packages with checksums"
	@echo "  packages               - Build SDK, all variants, and uninstall package"
	@echo "  checksums              - Generate MD5 checksums for all packages"
	@echo "  sdk                    - Build SDK package only"
	@echo "  <variant>              - Build specific variant ($(VARIANTS))"
	@echo "  uninstall              - Create uninstall package"
	@echo ""
	@echo "PLUGIN USAGE:"
	@echo "  Plugins are embedded into variants using the WITH_PLUGINS parameter."
	@echo "  Multiple plugins can be specified as a space-separated list."
	@echo ""
	@echo "MCU USAGE:"
	@echo "  The toolhead board (eboard) and the mainboard (mcu) exist with"
	@echo "  different MCUs depending on the printer revision. MCU selects the"
	@echo "  MCU of both boards, EBOARD_MCU and MAINBOARD_MCU override a single"
	@echo "  board. Builds for a non-default MCU get their own build directory"
	@echo "  and package name."
	@echo ""
	@echo "EXAMPLES:"
	@echo "  # Build all variants without plugins"
	@echo "  make"
	@echo ""
	@echo "  # Build all variants with specific plugins"
	@echo "  make WITH_PLUGINS=\"shaketune moonraker_tg\""
	@echo ""
	@echo "  # Build specific variant without plugins"
	@echo "  make klipperscreen"
	@echo ""
	@echo "  # Build specific variant with plugins"
	@echo "  make klipperscreen WITH_PLUGINS=\"shaketune\""
	@echo ""
	@echo "  # Build without any plugins (empty string)"
	@echo "  make WITH_PLUGINS=\"\""
	@echo ""
	@echo "  # Build multiple variants with different plugins"
	@echo "  make klipperscreen WITH_PLUGINS=\"shaketune moonraker_tg\""
	@echo "  make guppyscreen WITH_PLUGINS=\"shaketune\""
	@echo ""
	@echo "  # Build for a printer whose boards both carry an N32G455"
	@echo "  make MCU=n32g455"
	@echo ""
	@echo "  # Build for a replacement toolhead board only"
	@echo "  make EBOARD_MCU=n32g455"
	@echo ""
	@echo "CLEAN TARGETS:"
	@echo "  sdk_clean              - Clean SDK build directory"
	@echo "  <variant>_clean        - Clean specific variant build directory"
	@echo ""
	@echo "REBUILD TARGETS:"
	@echo "  sdk_rebuild            - Force rebuild SDK"
	@echo "  <variant>_rebuild      - Force rebuild specific variant"
	@echo ""
	@echo "UTILITY TARGETS:"
	@echo "  help                   - Show this help message"
	@echo ""
	@echo "NOTES:"
	@echo "  - Plugins are automatically detected from build_scripts/buildroot/configs/plugin-*"
	@echo "  - MCUs are automatically detected from $(MCU_CONFIGS_DIR)/eboard_*"
	@echo "  - Each plugin+variant combination creates a separate build directory"
	@echo "  - Package names include plugin information for easy identification"
	@echo "  - Build directories: variant-<name>[-<mcu>][-<plugin1>-<plugin2>...]"
	@echo "  - Package names: Adventurer5M-KlipperMod-<version>-<variant>[-<mcu>][-<plugin1>-<plugin2>...].tgz"
