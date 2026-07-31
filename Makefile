RASM ?= rasm
PYTHON ?= python3
OPENMSX ?= openmsx
EMULATOR_1983 ?= ../1983/1983
MODELS_1983 ?= ../1983/1983-models.conf
BBC_BASIC_DIR ?= ../bbcbasic-z80-msx
BBC_ZMAC ?= zmac
BBC_LD80 ?= ld80
BBC_BASIC_ROM ?= $(BBC_BASIC_DIR)/build/msx-console/bbcbasic_msx_console.rom
ARKANO_ROM ?= ../1983/ROMS/Arkano.rom
MSX_DIAGNOSTICS_ROM ?= ../1983/ROMS/diag.rom

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
OPENMSX_M1_EXPANDED_RAM_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_EXPANDED_RAM.xml
OPENMSX_M1_REPORT_DIR := $(OPENMSX_ROOT)/m1
OPENMSX_SLOT_REPORT := $(OPENMSX_M1_REPORT_DIR)/slot-calls.txt
OPENMSX_EXPANDED_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_EXPANDED.xml
OPENMSX_EXPANDED_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/expanded-slot-calls.txt
OPENMSX_SERVICES_REPORT := $(OPENMSX_M1_REPORT_DIR)/services.txt
OPENMSX_KEYBOARD_REPORT := $(OPENMSX_M1_REPORT_DIR)/keyboard.txt
OPENMSX_FONT_REPORT := $(OPENMSX_M1_REPORT_DIR)/font.txt
DIAGNOSTIC_CART := $(BUILD_DIR)/cartridges/primary_init.rom
DIAGNOSTIC_CART_SYM := $(BUILD_DIR)/cartridges/primary_init.sym
MENU_INPUT_CART := $(BUILD_DIR)/cartridges/menu_input.rom
MENU_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/menu_input.sym
GRAPHICS_INPUT_CART := $(BUILD_DIR)/cartridges/graphics_input.rom
GRAPHICS_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/graphics_input.sym
DISK_BASELINE_CART := $(BUILD_DIR)/cartridges/disk_baseline_input.rom
DISK_BASELINE_CART_SYM := $(BUILD_DIR)/cartridges/disk_baseline_input.sym
DISK_ROM_BOOT_CART := $(BUILD_DIR)/cartridges/disk_rom_boot_input.rom
DISK_ROM_BOOT_CART_SYM := $(BUILD_DIR)/cartridges/disk_rom_boot_input.sym
NMS8250_DISK_ROM := $(BUILD_DIR)/rainbios_nms8250_disk.rom
NMS8250_DISK_ROM_SYM := $(BUILD_DIR)/rainbios_nms8250_disk.sym
NMS8250_DISK_SOURCES := src/disk_nms8250_rom.asm \
	src/disk_nms8250_driver.asm
DISK_PHYDIO_TEST_ROM := $(BUILD_DIR)/cartridges/disk_phydio_rom.rom
DISK_PHYDIO_TEST_ROM_SYM := $(BUILD_DIR)/cartridges/disk_phydio_rom.sym
DISK_PHYDIO_TEST_SOURCES := tests/cartridges/disk_phydio_rom.asm \
	src/disk_nms8250_driver.asm
DISK_NO_MEDIA_TEST_ROM := $(BUILD_DIR)/cartridges/disk_no_media_rom.rom
DISK_NO_MEDIA_TEST_ROM_SYM := $(BUILD_DIR)/cartridges/disk_no_media_rom.sym
DISK_NO_MEDIA_TEST_SOURCES := tests/cartridges/disk_no_media_rom.asm \
	src/disk_nms8250_driver.asm
DISK_PHYDIO_IMAGE := $(BUILD_DIR)/disks/disk-phydio.dsk
DISK_PARTIAL_TEST_ROM := $(BUILD_DIR)/cartridges/disk_partial_error_rom.rom
DISK_PARTIAL_TEST_ROM_SYM := $(BUILD_DIR)/cartridges/disk_partial_error_rom.sym
DISK_PARTIAL_TEST_SOURCES := tests/cartridges/disk_partial_error_rom.asm \
	src/disk_nms8250_driver.asm
DISK_PARTIAL_IMAGE := $(BUILD_DIR)/disks/disk-partial-error.dsk
DISK_PRODUCTION_INIT_CART := \
	$(BUILD_DIR)/cartridges/disk_production_init_input.rom
DISK_PRODUCTION_INIT_CART_SYM := \
	$(BUILD_DIR)/cartridges/disk_production_init_input.sym
