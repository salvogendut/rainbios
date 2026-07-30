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
OPENMSX_M1_REPORT_DIR := $(OPENMSX_ROOT)/m1
OPENMSX_SLOT_REPORT := $(OPENMSX_M1_REPORT_DIR)/slot-calls.txt
OPENMSX_SERVICES_REPORT := $(OPENMSX_M1_REPORT_DIR)/services.txt
OPENMSX_KEYBOARD_REPORT := $(OPENMSX_M1_REPORT_DIR)/keyboard.txt
DIAGNOSTIC_CART := $(BUILD_DIR)/cartridges/primary_init.rom
DIAGNOSTIC_CART_SYM := $(BUILD_DIR)/cartridges/primary_init.sym
OPENMSX_CART_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_CARTRIDGE.xml
OPENMSX_CART_REPORT := $(OPENMSX_M1_REPORT_DIR)/cartridge.txt
OPENMSX_CART_SCREEN := $(OPENMSX_ROOT)/rainbios_cartridge.png
OPENMSX_BBC_BASIC_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_BBC_BASIC.xml
OPENMSX_BBC_BASIC_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/bbcbasic-smoke.txt
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
EMULATOR_1983_CART_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_cartridge.ppm
EMULATOR_1983_BBC_BASIC_SCREEN := \
	$(EMULATOR_1983_DIR)/bbcbasic-prompt.ppm
EMULATOR_1983_EXTERNAL_ARKANO_SCREEN := \
	$(EMULATOR_1983_DIR)/external-arkano.ppm
EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN := \
	$(EMULATOR_1983_DIR)/external-diagnostics.ppm
LOGO_DIR := $(BUILD_DIR)/logo
LOGO_STAMP := $(LOGO_DIR)/.converted
SOURCES := src/main_msx1.asm

.PHONY: all test test-openmsx test-openmsx-boot test-openmsx-options \
	test-openmsx-audio test-openmsx-m1 test-openmsx-slots \
	test-openmsx-services test-openmsx-keyboard test-openmsx-cartridge test-1983 \
	test-openmsx-bbcbasic test-1983-bbcbasic \
	test-1983-cartridge test-external-cartridges \
	test-openmsx-external-cartridges test-openmsx-external-arkano \
	test-openmsx-external-diagnostics test-1983-external-cartridges \
	test-1983-external-arkano test-1983-external-diagnostics check-bbcbasic \
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

$(DIAGNOSTIC_CART): tests/cartridges/primary_init.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DIAGNOSTIC_CART_SYM)

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

test-openmsx-slots: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set slot_output {$(abspath $(OPENMSX_SLOT_REPORT))}" \
		-script "$(abspath tests/openmsx/slot_calls_probe.tcl)"
	$(PYTHON) tools/check_slot_calls_probe.py $(OPENMSX_SLOT_REPORT)

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

$(OPENMSX_BBC_BASIC_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(BBC_BASIC_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(BBC_BASIC_ROM))|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-BBC-BASIC|' \
		-e 's|RainBIOS Diagnostic Cartridge|BBC BASIC Payload|' \
		$< > $@

test-openmsx-bbcbasic: $(OPENMSX_BBC_BASIC_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_BBC_BASIC \
		-command "set smoke_output {$(abspath $(OPENMSX_BBC_BASIC_REPORT))}" \
		-script "$(abspath $(BBC_BASIC_DIR)/tools/openmsx_smoke.tcl)"
	$(PYTHON) tools/check_bbcbasic_smoke.py $(OPENMSX_BBC_BASIC_REPORT)

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

test-1983-cartridge: $(MSX1_ROM) $(DIAGNOSTIC_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(DIAGNOSTIC_CART)" \
		--screenshot "$(EMULATOR_1983_CART_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_CART_SCREEN)

test-1983-bbcbasic: $(MSX1_ROM) $(BBC_BASIC_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_bbcbasic.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(BBC_BASIC_ROM)" \
		--screenshot "$(EMULATOR_1983_BBC_BASIC_SCREEN)"
	$(PYTHON) tools/check_bbcbasic_screenshot.py \
		$(EMULATOR_1983_BBC_BASIC_SCREEN)

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
