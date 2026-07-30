RASM ?= rasm
PYTHON ?= python3
OPENMSX ?= openmsx
EMULATOR_1983 ?= ../1983/1983
MODELS_1983 ?= ../1983/1983-models.conf
BBC_BASIC_DIR ?= ../bbcbasic-z80-msx

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
EMULATOR_1983_DIR := $(BUILD_DIR)/1983
EMULATOR_1983_SCREEN := $(EMULATOR_1983_DIR)/rainbios_logo.ppm
LOGO_DIR := $(BUILD_DIR)/logo
LOGO_STAMP := $(LOGO_DIR)/.converted
SOURCES := src/main_msx1.asm

.PHONY: all test test-openmsx test-openmsx-boot test-openmsx-options \
	test-openmsx-audio test-1983 check-bbcbasic clean

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
		-command 'set throttle off; after time 0.5 {keymatrixdown 8 0x01}; after time 0.55 {keymatrixup 8 0x01}; after time 0.8 {screenshot -raw -size 320 $(abspath $(OPENMSX_OPTIONS_SCREEN)); exit}'
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 2 --max-colors 4 $(OPENMSX_OPTIONS_SCREEN)

test-openmsx-audio: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'soundlog start $(abspath $(OPENMSX_JINGLE)); after realtime 1 {soundlog stop; exit}'
	$(PYTHON) tools/check_jingle_wav.py $(OPENMSX_JINGLE)

test-1983: $(MSX1_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(EMULATOR_1983) --config /dev/null --models $(MODELS_1983) \
		--model msx1 --region ntsc --bios $(MSX1_ROM) \
		--headless --unthrottled --exit-after 120 --dump-state \
		--screenshot $(EMULATOR_1983_SCREEN)
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_SCREEN)

check-bbcbasic:
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR)
	$(MAKE) -C $(BBC_BASIC_DIR) check

clean:
	rm -rf $(BUILD_DIR)