TAPE_INPUT_CART := $(BUILD_DIR)/cartridges/tape_input.rom
TAPE_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/tape_input.sym
TAPE_PROBE_IMAGE := $(BUILD_DIR)/cassettes/tape-probe.cas
TAPE_LOAD_INPUT_CART := $(BUILD_DIR)/cartridges/tape_load_input.rom
TAPE_LOAD_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/tape_load_input.sym
TAPE_SAVE_INPUT_CART := $(BUILD_DIR)/cartridges/tape_save_input.rom
TAPE_SAVE_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/tape_save_input.sym
BBC_TAPE_IMAGE := $(BUILD_DIR)/cassettes/bbcbasic-tape.cas
INVALID_PAYLOAD_CART := $(BUILD_DIR)/cartridges/invalid_payload.rom
INVALID_PAYLOAD_CART_SYM := $(BUILD_DIR)/cartridges/invalid_payload.sym
OPENMSX_CART_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_CARTRIDGE.xml
OPENMSX_CART_REPORT := $(OPENMSX_M1_REPORT_DIR)/cartridge.txt
OPENMSX_CART_SCREEN := $(OPENMSX_ROOT)/rainbios_cartridge.png
OPENMSX_EXPANDED_CART_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_EXPANDED_CARTRIDGE.xml
OPENMSX_EXPANDED_CART_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/expanded-cartridge.txt
OPENMSX_EXPANDED_CART_SCREEN := \
	$(OPENMSX_ROOT)/rainbios_expanded_cartridge.png
OPENMSX_BBC_BASIC_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_BBC_BASIC.xml
OPENMSX_BBC_BASIC_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/bbcbasic-smoke.txt
OPENMSX_BBC_GRAPHICS_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/bbcbasic-graphics.txt
OPENMSX_BBC_GRAPHICS_SCREEN := \
	$(OPENMSX_ROOT)/bbcbasic-graphics.png
OPENMSX_BBC_BASIC_MENU_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/bbcbasic-menu.txt
OPENMSX_TAPE_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_TAPE.xml
OPENMSX_TAPE_REPORT := $(OPENMSX_M1_REPORT_DIR)/tape.txt
OPENMSX_BBC_TAPE_SAVE_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_BBC_TAPE_SAVE.xml
OPENMSX_BBC_TAPE_SAVE_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/bbcbasic-tape-save.txt
OPENMSX_BBC_TAPE_SAVE_IMAGE := \
	$(OPENMSX_ROOT)/bbcbasic-tape-save.wav
OPENMSX_EXPANDED_BBC_BASIC_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_EXPANDED_BBC_BASIC.xml
OPENMSX_EXPANDED_BBC_BASIC_MENU_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/expanded-bbcbasic-menu.txt
OPENMSX_INVALID_PAYLOAD_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_INVALID_PAYLOAD.xml
OPENMSX_INVALID_PAYLOAD_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/invalid-payload.txt
OPENMSX_EXTERNAL_ARKANO_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_EXTERNAL_ARKANO.xml
OPENMSX_EXTERNAL_DIAGNOSTICS_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_EXTERNAL_DIAGNOSTICS.xml
OPENMSX_EXTERNAL_ARKANO_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/external-arkano.txt
OPENMSX_EXTERNAL_DIAGNOSTICS_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/external-diagnostics.txt
OPENMSX_EXTERNAL_ARKANO_SCREEN := \
	$(OPENMSX_ROOT)/external-arkano.png
OPENMSX_EXTERNAL_DIAGNOSTICS_SCREEN := \
	$(OPENMSX_ROOT)/external-diagnostics.png
EMULATOR_1983_DIR := $(BUILD_DIR)/1983
EMULATOR_1983_SCREEN := $(EMULATOR_1983_DIR)/rainbios_logo.ppm
EMULATOR_1983_EXPANDED_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_msx2_expanded.ppm
EMULATOR_1983_CART_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_cartridge.ppm
EMULATOR_1983_BBC_BASIC_SCREEN := \
	$(EMULATOR_1983_DIR)/bbcbasic-prompt.ppm
EMULATOR_1983_BBC_GRAPHICS_SCREEN := \
	$(EMULATOR_1983_DIR)/bbcbasic-graphics.ppm
EMULATOR_1983_BBC_TAPE_SCREEN := \
	$(EMULATOR_1983_DIR)/bbcbasic-tape.ppm
EMULATOR_1983_DISK_BASELINE_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-baseline.ppm
EMULATOR_1983_DISK_ROM_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-rom-hook.ppm
EMULATOR_1983_DISK_PHYDIO_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-phydio-read.ppm
EMULATOR_1983_DISK_NO_MEDIA_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-no-media.ppm
EMULATOR_1983_DISK_WRITE_GUARD_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-write-guard.ppm
EMULATOR_1983_DISK_PARTIAL_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-partial-error.ppm
EMULATOR_1983_NMS8250_DISK_ROM_SCREEN := \
	$(EMULATOR_1983_DIR)/nms8250-disk-rom.ppm
