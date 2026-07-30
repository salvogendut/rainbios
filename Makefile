RASM ?= rasm
PYTHON ?= python3
OPENMSX ?= openmsx
EMULATOR_1983 ?= ../1983/1983
MODELS_1983 ?= ../1983/1983-models.conf
BBC_BASIC_DIR ?= ../bbcbasic-z80-msx
BBC_ZMAC ?= zmac
BBC_LD80 ?= ld80

BUILD_DIR := build
MSX1_ROM := $(BUILD_DIR)/rainbios_msx1.rom
MSX1_SYM := $(BUILD_DIR)/rainbios_msx1.sym
OPENMSX_ROOT := $(BUILD_DIR)/openmsx
OPENMSX_SHARE := $(OPENMSX_ROOT)/share
OPENMSX_HOME := $(OPENMSX_ROOT)/home
OPENMSX_MACHINE := $(OPENMSX_SHARE)/machines/RainBIOS_MSX1.xml
OPENMSX_BOOT_SCREEN := $(OPENMSX_ROOT)/rainbios_logo.png
OPENMSX_OPTIONS_SCREEN := $(OPENMSX_ROOT)/rainbios_options.png
OPENMSX_JINGLE := $(OPENMSX_ROOT)/rainbios_jingle.wav
OPENMSX_M1_SLOTS := 1 2 3
OPENMSX_M1_MACHINES := $(foreach slot,$(OPENMSX_M1_SLOTS),\
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM$(slot).xml)
OPENMSX_M1_SPLIT_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_SPLIT.xml
OPENMSX_M1_REPORT_DIR := $(OPENMSX_ROOT)/m1
EMULATOR_1983_DIR := $(BUILD_DIR)/1983
EMULATOR_1983_SCREEN := $(EMULATOR_1983_DIR)/rainbios_logo.ppm
LOGO_DIR := $(BUILD_DIR)/logo
LOGO_STAMP := $(LOGO_DIR)/.converted
SOURCES := src/main_msx1.asm

.PHONY: all test test-openmsx test-openmsx-boot test-openmsx-options \
	test-openmsx-audio test-openmsx-m1 test-1983 check-bbcbasic \
	check-bbcbasic-artifact clean

all: $(MSX1_ROM)

$(BUILD_DIR):
	mkdir -p $@

$(LOGO_STAMP): src/logo.png tools/png_to_screen2.py | $(BUILD_DIR)
	mkdir -p $(LOGO_DIR)
	$(PYTHON) tools/png_to_screen2.py $< $(LOGO_DIR)
	touch $@

$(MSX1_ROM): $(SOURCES) $(LOGO_STAMP) | $(BUILD_DIR)
	$(RASM) $< -I$(LOGO_DIR) -ob $@ -s -os $(MSX1_SYM)

test: $(MSX1_ROM)
	PYTHONDONTWRITEBYTECODE=1 RAINBIOS_MSX1_ROM=$(MSX1_ROM) \
	$(PYTHON) -m unittest discover -s tests -v

$(OPENMSX_MACHINE): tests/openmsx/RainBIOS_MSX1.xml.in $(MSX1_ROM)
	mkdir -p $(@D)
	sed 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' $< > $@

$(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM%.xml: \
		tests/openmsx/RainBIOS_M1.xml.in $(MSX1_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@RAM_SLOT@|$*|g' $< > $@

$(OPENMSX_M1_SPLIT_MACHINE): \
		tests/openmsx/RainBIOS_M1_SPLIT.xml.in $(MSX1_ROM)
	mkdir -p $(@D)
	sed 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' $< > $@

test-openmsx: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 -testconfig

test-openmsx-boot: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'set throttle off; after time 1 {screenshot -raw -size 320 $(abspath $(OPENMSX_BOOT_SCREEN)); exit}'
	$(PYTHON) tools/check_boot_screenshot.py $(OPENMSX_BOOT_SCREEN)

test-openmsx-options: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'set throttle off; after time 1.2 {keymatrixdown 8 0x01}; after time 1.3 {keymatrixup 8 0x01}; after time 1.8 {screenshot -raw -size 320 $(abspath $(OPENMSX_OPTIONS_SCREEN)); exit}'
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 2 --max-colors 4 $(OPENMSX_OPTIONS_SCREEN)

test-openmsx-audio: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'soundlog start $(abspath $(OPENMSX_JINGLE)); after realtime 1 {soundlog stop; exit}'
	$(PYTHON) tools/check_jingle_wav.py $(OPENMSX_JINGLE)

test-openmsx-m1: $(OPENMSX_M1_MACHINES) $(OPENMSX_M1_SPLIT_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	@for slot in $(OPENMSX_M1_SLOTS); do \
		report="$(abspath $(OPENMSX_M1_REPORT_DIR))/ram$$slot.txt"; \
		OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
		OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
		$(OPENMSX) -machine RainBIOS_M1_RAM$$slot \
			-command "set m1_output {$$report}" \
			-script "$(abspath tests/openmsx/m1_probe.tcl)" || exit 1; \
		$(PYTHON) tools/check_m1_probe.py \
			--ram-slot $$slot "$$report" || exit 1; \
	done
	@report="$(abspath $(OPENMSX_M1_REPORT_DIR))/split.txt"; \
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_SPLIT \
		-command "set m1_output {$$report}" \
		-script "$(abspath tests/openmsx/m1_probe.tcl)" || exit 1; \
	$(PYTHON) tools/check_m1_probe.py --ram-slot 2 "$$report"

test-1983: $(MSX1_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_m1.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --screenshot "$(EMULATOR_1983_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_SCREEN)

check-bbcbasic:
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR)
	$(MAKE) -C $(BBC_BASIC_DIR) check

check-bbcbasic-artifact:
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR) --skip-artifact
	$(MAKE) -C $(BBC_BASIC_DIR) check
	$(MAKE) -C $(BBC_BASIC_DIR) msx-console \
		ZMAC="$(BBC_ZMAC)" LD80="$(BBC_LD80)"
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR) --require-artifact

clean:
	rm -rf $(BUILD_DIR)