EMULATOR_1983_EXTERNAL_ARKANO_SCREEN := \
	$(EMULATOR_1983_DIR)/external-arkano.ppm
EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN := \
	$(EMULATOR_1983_DIR)/external-diagnostics.ppm
LOGO_DIR := $(BUILD_DIR)/logo
LOGO_STAMP := $(LOGO_DIR)/.converted
SOURCES := src/main_msx1.asm

.PHONY: all test test-openmsx test-openmsx-boot test-openmsx-options \
	test-openmsx-audio test-openmsx-m1 test-openmsx-slots \
	test-openmsx-expanded-slots \
	test-openmsx-services test-openmsx-keyboard test-openmsx-font \
	test-openmsx-tape \
	test-1983-tape \
	test-openmsx-cartridge test-1983 \
	test-openmsx-expanded-cartridge \
	test-1983-expanded \
	test-openmsx-bbcbasic test-openmsx-bbcbasic-menu \
	test-openmsx-bbcbasic-graphics test-1983-bbcbasic-graphics \
	test-openmsx-bbcbasic-tape-save \
	test-1983-bbcbasic-tape \
	test-1983-disk-baseline test-1983-disk-boot test-1983-disk-read \
	test-1983-disk-no-media test-1983-disk-write-guard \
	test-1983-disk-partial-error test-1983-nms8250-disk-rom \
	test-openmsx-expanded-bbcbasic-menu \
	test-openmsx-payload-invalid test-1983-bbcbasic \
	test-1983-cartridge test-external-cartridges \
	test-openmsx-external-cartridges test-openmsx-external-arkano \
	test-openmsx-external-diagnostics test-1983-external-cartridges \
	test-1983-external-arkano test-1983-external-diagnostics check-bbcbasic \
	check-bbcbasic-artifact nms8250-disk-rom clean

all: $(MSX1_ROM)

nms8250-disk-rom: $(NMS8250_DISK_ROM)

$(BUILD_DIR):
	mkdir -p $@

$(LOGO_STAMP): src/logo.png tools/png_to_screen2.py | $(BUILD_DIR)
	mkdir -p $(LOGO_DIR)
	$(PYTHON) tools/png_to_screen2.py $< $(LOGO_DIR)
	touch $@

$(MSX1_ROM): $(SOURCES) $(LOGO_STAMP) | $(BUILD_DIR)
	$(RASM) $< -I$(LOGO_DIR) -ob $@ -s -os $(MSX1_SYM)

$(DIAGNOSTIC_CART): tests/cartridges/primary_init.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DIAGNOSTIC_CART_SYM)

$(MENU_INPUT_CART): tests/cartridges/menu_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(MENU_INPUT_CART_SYM)

$(GRAPHICS_INPUT_CART): tests/cartridges/graphics_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(GRAPHICS_INPUT_CART_SYM)

$(DISK_BASELINE_CART): tests/cartridges/disk_baseline_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DISK_BASELINE_CART_SYM)

$(DISK_ROM_BOOT_CART): tests/cartridges/disk_rom_boot_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DISK_ROM_BOOT_CART_SYM)

$(NMS8250_DISK_ROM): $(NMS8250_DISK_SOURCES) | $(BUILD_DIR)
	$(RASM) $< -Isrc -ob $(NMS8250_DISK_ROM) \
		-s -os $(NMS8250_DISK_ROM_SYM)

$(NMS8250_DISK_ROM_SYM): $(NMS8250_DISK_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(NMS8250_DISK_SOURCES)) -Isrc \
			-ob $(NMS8250_DISK_ROM) -s -os $@; \
	fi

$(DISK_PHYDIO_TEST_ROM): $(DISK_PHYDIO_TEST_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_PHYDIO_TEST_ROM) \
		-s -os $(DISK_PHYDIO_TEST_ROM_SYM)

$(DISK_PHYDIO_TEST_ROM_SYM): $(DISK_PHYDIO_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_PHYDIO_TEST_SOURCES)) -Isrc \
			-ob $(DISK_PHYDIO_TEST_ROM) -s -os $@; \
	fi

$(DISK_NO_MEDIA_TEST_ROM): $(DISK_NO_MEDIA_TEST_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_NO_MEDIA_TEST_ROM) \
		-s -os $(DISK_NO_MEDIA_TEST_ROM_SYM)

$(DISK_NO_MEDIA_TEST_ROM_SYM): $(DISK_NO_MEDIA_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_NO_MEDIA_TEST_SOURCES)) -Isrc \
			-ob $(DISK_NO_MEDIA_TEST_ROM) -s -os $@; \
	fi

$(DISK_PARTIAL_TEST_ROM): $(DISK_PARTIAL_TEST_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_PARTIAL_TEST_ROM) \
		-s -os $(DISK_PARTIAL_TEST_ROM_SYM)

$(DISK_PARTIAL_TEST_ROM_SYM): $(DISK_PARTIAL_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_PARTIAL_TEST_SOURCES)) -Isrc \
			-ob $(DISK_PARTIAL_TEST_ROM) -s -os $@; \
	fi

$(DISK_PRODUCTION_INIT_CART): \
		tests/cartridges/disk_production_init_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $(DISK_PRODUCTION_INIT_CART) \
		-s -os $(DISK_PRODUCTION_INIT_CART_SYM)

$(DISK_PRODUCTION_INIT_CART_SYM): $(DISK_PRODUCTION_INIT_CART)
	@if test ! -f "$@"; then \
		$(RASM) tests/cartridges/disk_production_init_input.asm \
			-ob $(DISK_PRODUCTION_INIT_CART) -s -os $@; \
	fi

$(DISK_PHYDIO_IMAGE): tools/make_test_disk.py | $(BUILD_DIR)
	$(PYTHON) $< $@

$(DISK_PARTIAL_IMAGE): tools/make_test_disk.py | $(BUILD_DIR)
	$(PYTHON) $< --one-side $@

$(TAPE_INPUT_CART): tests/cartridges/tape_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(TAPE_INPUT_CART_SYM)

$(TAPE_PROBE_IMAGE): tools/make_test_cassette.py | $(BUILD_DIR)
	$(PYTHON) $< $@

$(TAPE_LOAD_INPUT_CART): tests/cartridges/tape_load_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(TAPE_LOAD_INPUT_CART_SYM)

$(TAPE_SAVE_INPUT_CART): tests/cartridges/tape_save_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(TAPE_SAVE_INPUT_CART_SYM)

$(BBC_TAPE_IMAGE): $(BBC_BASIC_DIR)/tools/make_msx_tape_fixture.py | $(BUILD_DIR)
	$(PYTHON) $< $@

$(INVALID_PAYLOAD_CART): tests/cartridges/invalid_payload.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(INVALID_PAYLOAD_CART_SYM)

test: $(MSX1_ROM) $(NMS8250_DISK_ROM)
	PYTHONDONTWRITEBYTECODE=1 RAINBIOS_MSX1_ROM=$(MSX1_ROM) \
	RAINBIOS_NMS8250_DISK_ROM=$(NMS8250_DISK_ROM) \
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

$(OPENMSX_M1_EXPANDED_RAM_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXPANDED_RAM.xml.in $(MSX1_ROM)
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
		-command 'set throttle off; after time 1 {set throttle on; after realtime 0.25 {screenshot -raw -size 320 $(abspath $(OPENMSX_BOOT_SCREEN)); exit}}'
	$(PYTHON) tools/check_boot_screenshot.py $(OPENMSX_BOOT_SCREEN)

test-openmsx-options: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'set throttle off; after time 1.2 {keymatrixdown 8 0x01}; after time 1.3 {keymatrixup 8 0x01}; after time 1.8 {set throttle on; after realtime 0.25 {screenshot -raw -size 320 $(abspath $(OPENMSX_OPTIONS_SCREEN)); exit}}'
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 2 --max-colors 4 $(OPENMSX_OPTIONS_SCREEN)

test-openmsx-audio: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command 'soundlog start $(abspath $(OPENMSX_JINGLE)); after realtime 1 {soundlog stop; exit}'
	$(PYTHON) tools/check_jingle_wav.py $(OPENMSX_JINGLE)

test-openmsx-m1: $(OPENMSX_M1_MACHINES) $(OPENMSX_M1_SPLIT_MACHINE) \
		$(OPENMSX_M1_EXPANDED_RAM_MACHINE)
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
	@report="$(abspath $(OPENMSX_M1_REPORT_DIR))/expanded-ram.txt"; \
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_EXPANDED_RAM \
		-command "set m1_output {$$report}" \
		-script "$(abspath tests/openmsx/m1_probe.tcl)" || exit 1; \
	$(PYTHON) tools/check_m1_probe.py --ram-slot 3 \
		--expanded-primary 0 --expanded-primary 3 \
		--selector 0xA0 --bios-slot 0x80 "$$report"

test-openmsx-slots: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set slot_output {$(abspath $(OPENMSX_SLOT_REPORT))}" \
		-script "$(abspath tests/openmsx/slot_calls_probe.tcl)"
	$(PYTHON) tools/check_slot_calls_probe.py $(OPENMSX_SLOT_REPORT)

$(OPENMSX_EXPANDED_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXPANDED.xml.in $(MSX1_ROM)
	mkdir -p $(@D)
	sed 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' $< > $@

test-openmsx-expanded-slots: $(OPENMSX_EXPANDED_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_EXPANDED \
		-command "set expanded_output {$(abspath $(OPENMSX_EXPANDED_REPORT))}" \
		-script "$(abspath tests/openmsx/expanded_slot_calls_probe.tcl)"
	$(PYTHON) tools/check_expanded_slot_calls_probe.py \
		$(OPENMSX_EXPANDED_REPORT)

test-openmsx-services: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set services_output {$(abspath $(OPENMSX_SERVICES_REPORT))}" \
		-script "$(abspath tests/openmsx/services_probe.tcl)"
	$(PYTHON) tools/check_services_probe.py $(OPENMSX_SERVICES_REPORT)

test-openmsx-keyboard: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set keyboard_output {$(abspath $(OPENMSX_KEYBOARD_REPORT))}" \
		-script "$(abspath tests/openmsx/keyboard_probe.tcl)"
	$(PYTHON) tools/check_keyboard_probe.py $(OPENMSX_KEYBOARD_REPORT)

test-openmsx-font: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set font_output {$(abspath $(OPENMSX_FONT_REPORT))}" \
		-script "$(abspath tests/openmsx/font_probe.tcl)"
	$(PYTHON) tools/check_font_probe.py $(OPENMSX_FONT_REPORT)

$(OPENMSX_CART_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(DIAGNOSTIC_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(DIAGNOSTIC_CART))|' \
		$< > $@

test-openmsx-cartridge: $(OPENMSX_CART_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_CARTRIDGE \
		-command "set cartridge_output {$(abspath $(OPENMSX_CART_REPORT))}; set cartridge_screenshot {$(abspath $(OPENMSX_CART_SCREEN))}" \
		-script "$(abspath tests/openmsx/cartridge_probe.tcl)"
	$(PYTHON) tools/check_cartridge_probe.py $(OPENMSX_CART_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py $(OPENMSX_CART_SCREEN)

$(OPENMSX_EXPANDED_CART_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXPANDED_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(DIAGNOSTIC_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(DIAGNOSTIC_CART))|' \
		$< > $@

test-openmsx-expanded-cartridge: $(OPENMSX_EXPANDED_CART_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_EXPANDED_CARTRIDGE \
		-command "set cartridge_output {$(abspath $(OPENMSX_EXPANDED_CART_REPORT))}; set cartridge_screenshot {$(abspath $(OPENMSX_EXPANDED_CART_SCREEN))}" \
		-script "$(abspath tests/openmsx/cartridge_probe.tcl)"
	$(PYTHON) tools/check_cartridge_probe.py --expected-slot F8 \
		--expected-exptbl 00,00,80,00 --expected-slttbl 00,00,08,00 \
		$(OPENMSX_EXPANDED_CART_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py $(OPENMSX_EXPANDED_CART_SCREEN)

$(OPENMSX_BBC_BASIC_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(BBC_BASIC_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(BBC_BASIC_ROM))|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-BBC-BASIC|' \
		-e 's|RainBIOS Diagnostic Cartridge|BBC BASIC Payload|' \
		$< > $@

test-openmsx-bbcbasic-menu: $(OPENMSX_BBC_BASIC_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_BBC_BASIC \
		-command "set payload_menu_output {$(abspath $(OPENMSX_BBC_BASIC_MENU_REPORT))}" \
		-script "$(abspath tests/openmsx/payload_menu_probe.tcl)"
	$(PYTHON) tools/check_payload_menu_probe.py \
		$(OPENMSX_BBC_BASIC_MENU_REPORT)

$(OPENMSX_EXPANDED_BBC_BASIC_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXPANDED_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(BBC_BASIC_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(BBC_BASIC_ROM))|' \
		-e 's|RainBIOS-MSX1-M1-EXPANDED-CARTRIDGE|RainBIOS-EXPANDED-BBC-BASIC|' \
		-e 's|RainBIOS Expanded Diagnostic Cartridge|Expanded BBC BASIC Payload|' \
		$< > $@

test-openmsx-expanded-bbcbasic-menu: $(OPENMSX_EXPANDED_BBC_BASIC_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_EXPANDED_BBC_BASIC \
		-command "set payload_menu_output {$(abspath $(OPENMSX_EXPANDED_BBC_BASIC_MENU_REPORT))}" \
		-script "$(abspath tests/openmsx/payload_menu_probe.tcl)"
	$(PYTHON) tools/check_payload_menu_probe.py \
		--payload-slot 8A --launch-slot F8 \
		$(OPENMSX_EXPANDED_BBC_BASIC_MENU_REPORT)

test-openmsx-bbcbasic: test-openmsx-bbcbasic-menu
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_BBC_BASIC \
		-command "set smoke_output {$(abspath $(OPENMSX_BBC_BASIC_REPORT))}; after time 1.20 {keymatrixdown 8 0x01}; after time 1.30 {keymatrixup 8 0x01}; after time 2.00 {keymatrixdown 0 0x02}; after time 2.10 {keymatrixup 0 0x02}" \
		-script "$(abspath $(BBC_BASIC_DIR)/tools/openmsx_smoke.tcl)"
	$(PYTHON) tools/check_bbcbasic_smoke.py $(OPENMSX_BBC_BASIC_REPORT)

test-openmsx-bbcbasic-graphics: $(OPENMSX_BBC_BASIC_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_BBC_BASIC \
		-command "set graphics_output {$(abspath $(OPENMSX_BBC_GRAPHICS_REPORT))}; set graphics_screenshot {$(abspath $(OPENMSX_BBC_GRAPHICS_SCREEN))}; after time 1.20 {keymatrixdown 8 0x01}; after time 1.30 {keymatrixup 8 0x01}; after time 2.00 {keymatrixdown 0 0x02}; after time 2.10 {keymatrixup 0 0x02}" \
		-script "$(abspath $(BBC_BASIC_DIR)/tools/openmsx_graphics.tcl)"
	$(PYTHON) $(BBC_BASIC_DIR)/tools/check_openmsx_graphics.py \
		$(OPENMSX_BBC_GRAPHICS_REPORT)

$(OPENMSX_TAPE_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(TAPE_INPUT_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(TAPE_INPUT_CART))|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-TAPE|' \
		-e 's|RainBIOS Diagnostic Cartridge|Tape Input Probe|' \
		$< > $@

test-openmsx-tape: $(OPENMSX_TAPE_MACHINE) $(TAPE_PROBE_IMAGE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_TAPE \
		-cassetteplayer "$(abspath $(TAPE_PROBE_IMAGE))" \
		-command "set tape_output {$(abspath $(OPENMSX_TAPE_REPORT))}" \
		-script "$(abspath tests/openmsx/tape_probe.tcl)"
	$(PYTHON) tools/check_tape_probe.py $(OPENMSX_TAPE_REPORT)

$(OPENMSX_BBC_TAPE_SAVE_MACHINE): \
		tests/openmsx/RainBIOS_M1_TWO_CARTRIDGES.xml.in \
		$(MSX1_ROM) $(BBC_BASIC_ROM) $(TAPE_SAVE_INPUT_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE1_ROM@|$(abspath $(BBC_BASIC_ROM))|' \
		-e 's|@CARTRIDGE2_ROM@|$(abspath $(TAPE_SAVE_INPUT_CART))|' \
		-e 's|RainBIOS-MSX1-M1-TWO-CARTRIDGES|RainBIOS-BBC-TAPE-SAVE|' \
		$< > $@

test-openmsx-bbcbasic-tape-save: $(OPENMSX_BBC_TAPE_SAVE_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_BBC_TAPE_SAVE \
		-command "set tape_save_output {$(abspath $(OPENMSX_BBC_TAPE_SAVE_REPORT))}; set tape_save_image {$(abspath $(OPENMSX_BBC_TAPE_SAVE_IMAGE))}" \
		-script "$(abspath tests/openmsx/tape_save_probe.tcl)"
	$(PYTHON) tools/check_tape_save_probe.py \
		--tape $(OPENMSX_BBC_TAPE_SAVE_IMAGE) \
		$(OPENMSX_BBC_TAPE_SAVE_REPORT)

test-1983-tape: $(MSX1_ROM) $(TAPE_INPUT_CART) $(TAPE_PROBE_IMAGE)
	$(PYTHON) tools/run_1983_tape.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(TAPE_INPUT_CART)" \
		--cassette "$(TAPE_PROBE_IMAGE)"

$(OPENMSX_INVALID_PAYLOAD_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(INVALID_PAYLOAD_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(INVALID_PAYLOAD_CART))|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-INVALID-PAYLOAD|' \
		-e 's|RainBIOS Diagnostic Cartridge|Invalid Payload|' \
		$< > $@

test-openmsx-payload-invalid: $(OPENMSX_INVALID_PAYLOAD_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_INVALID_PAYLOAD \
		-command "set invalid_payload_output {$(abspath $(OPENMSX_INVALID_PAYLOAD_REPORT))}" \
		-script "$(abspath tests/openmsx/invalid_payload_probe.tcl)"
	$(PYTHON) tools/check_invalid_payload_probe.py \
		$(OPENMSX_INVALID_PAYLOAD_REPORT)

$(OPENMSX_EXTERNAL_ARKANO_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXTERNAL_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(ARKANO_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(ARKANO_ROM))|' \
		-e 's|@MACHINE_CODE@|RainBIOS-EXTERNAL-ARKANO|' \
		$< > $@

$(OPENMSX_EXTERNAL_DIAGNOSTICS_MACHINE): \
		tests/openmsx/RainBIOS_M1_EXTERNAL_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(MSX_DIAGNOSTICS_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(MSX_DIAGNOSTICS_ROM))|' \
		-e 's|@MACHINE_CODE@|RainBIOS-EXTERNAL-DIAGNOSTICS|' \
		$< > $@

test-openmsx-external-cartridges: test-openmsx-external-arkano \
		test-openmsx-external-diagnostics

test-openmsx-external-arkano: $(OPENMSX_EXTERNAL_ARKANO_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_EXTERNAL_ARKANO \
		-command "set external_output {$(abspath $(OPENMSX_EXTERNAL_ARKANO_REPORT))}; set external_screenshot {$(abspath $(OPENMSX_EXTERNAL_ARKANO_SCREEN))}" \
		-script "$(abspath tests/openmsx/external_cartridge_probe.tcl)"
	$(PYTHON) tools/check_external_cartridge_probe.py \
		--vdp-r0 02 --vdp-r1 E0 $(OPENMSX_EXTERNAL_ARKANO_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 2 $(OPENMSX_EXTERNAL_ARKANO_SCREEN)

test-openmsx-external-diagnostics: \
		$(OPENMSX_EXTERNAL_DIAGNOSTICS_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_EXTERNAL_DIAGNOSTICS \
		-command "set external_output {$(abspath $(OPENMSX_EXTERNAL_DIAGNOSTICS_REPORT))}; set external_screenshot {$(abspath $(OPENMSX_EXTERNAL_DIAGNOSTICS_SCREEN))}" \
		-script "$(abspath tests/openmsx/external_cartridge_probe.tcl)"
	$(PYTHON) tools/check_external_cartridge_probe.py \
		--vdp-r0 00 --vdp-r1 F0 \
		$(OPENMSX_EXTERNAL_DIAGNOSTICS_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 2 $(OPENMSX_EXTERNAL_DIAGNOSTICS_SCREEN)

test-1983: $(MSX1_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_m1.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --screenshot "$(EMULATOR_1983_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_SCREEN)

test-1983-expanded: $(MSX1_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_m1.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model msx2 --expected-subslot A0 \
		--bios "$(MSX1_ROM)" --screenshot "$(EMULATOR_1983_EXPANDED_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_EXPANDED_SCREEN)

test-1983-cartridge: $(MSX1_ROM) $(DIAGNOSTIC_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(DIAGNOSTIC_CART)" \
		--screenshot "$(EMULATOR_1983_CART_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_CART_SCREEN)

test-1983-bbcbasic: $(MSX1_ROM) $(BBC_BASIC_ROM) $(MENU_INPUT_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_bbcbasic.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(BBC_BASIC_ROM)" \
		--input-cartridge "$(MENU_INPUT_CART)" \
		--screenshot "$(EMULATOR_1983_BBC_BASIC_SCREEN)"
	$(PYTHON) tools/check_bbcbasic_screenshot.py \
		$(EMULATOR_1983_BBC_BASIC_SCREEN)

test-1983-bbcbasic-graphics: \
		$(MSX1_ROM) $(BBC_BASIC_ROM) $(GRAPHICS_INPUT_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_bbcbasic_graphics.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(BBC_BASIC_ROM)" \
		--input-cartridge "$(GRAPHICS_INPUT_CART)" \
		--screenshot "$(EMULATOR_1983_BBC_GRAPHICS_SCREEN)"
	$(PYTHON) tools/check_graphics_screenshot.py \
		$(EMULATOR_1983_BBC_GRAPHICS_SCREEN)

test-1983-bbcbasic-tape: \
		$(MSX1_ROM) $(BBC_BASIC_ROM) $(TAPE_LOAD_INPUT_CART) $(BBC_TAPE_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_bbcbasic_tape.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(BBC_BASIC_ROM)" \
		--input-cartridge "$(TAPE_LOAD_INPUT_CART)" \
		--cassette "$(BBC_TAPE_IMAGE)" \
		--screenshot "$(EMULATOR_1983_BBC_TAPE_SCREEN)"
	$(PYTHON) tools/check_bbcbasic_screenshot.py \
		$(EMULATOR_1983_BBC_TAPE_SCREEN)

test-1983-disk-baseline: \
		$(MSX1_ROM) $(DISK_BASELINE_CART) $(DISK_BASELINE_CART_SYM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(DISK_BASELINE_CART)" \
		--symbols "$(DISK_BASELINE_CART_SYM)" \
		--screenshot "$(EMULATOR_1983_DISK_BASELINE_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_BASELINE_SCREEN)

test-1983-disk-boot: \
		$(MSX1_ROM) $(DISK_ROM_BOOT_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --bios "$(MSX1_ROM)" \
		--symbols "$(DISK_ROM_BOOT_CART_SYM)" \
		--expected-pass-label disk_rom_boot_pass \
		--expected-slot FC \
		--disk-rom "$(DISK_ROM_BOOT_CART)" \
		--screenshot "$(EMULATOR_1983_DISK_ROM_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_ROM_SCREEN)

test-1983-disk-read: \
		$(MSX1_ROM) $(DISK_PHYDIO_TEST_ROM) \
		$(DISK_PHYDIO_TEST_ROM_SYM) $(DISK_PHYDIO_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_PHYDIO_TEST_ROM)" \
		--symbols "$(DISK_PHYDIO_TEST_ROM_SYM)" \
		--expected-pass-label disk_phydio_read_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_PHYDIO_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_DISK_PHYDIO_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_PHYDIO_SCREEN)

test-1983-disk-no-media: $(MSX1_ROM) $(DISK_NO_MEDIA_TEST_ROM) \
		$(DISK_NO_MEDIA_TEST_ROM_SYM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_NO_MEDIA_TEST_ROM)" \
		--symbols "$(DISK_NO_MEDIA_TEST_ROM_SYM)" \
		--expected-pass-label disk_no_media_pass \
		--expected-slot FC --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_DISK_NO_MEDIA_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_NO_MEDIA_SCREEN)

test-1983-disk-write-guard: \
		$(MSX1_ROM) $(DISK_PHYDIO_TEST_ROM) \
		$(DISK_PHYDIO_TEST_ROM_SYM) $(DISK_PHYDIO_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_PHYDIO_TEST_ROM)" \
		--symbols "$(DISK_PHYDIO_TEST_ROM_SYM)" \
		--expected-pass-label disk_phydio_read_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_PHYDIO_IMAGE)" --floppy-mode read-write \
		--expect-disk-unchanged \
		--screenshot "$(EMULATOR_1983_DISK_WRITE_GUARD_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_WRITE_GUARD_SCREEN)

test-1983-disk-partial-error: \
		$(MSX1_ROM) $(DISK_PARTIAL_TEST_ROM) \
		$(DISK_PARTIAL_TEST_ROM_SYM) $(DISK_PARTIAL_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_PARTIAL_TEST_ROM)" \
		--symbols "$(DISK_PARTIAL_TEST_ROM_SYM)" \
		--expected-pass-label disk_partial_error_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_PARTIAL_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_DISK_PARTIAL_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_PARTIAL_SCREEN)

test-1983-nms8250-disk-rom: $(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(DISK_PRODUCTION_INIT_CART) $(DISK_PRODUCTION_INIT_CART_SYM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--cartridge "$(DISK_PRODUCTION_INIT_CART)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--symbols "$(DISK_PRODUCTION_INIT_CART_SYM)" \
		--expected-pass-label disk_production_init_pass \
		--expected-slot F4 --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_NMS8250_DISK_ROM_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_NMS8250_DISK_ROM_SCREEN)

test-1983-external-cartridges: test-1983-external-arkano \
		test-1983-external-diagnostics

test-1983-external-arkano: $(MSX1_ROM) $(ARKANO_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(ARKANO_ROM)" \
		--screenshot "$(EMULATOR_1983_EXTERNAL_ARKANO_SCREEN)" \
		--exit-after 1200 --expected-slot D4 \
		--expected-vdp-r0 02 --expected-vdp-r1 E0
	$(PYTHON) tools/check_boot_screenshot.py --min-colors 2 \
		--size 640x480 $(EMULATOR_1983_EXTERNAL_ARKANO_SCREEN)

test-1983-external-diagnostics: $(MSX1_ROM) $(MSX_DIAGNOSTICS_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(MSX_DIAGNOSTICS_ROM)" \
		--screenshot "$(EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN)" \
		--exit-after 1200 --expected-slot D4 \
		--expected-vdp-r0 00 --expected-vdp-r1 F0
	$(PYTHON) tools/check_boot_screenshot.py --min-colors 2 \
		--size 640x480 $(EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN)

test-external-cartridges: test-openmsx-external-cartridges \
		test-1983-external-cartridges

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
