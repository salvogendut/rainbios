RASM ?= rasm
PYTHON ?= python3
HOST_CC ?= cc
LOGO_SOURCE := src/logo-simple.png
OPENMSX ?= openmsx
EMULATOR_1983 ?= ../1983/1983
MODELS_1983 ?= ../1983/1983-models.conf
BBC_BASIC_DIR ?= ../bbcbasic-z80-msx
BBC_ZMAC ?= zmac
BBC_LD80 ?= ld80
BBC_BASIC_ROM ?= $(BBC_BASIC_DIR)/build/msx-console/bbcbasic_msx_console.rom
ARKANO_ROM ?= ../1983/ROMS/Arkano.rom
MSX_DIAGNOSTICS_ROM ?= ../1983/ROMS/diag.rom
SUNRISE_ROM ?= ../1983/ROMS/Nextor-2.1.1.SunriseIDE.ROM
SD_MAPPER_ROM ?= ../1983/ROMS/SDM V2 Nextor2.1.1.rom
NEXTOR_SYS ?= ../1983/DOS/NEXTOR.SYS
NEXTOR_COMMAND ?= ../1983/DOS/COMMAND2.COM
CBIOS_SUB_ROM ?= ../cbios-0.29a/roms/cbios_sub.rom
GEOBENCH_IMAGE ?= ../geobench/QA/GBMSX.IMG
OPENMSX_GEOBENCH_CAPTURE_TIME ?= 15

BUILD_DIR := build
MSX1_ROM := $(BUILD_DIR)/rainbios_msx1.rom
MSX1_SYM := $(BUILD_DIR)/rainbios_msx1.sym
MSX2_ROM := $(BUILD_DIR)/rainbios_msx2.rom
MSX2_SYM := $(BUILD_DIR)/rainbios_msx2.sym
MSX2_SUB_ROM := $(BUILD_DIR)/rainbios_msx2_sub.rom
MSX2_SUB_SYM := $(BUILD_DIR)/rainbios_msx2_sub.sym
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
OPENMSX_MAPPER_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_MAPPER.xml
OPENMSX_MAPPER_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/mapper.txt
OPENMSX_SERVICES_REPORT := $(OPENMSX_M1_REPORT_DIR)/services.txt
OPENMSX_KEYBOARD_REPORT := $(OPENMSX_M1_REPORT_DIR)/keyboard.txt
OPENMSX_CONTROLLER_REPORT := $(OPENMSX_M1_REPORT_DIR)/controller.txt
OPENMSX_CURSOR_REPORT := $(OPENMSX_M1_REPORT_DIR)/cursor.txt
OPENMSX_VRAM_REPORT := $(OPENMSX_M1_REPORT_DIR)/vram.txt
OPENMSX_SCREENMODES_REPORT := $(OPENMSX_M1_REPORT_DIR)/screen-modes.txt
OPENMSX_SPRITE_REPORT := $(OPENMSX_M1_REPORT_DIR)/sprite.txt
OPENMSX_GRPPRT_REPORT := $(OPENMSX_M1_REPORT_DIR)/grpprt.txt
OPENMSX_TEXTCTL_REPORT := $(OPENMSX_M1_REPORT_DIR)/textctl.txt
OPENMSX_VDPSTATE_REPORT := $(OPENMSX_M1_REPORT_DIR)/vdpstate.txt
OPENMSX_COLOR_REPORT := $(OPENMSX_M1_REPORT_DIR)/color.txt
OPENMSX_SCREEN3_REPORT := $(OPENMSX_M1_REPORT_DIR)/screen3.txt
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
DISK_DSKCHG_TEST_ROM := $(BUILD_DIR)/cartridges/disk_dskchg_getdpb_rom.rom
DISK_DSKCHG_TEST_ROM_SYM := $(BUILD_DIR)/cartridges/disk_dskchg_getdpb_rom.sym
DISK_DSKCHG_TEST_SOURCES := tests/cartridges/disk_dskchg_getdpb_rom.asm \
	src/disk_nms8250_driver.asm
DISK_DSKCHG_NO_MEDIA_TEST_ROM := \
	$(BUILD_DIR)/cartridges/disk_dskchg_no_media_rom.rom
DISK_DSKCHG_NO_MEDIA_TEST_ROM_SYM := \
	$(BUILD_DIR)/cartridges/disk_dskchg_no_media_rom.sym
DISK_DSKCHG_NO_MEDIA_TEST_SOURCES := \
	tests/cartridges/disk_dskchg_no_media_rom.asm \
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
DISK_BOOT_SECTOR := tests/cartridges/disk_boot_sector.asm
DISK_BOOT_SECTOR_BIN := $(BUILD_DIR)/disk_boot_sector.bin
DISK_BOOT_SECTOR_SYM := $(BUILD_DIR)/disk_boot_sector.sym
DISK_BOOT_IMAGE := $(BUILD_DIR)/disks/disk-boot.dsk
IDE_BOOT_SECTOR := tests/cartridges/ide_boot_sector.asm
IDE_BOOT_SECTOR_BIN := $(BUILD_DIR)/ide_boot_sector.bin
IDE_BOOT_SECTOR_SYM := $(BUILD_DIR)/ide_boot_sector.sym
IDE_BOOT_IMAGE := $(BUILD_DIR)/disks/ide-boot.img
SD_BOOT_SECTOR := tests/cartridges/sd_boot_sector.asm
SD_BOOT_SECTOR_BIN := $(BUILD_DIR)/sd_boot_sector.bin
SD_BOOT_SECTOR_SYM := $(BUILD_DIR)/sd_boot_sector.sym
SD_BOOT_IMAGE := $(BUILD_DIR)/disks/sd-boot.img
NEXTOR_IMAGE := $(BUILD_DIR)/disks/nextor.img
DISK_FAULT_TEST_ROM := $(BUILD_DIR)/cartridges/disk_fault_rom.rom
DISK_FAULT_TEST_ROM_SYM := $(BUILD_DIR)/cartridges/disk_fault_rom.sym
DISK_FAULT_TEST_SOURCES := tests/cartridges/disk_fault_rom.asm \
	src/disk_nms8250_driver.asm
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
CLS_INPUT_CART := $(BUILD_DIR)/cartridges/cls_input.rom
CLS_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/cls_input.sym
VALID_PAYLOAD_CART := $(BUILD_DIR)/cartridges/payload_valid.rom
VALID_PAYLOAD_CART_SYM := $(BUILD_DIR)/cartridges/payload_valid.sym
MENU_DISK2_INPUT_CART := $(BUILD_DIR)/cartridges/menu_disk2_input.rom
MENU_DISK2_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/menu_disk2_input.sym
MENU_DISK3_INPUT_CART := $(BUILD_DIR)/cartridges/menu_disk3_input.rom
MENU_DISK3_INPUT_CART_SYM := $(BUILD_DIR)/cartridges/menu_disk3_input.sym
OPENMSX_CART_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_CARTRIDGE.xml
OPENMSX_CART_REPORT := $(OPENMSX_M1_REPORT_DIR)/cartridge.txt
OPENMSX_CART_SCREEN := $(OPENMSX_ROOT)/rainbios_cartridge.png
OPENMSX_FAULT_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_DISK_FAULT.xml
OPENMSX_FAULT_REPORT := $(OPENMSX_M1_REPORT_DIR)/disk-fault.txt
OPENMSX_CLS_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_M1_CLS_CARTRIDGE.xml
OPENMSX_CLS_REPORT := $(OPENMSX_M1_REPORT_DIR)/cls.txt
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
OPENMSX_EMBEDDED_BASIC_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/embedded-basic.txt
OPENMSX_EMBEDDED_BASIC_SCREEN := \
	$(OPENMSX_ROOT)/embedded-basic.png
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
OPENMSX_GEOBENCH_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_GeoBench.xml
OPENMSX_MSX2_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_MSX2.xml
OPENMSX_MSX2_REPORT := $(OPENMSX_M1_REPORT_DIR)/msx2.txt
OPENMSX_MSX2_SCREEN := $(OPENMSX_ROOT)/msx2.png
OPENMSX_MSX2_SUBROM_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_MSX2_SUBROM.xml
OPENMSX_MSX2_SUBROM_REPORT := $(OPENMSX_M1_REPORT_DIR)/msx2-subrom.txt
OPENMSX_MSX2_SUBROM_SCREEN := $(OPENMSX_ROOT)/msx2-subrom.png
SUBROM_PROBE_ROM := $(BUILD_DIR)/subroms/subrom_probe.rom
SUBROM_PROBE_CART := $(BUILD_DIR)/cartridges/subrom_probe.rom
SUBROM_SERVICES_PROBE_CART := \
	$(BUILD_DIR)/cartridges/subrom_services_probe.rom
OPENMSX_MSX2_SERVICES_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_MSX2_SERVICES.xml
OPENMSX_MSX2_SERVICES_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/msx2-services.txt
OPENMSX_MSX2_SERVICES_SCREEN := $(OPENMSX_ROOT)/msx2-services.png
SUBROM_CMDCLOCK_PROBE_CART := \
	$(BUILD_DIR)/cartridges/subrom_cmdclock_probe.rom
OPENMSX_MSX2_CMDCLOCK_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_MSX2_CMDCLOCK.xml
OPENMSX_MSX2_CMDCLOCK_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/msx2-cmdclock.txt
OPENMSX_MSX2_CMDCLOCK_SCREEN := $(OPENMSX_ROOT)/msx2-cmdclock.png
OPENMSX_MSX2_64K_MACHINE := \
	$(OPENMSX_SHARE)/machines/RainBIOS_MSX2_64K.xml
OPENMSX_MSX2_64K_REPORT := \
	$(OPENMSX_M1_REPORT_DIR)/msx2-64k.txt
OPENMSX_MSX2_64K_SCREEN := $(OPENMSX_ROOT)/msx2-64k.png
EMULATOR_1983_MSX2_SUBROM_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_msx2_subrom.ppm
OPENMSX_GEOBENCH_REPORT := $(OPENMSX_M1_REPORT_DIR)/geobench-sunrise.txt
OPENMSX_GEOBENCH_SCREEN := $(OPENMSX_ROOT)/geobench-sunrise.png
OPENMSX_SUNRISE_SYSTEM_ROM := \
	$(OPENMSX_SHARE)/systemroms/Nextor-2.1.1.SunriseIDE.ROM
OPENMSX_GEOBENCH_IMAGE := $(OPENMSX_ROOT)/media/geobench-sunrise.img
EMULATOR_1983_DIR := $(BUILD_DIR)/1983
EMULATOR_1983_SCREEN := $(EMULATOR_1983_DIR)/rainbios_logo.ppm
EMULATOR_1983_EXPANDED_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_msx2_expanded.ppm
EMULATOR_1983_MSX2_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_msx2.ppm
EMULATOR_1983_CART_SCREEN := \
	$(EMULATOR_1983_DIR)/rainbios_cartridge.ppm
EMULATOR_1983_BBC_BASIC_SCREEN := \
	$(EMULATOR_1983_DIR)/bbcbasic-prompt.ppm
EMULATOR_1983_EMBEDDED_BASIC_SCREEN := \
	$(EMULATOR_1983_DIR)/embedded-basic-prompt.ppm
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
EMULATOR_1983_DISK_BOOT_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-boot.ppm
EMULATOR_1983_DISK_BOOT_FALLBACK_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-boot-fallback.ppm
EMULATOR_1983_DISK_BOOT_MENU_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-boot-menu.ppm
EMULATOR_1983_DISK_MENU_STUB_SCREEN := \
	$(EMULATOR_1983_DIR)/disk-menu-stub.ppm
EMULATOR_1983_IDE_BOOT_SCREEN := \
	$(EMULATOR_1983_DIR)/ide-boot.ppm
EMULATOR_1983_IDE_MENU_SCREEN := \
	$(EMULATOR_1983_DIR)/ide-menu.ppm
EMULATOR_1983_SD_BOOT_SCREEN := \
	$(EMULATOR_1983_DIR)/sd-boot.ppm
EMULATOR_1983_SD_MENU_SCREEN := \
	$(EMULATOR_1983_DIR)/sd-menu.ppm
EMULATOR_1983_SD_EMPTY_FLOPPY_SCREEN := \
	$(EMULATOR_1983_DIR)/sd-empty-floppy-boot.ppm
EMULATOR_1983_SD_EMPTY_SUNRISE_SCREEN := \
	$(EMULATOR_1983_DIR)/sd-empty-sunrise-nextor.ppm
EMULATOR_1983_NEXTOR_SCREEN := \
	$(EMULATOR_1983_DIR)/nextor-prompt.ppm
EMULATOR_1983_NEXTOR_SD_A_SCREEN := \
	$(EMULATOR_1983_DIR)/nextor-sd-a-prompt.ppm
EMULATOR_1983_NEXTOR_SD_B_SCREEN := \
	$(EMULATOR_1983_DIR)/nextor-sd-b-prompt.ppm
EMULATOR_1983_NEXTOR_SD_DUAL_SCREEN := \
	$(EMULATOR_1983_DIR)/nextor-sd-dual-prompt.ppm
EMULATOR_1983_GEOBENCH_SUNRISE_SCREEN := \
	$(EMULATOR_1983_DIR)/geobench-sunrise.ppm
EMULATOR_1983_GEOBENCH_SD_SCREEN := \
	$(EMULATOR_1983_DIR)/geobench-sd.ppm
EMULATOR_1983_EXTERNAL_ARKANO_SCREEN := \
	$(EMULATOR_1983_DIR)/external-arkano.ppm
EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN := \
	$(EMULATOR_1983_DIR)/external-diagnostics.ppm
EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN3_SCREEN := \
	$(EMULATOR_1983_DIR)/external-diagnostics-screen3.ppm
LOGO_DIR := $(BUILD_DIR)/logo
LOGO_STAMP := $(LOGO_DIR)/.converted
LOGO_COMPRESSED_ASSETS := $(addprefix $(LOGO_DIR)/, \
	options_name_ready.zx0 options_name_missing.zx0 options_color.zx0 \
	logo_pattern.zx0 logo_name.zx0 logo_color.zx0)
ZX0_TOOL := $(BUILD_DIR)/tools/zx0
ZX0_TOOL_SOURCES := tools/zx0/zx0.c tools/zx0/zx0.h \
	tools/zx0/optimize.c tools/zx0/compress.c tools/zx0/memory.c
BBC_EMBED_DIR := $(BUILD_DIR)/payload
BBC_PAYLOAD_ROM := $(BBC_EMBED_DIR)/bbcbasic_msx_console.rom
BBC_EMBEDDED_ROM := $(BBC_EMBED_DIR)/bbcbasic_msx_console.zx0
SOURCES := src/main_msx1.asm src/ide_nms8250_driver.asm \
	src/zx0_decompress.asm

.PHONY: all test test-openmsx test-openmsx-boot test-openmsx-options \
	test-openmsx-audio test-openmsx-m1 test-openmsx-slots \
	test-openmsx-expanded-slots test-openmsx-mapper \
	test-openmsx-services test-openmsx-keyboard 	test-openmsx-cursor \
	test-openmsx-vram \
	test-openmsx-screen-modes \
	test-openmsx-sprites \
	test-openmsx-grpprt \
	test-openmsx-textctl \
	test-openmsx-vdpstate \
	test-openmsx-color \
	test-openmsx-screen3 \
	test-openmsx-controller \
	test-openmsx-geobench-sunrise \
	test-openmsx-font \
	test-openmsx-cls \
	test-openmsx-tape \
	test-1983-tape \
	test-openmsx-cartridge test-1983 \
	test-openmsx-disk-fault \
	test-openmsx-expanded-cartridge \
	test-1983-expanded test-openmsx-embedded-basic \
	test-openmsx-msx2 test-1983-msx2 \
	test-openmsx-msx2-subrom test-1983-msx2-subrom \
	test-openmsx-msx2-services test-1983-msx2-subrom-services \
	test-openmsx-msx2-cmdclock test-1983-msx2-subrom-cmdclock \
	test-openmsx-msx2-64k \
	test-openmsx-bbcbasic test-openmsx-bbcbasic-menu \
	test-openmsx-bbcbasic-graphics test-1983-bbcbasic-graphics \
	test-openmsx-bbcbasic-tape-save \
	test-1983-bbcbasic-tape \
	test-1983-disk-baseline test-1983-disk-boot \
	test-1983-disk-boot-production test-1983-disk-boot-fallback \
	test-1983-disk-boot-menu test-1983-disk-menu-stub \
	test-1983-disk-read test-1983-disk-no-media \
	test-1983-disk-write-guard \
	test-1983-disk-dskchg-getdpb test-1983-disk-dskchg-no-media \
	test-1983-disk-partial-error test-1983-nms8250-disk-rom \
	test-1983-ide-boot test-1983-ide-menu \
	test-1983-sd-boot test-1983-sd-menu test-1983-sd-empty-floppy \
	test-1983-sd-empty-sunrise \
	test-1983-nextor test-1983-nextor-sd \
	test-1983-geobench-sunrise test-1983-geobench-sd \
	run-1983-ide-boot run-1983-sd-boot run-1983-nextor \
	test-openmsx-expanded-bbcbasic-menu \
	test-openmsx-payload-invalid test-1983-bbcbasic \
	test-1983-embedded-basic \
	test-1983-cartridge test-external-cartridges \
	test-1983-stubs test-1983-abi-clobber \
	test-openmsx-external-cartridges test-openmsx-external-arkano \
	test-openmsx-external-diagnostics test-1983-external-cartridges \
	test-1983-external-arkano test-1983-external-diagnostics \
	test-1983-external-diagnostics-screen3 check-bbcbasic \
	check-bbcbasic-artifact bbcbasic-payload nms8250-disk-rom \
	check-manifest check-release clean

all: $(MSX1_ROM)

nms8250-disk-rom: $(NMS8250_DISK_ROM)

$(BUILD_DIR):
	mkdir -p $@

$(LOGO_STAMP): $(LOGO_SOURCE) tools/png_to_screen2.py | $(BUILD_DIR)
	mkdir -p $(LOGO_DIR)
	$(PYTHON) tools/png_to_screen2.py $< $(LOGO_DIR)
	touch $@

$(ZX0_TOOL): $(ZX0_TOOL_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(HOST_CC) -O2 -std=c99 -Wall -Wextra -Itools/zx0 \
		-o $@ tools/zx0/zx0.c tools/zx0/optimize.c \
		tools/zx0/compress.c tools/zx0/memory.c

$(LOGO_DIR)/%.zx0: $(LOGO_STAMP) $(ZX0_TOOL)
	$(ZX0_TOOL) -f $(patsubst %.zx0,%.bin,$@) $@

bbcbasic-payload:
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR) --skip-artifact
	$(MAKE) -C $(BBC_BASIC_DIR) check
	$(MAKE) -C $(BBC_BASIC_DIR) msx-console \
		ZMAC="$(BBC_ZMAC)" LD80="$(BBC_LD80)"
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR) --require-artifact
	mkdir -p $(BBC_EMBED_DIR)
	cp $(BBC_BASIC_ROM) $(BBC_PAYLOAD_ROM)
	$(ZX0_TOOL) -f $(BBC_PAYLOAD_ROM) $(BBC_EMBEDDED_ROM)

$(MSX1_ROM): bbcbasic-payload $(SOURCES) $(LOGO_STAMP) \
	$(LOGO_COMPRESSED_ASSETS) | $(BUILD_DIR)
	$(RASM) $(firstword $(SOURCES)) -Isrc -I$(LOGO_DIR) -I$(BBC_EMBED_DIR) \
		-ob $@ -s -os $(MSX1_SYM)

$(MSX2_ROM): bbcbasic-payload $(SOURCES) $(LOGO_STAMP) \
	$(LOGO_COMPRESSED_ASSETS) | $(BUILD_DIR)
	$(RASM) $(firstword $(SOURCES)) -DMSX2=1 -Isrc -I$(LOGO_DIR) \
		-I$(BBC_EMBED_DIR) -ob $@ -s -os $(MSX2_SYM)

$(MSX2_SUB_ROM): src/main_msx2_sub.asm | $(BUILD_DIR)
	$(RASM) $< -ob $@ -s -os $(MSX2_SUB_SYM)

msx2-sub-rom: $(MSX2_SUB_ROM)

msx2-main-rom: $(MSX2_ROM)

RELEASE_VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null)
RELEASE_DIR := $(BUILD_DIR)/release/$(RELEASE_VERSION)

release: $(MSX1_ROM) $(MSX2_ROM) $(MSX2_SUB_ROM) $(NMS8250_DISK_ROM) \
		$(MSX1_SYM) $(MSX2_SYM) $(MSX2_SUB_SYM) $(NMS8250_DISK_ROM_SYM)
	$(PYTHON) tools/make_release_bundle.py \
		--build "$(BUILD_DIR)" --root "$(CURDIR)" \
		--output "$(RELEASE_DIR)" --version "$(RELEASE_VERSION)"

check-release: release
	$(PYTHON) tools/check_release_bundle.py \
		--bundle "$(RELEASE_DIR)" --root "$(CURDIR)" \
		--version "$(RELEASE_VERSION)"

$(DIAGNOSTIC_CART): tests/cartridges/primary_init.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DIAGNOSTIC_CART_SYM)

$(MENU_INPUT_CART): tests/cartridges/menu_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(MENU_INPUT_CART_SYM)

$(GRAPHICS_INPUT_CART): tests/cartridges/graphics_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(GRAPHICS_INPUT_CART_SYM)

$(CLS_INPUT_CART): tests/cartridges/cls_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(CLS_INPUT_CART_SYM)

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

$(DISK_DSKCHG_TEST_ROM): $(DISK_DSKCHG_TEST_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_DSKCHG_TEST_ROM) \
		-s -os $(DISK_DSKCHG_TEST_ROM_SYM)

$(DISK_DSKCHG_TEST_ROM_SYM): $(DISK_DSKCHG_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_DSKCHG_TEST_SOURCES)) -Isrc \
			-ob $(DISK_DSKCHG_TEST_ROM) -s -os $@; \
	fi

$(DISK_DSKCHG_NO_MEDIA_TEST_ROM): $(DISK_DSKCHG_NO_MEDIA_TEST_SOURCES) | \
		$(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_DSKCHG_NO_MEDIA_TEST_ROM) \
		-s -os $(DISK_DSKCHG_NO_MEDIA_TEST_ROM_SYM)

$(DISK_DSKCHG_NO_MEDIA_TEST_ROM_SYM): $(DISK_DSKCHG_NO_MEDIA_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_DSKCHG_NO_MEDIA_TEST_SOURCES)) -Isrc \
			-ob $(DISK_DSKCHG_NO_MEDIA_TEST_ROM) -s -os $@; \
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

$(DISK_FAULT_TEST_ROM): $(DISK_FAULT_TEST_SOURCES) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -Isrc -ob $(DISK_FAULT_TEST_ROM) \
		-s -os $(DISK_FAULT_TEST_ROM_SYM)

$(DISK_FAULT_TEST_ROM_SYM): $(DISK_FAULT_TEST_ROM)
	@if test ! -f "$@"; then \
		$(RASM) $(firstword $(DISK_FAULT_TEST_SOURCES)) -Isrc \
			-ob $(DISK_FAULT_TEST_ROM) -s -os $@; \
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

$(VALID_PAYLOAD_CART): tests/cartridges/payload_valid.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $(VALID_PAYLOAD_CART) -s -os $(VALID_PAYLOAD_CART_SYM)

$(VALID_PAYLOAD_CART_SYM): $(VALID_PAYLOAD_CART)
	@if test ! -f "$@"; then \
		$(RASM) tests/cartridges/payload_valid.asm \
			-ob $(VALID_PAYLOAD_CART) -s -os $@; \
	fi

$(MENU_DISK2_INPUT_CART): tests/cartridges/menu_disk2_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $(MENU_DISK2_INPUT_CART) -s -os $(MENU_DISK2_INPUT_CART_SYM)

$(MENU_DISK2_INPUT_CART_SYM): $(MENU_DISK2_INPUT_CART)
	@if test ! -f "$@"; then \
		$(RASM) tests/cartridges/menu_disk2_input.asm \
			-ob $(MENU_DISK2_INPUT_CART) -s -os $@; \
	fi

$(MENU_DISK3_INPUT_CART): tests/cartridges/menu_disk3_input.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $(MENU_DISK3_INPUT_CART) -s -os $(MENU_DISK3_INPUT_CART_SYM)

$(MENU_DISK3_INPUT_CART_SYM): $(MENU_DISK3_INPUT_CART)
	@if test ! -f "$@"; then \
		$(RASM) tests/cartridges/menu_disk3_input.asm \
			-ob $(MENU_DISK3_INPUT_CART) -s -os $@; \
	fi

$(DISK_PHYDIO_IMAGE): tools/make_test_disk.py | $(BUILD_DIR)
	$(PYTHON) $< $@

$(DISK_PARTIAL_IMAGE): tools/make_test_disk.py | $(BUILD_DIR)
	$(PYTHON) $< --one-side $@

$(DISK_BOOT_SECTOR_BIN): $(DISK_BOOT_SECTOR) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(DISK_BOOT_SECTOR_SYM)

$(DISK_BOOT_SECTOR_SYM): $(DISK_BOOT_SECTOR_BIN)
	@if test ! -f "$@"; then \
		$(RASM) $(DISK_BOOT_SECTOR) -ob $(DISK_BOOT_SECTOR_BIN) \
			-s -os $@; \
	fi

$(DISK_BOOT_IMAGE): tools/make_boot_disk.py $(DISK_BOOT_SECTOR_BIN)
	$(PYTHON) $< --boot-sector $(DISK_BOOT_SECTOR_BIN) $@

$(IDE_BOOT_SECTOR_BIN): $(IDE_BOOT_SECTOR) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(IDE_BOOT_SECTOR_SYM)

$(IDE_BOOT_SECTOR_SYM): $(IDE_BOOT_SECTOR_BIN)
	@if test ! -f "$@"; then \
		$(RASM) $(IDE_BOOT_SECTOR) -ob $(IDE_BOOT_SECTOR_BIN) \
			-s -os $@; \
	fi

$(IDE_BOOT_IMAGE): tools/make_ide_image.py $(IDE_BOOT_SECTOR_BIN)
	$(PYTHON) $< --boot-sector $(IDE_BOOT_SECTOR_BIN) $@

$(SD_BOOT_SECTOR_BIN): $(SD_BOOT_SECTOR) | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SD_BOOT_SECTOR_SYM)

$(SD_BOOT_SECTOR_SYM): $(SD_BOOT_SECTOR_BIN)
	@if test ! -f "$@"; then \
		$(RASM) $(SD_BOOT_SECTOR) -ob $(SD_BOOT_SECTOR_BIN) \
			-s -os $@; \
	fi

$(SD_BOOT_IMAGE): tools/make_ide_image.py $(SD_BOOT_SECTOR_BIN)
	$(PYTHON) $< --boot-sector $(SD_BOOT_SECTOR_BIN) $@

$(NEXTOR_IMAGE): $(NEXTOR_SYS) $(NEXTOR_COMMAND) | $(BUILD_DIR)
	mkdir -p $(@D)
	truncate -s 32M $@
	printf '32,,6,*\n' | sfdisk $@
	sfdisk --disk-id $@ 0x5241494e
	mkfs.fat -F 16 -i 5241494e --offset 32 -n NEXTOR $@
	mcopy -i "$@@@16384" "$(NEXTOR_SYS)" ::NEXTOR.SYS
	mcopy -i "$@@@16384" "$(NEXTOR_COMMAND)" ::COMMAND2.COM

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

test: $(MSX1_ROM) $(MSX2_ROM) $(MSX2_SUB_ROM) $(NMS8250_DISK_ROM) \
	$(DISK_BOOT_SECTOR_BIN) $(IDE_BOOT_SECTOR_BIN) $(SD_BOOT_SECTOR_BIN) \
	$(VALID_PAYLOAD_CART) release
	PYTHONDONTWRITEBYTECODE=1 RAINBIOS_MSX1_ROM=$(MSX1_ROM) \
	RAINBIOS_MSX2_ROM=$(MSX2_ROM) \
	RAINBIOS_MSX2_SUB_ROM=$(MSX2_SUB_ROM) \
	RAINBIOS_BBC_BASIC_ROM=$(BBC_PAYLOAD_ROM) \
	RAINBIOS_NMS8250_DISK_ROM=$(NMS8250_DISK_ROM) \
	RAINBIOS_DISK_BOOT_SECTOR=$(DISK_BOOT_SECTOR_BIN) \
	RAINBIOS_IDE_BOOT_SECTOR=$(IDE_BOOT_SECTOR_BIN) \
	RAINBIOS_SD_BOOT_SECTOR=$(SD_BOOT_SECTOR_BIN) \
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

$(OPENMSX_GEOBENCH_MACHINE): \
		tests/openmsx/RainBIOS_GeoBench.xml.in $(MSX1_ROM) $(CBIOS_SUB_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CBIOS_SUB_ROM@|$(abspath $(CBIOS_SUB_ROM))|' $< > $@

$(OPENMSX_MSX2_MACHINE): \
		tests/openmsx/RainBIOS_MSX2.xml.in $(MSX2_ROM) $(CBIOS_SUB_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX2_ROM))|' \
		-e 's|@CBIOS_SUB_ROM@|$(abspath $(CBIOS_SUB_ROM))|' $< > $@

$(OPENMSX_MSX2_SUBROM_MACHINE): \
		tests/openmsx/RainBIOS_MSX2_SUBROM.xml.in $(MSX2_ROM) \
		$(SUBROM_PROBE_ROM) $(SUBROM_PROBE_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX2_ROM))|' \
		-e 's|@SUBROM_PROBE_ROM@|$(abspath $(SUBROM_PROBE_ROM))|' \
		-e 's|@SUBROM_PROBE_CART@|$(abspath $(SUBROM_PROBE_CART))|' $< > $@

$(OPENMSX_MSX2_SERVICES_MACHINE): \
		tests/openmsx/RainBIOS_MSX2_SERVICES.xml.in $(MSX2_ROM) \
		$(MSX2_SUB_ROM) $(SUBROM_SERVICES_PROBE_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX2_ROM))|' \
		-e 's|@MSX2_SUB_ROM@|$(abspath $(MSX2_SUB_ROM))|' \
		-e 's|@SUBROM_SERVICES_PROBE_CART@|$(abspath $(SUBROM_SERVICES_PROBE_CART))|' \
		$< > $@

$(OPENMSX_MSX2_CMDCLOCK_MACHINE): \
		tests/openmsx/RainBIOS_MSX2_CMDCLOCK.xml.in $(MSX2_ROM) \
		$(MSX2_SUB_ROM) $(SUBROM_CMDCLOCK_PROBE_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX2_ROM))|' \
		-e 's|@MSX2_SUB_ROM@|$(abspath $(MSX2_SUB_ROM))|' \
		-e 's|@SUBROM_CMDCLOCK_PROBE_CART@|$(abspath $(SUBROM_CMDCLOCK_PROBE_CART))|' \
		$< > $@

$(OPENMSX_MSX2_64K_MACHINE): \
		tests/openmsx/RainBIOS_MSX2_64K.xml.in $(MSX2_ROM) \
		$(MSX2_SUB_ROM) $(SUBROM_64K_PROBE_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX2_ROM))|' \
		-e 's|@MSX2_SUB_ROM@|$(abspath $(MSX2_SUB_ROM))|' \
		-e 's|@SUBROM_64K_PROBE_CART@|$(abspath $(SUBROM_64K_PROBE_CART))|' \
		$< > $@

$(SUBROM_PROBE_ROM): tests/subroms/subrom_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_PROBE_ROM:.rom=.sym)

$(SUBROM_PROBE_CART): tests/cartridges/subrom_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_PROBE_CART:.rom=.sym)

SUBROM_SERVICES_PROBE_CART := \
	$(BUILD_DIR)/cartridges/subrom_services_probe.rom
SUBROM_SERVICES_PROBE_SYM := \
	$(BUILD_DIR)/cartridges/subrom_services_probe.sym

$(SUBROM_SERVICES_PROBE_CART): \
		tests/cartridges/subrom_services_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_SERVICES_PROBE_CART:.rom=.sym)

$(SUBROM_CMDCLOCK_PROBE_CART): \
		tests/cartridges/subrom_cmdclock_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_CMDCLOCK_PROBE_CART:.rom=.sym)

SUBROM_64K_PROBE_CART := \
	$(BUILD_DIR)/cartridges/subrom_64k_probe.rom

$(SUBROM_64K_PROBE_CART): \
		tests/cartridges/subrom_64k_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_64K_PROBE_CART:.rom=.sym)

STUB_PROBE_CART := $(BUILD_DIR)/cartridges/stub_probe.rom

$(STUB_PROBE_CART): tests/cartridges/stub_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(STUB_PROBE_CART:.rom=.sym)

ABI_CLOBBER_PROBE_CART := $(BUILD_DIR)/cartridges/abi_clobber_probe.rom

$(ABI_CLOBBER_PROBE_CART): tests/cartridges/abi_clobber_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(ABI_CLOBBER_PROBE_CART:.rom=.sym)

SUBROM_CMDCLOCK_PROBE_CART := \
	$(BUILD_DIR)/cartridges/subrom_cmdclock_probe.rom
SUBROM_CMDCLOCK_PROBE_SYM := \
	$(BUILD_DIR)/cartridges/subrom_cmdclock_probe.sym

$(SUBROM_CMDCLOCK_PROBE_CART): \
		tests/cartridges/subrom_cmdclock_probe.asm | $(BUILD_DIR)
	mkdir -p $(@D)
	$(RASM) $< -ob $@ -s -os $(SUBROM_CMDCLOCK_PROBE_SYM)

$(OPENMSX_SUNRISE_SYSTEM_ROM): $(SUNRISE_ROM)
	mkdir -p $(@D)
	cp "$<" "$@"

$(OPENMSX_GEOBENCH_IMAGE): $(GEOBENCH_IMAGE)
	mkdir -p $(@D)
	cp "$<" "$@"

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

$(OPENMSX_MAPPER_MACHINE): \
		tests/openmsx/RainBIOS_M1_MAPPER.xml.in $(MSX1_ROM)
	mkdir -p $(@D)
	sed 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' $< > $@

test-openmsx-mapper: $(OPENMSX_MAPPER_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_MAPPER \
		-command "set mapper_output {$(abspath $(OPENMSX_MAPPER_REPORT))}" \
		-script "$(abspath tests/openmsx/mapper_probe.tcl)"
	$(PYTHON) tools/check_mapper_probe.py $(OPENMSX_MAPPER_REPORT)

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

test-openmsx-cursor: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set cursor_output {$(abspath $(OPENMSX_CURSOR_REPORT))}" \
		-script "$(abspath tests/openmsx/cursor_move_probe.tcl)"
	$(PYTHON) tools/check_cursor_move_probe.py $(OPENMSX_CURSOR_REPORT)

test-openmsx-vram: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set vram_output {$(abspath $(OPENMSX_VRAM_REPORT))}" \
		-script "$(abspath tests/openmsx/vram_probe.tcl)"
	$(PYTHON) tools/check_vram_probe.py $(OPENMSX_VRAM_REPORT)

test-openmsx-screen-modes: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set screend_output {$(abspath $(OPENMSX_SCREENMODES_REPORT))}" \
		-script "$(abspath tests/openmsx/screen_modes_probe.tcl)"
	$(PYTHON) tools/check_screen_modes_probe.py $(OPENMSX_SCREENMODES_REPORT)

test-openmsx-sprites: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set sprite_output {$(abspath $(OPENMSX_SPRITE_REPORT))}" \
		-script "$(abspath tests/openmsx/sprite_probe.tcl)"
	$(PYTHON) tools/check_sprite_probe.py $(OPENMSX_SPRITE_REPORT)

test-openmsx-grpprt: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set grpprt_output {$(abspath $(OPENMSX_GRPPRT_REPORT))}" \
		-script "$(abspath tests/openmsx/grpprt_probe.tcl)"
	$(PYTHON) tools/check_grpprt_probe.py $(OPENMSX_GRPPRT_REPORT)

test-openmsx-textctl: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set textctl_output {$(abspath $(OPENMSX_TEXTCTL_REPORT))}" \
		-script "$(abspath tests/openmsx/textctl_probe.tcl)"
	$(PYTHON) tools/check_textctl_probe.py $(OPENMSX_TEXTCTL_REPORT)

test-openmsx-vdpstate: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set vdpstate_output {$(abspath $(OPENMSX_VDPSTATE_REPORT))}" \
		-script "$(abspath tests/openmsx/vdpstate_probe.tcl)"
	$(PYTHON) tools/check_vdpstate_probe.py $(OPENMSX_VDPSTATE_REPORT)

test-openmsx-color: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set color_output {$(abspath $(OPENMSX_COLOR_REPORT))}" \
		-script "$(abspath tests/openmsx/color_probe.tcl)"
	$(PYTHON) tools/check_color_probe.py $(OPENMSX_COLOR_REPORT)

test-openmsx-screen3: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set s3_output {$(abspath $(OPENMSX_SCREEN3_REPORT))}" \
		-script "$(abspath tests/openmsx/screen3_probe.tcl)"
	$(PYTHON) tools/check_screen3_probe.py $(OPENMSX_SCREEN3_REPORT)










test-openmsx-controller: $(OPENMSX_SHARE)/machines/RainBIOS_M1_RAM3.xml
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_RAM3 \
		-command "set controller_output {$(abspath $(OPENMSX_CONTROLLER_REPORT))}" \
		-script "$(abspath tests/openmsx/controller_probe.tcl)"
	$(PYTHON) tools/check_controller_probe.py $(OPENMSX_CONTROLLER_REPORT)

test-openmsx-geobench-sunrise: $(OPENMSX_GEOBENCH_MACHINE) \
		$(OPENMSX_SUNRISE_SYSTEM_ROM) $(OPENMSX_GEOBENCH_IMAGE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	cp "$(GEOBENCH_IMAGE)" "$(OPENMSX_GEOBENCH_IMAGE)"
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_GeoBench -ext SunriseIDE_Nextor \
		-hda "$(abspath $(OPENMSX_GEOBENCH_IMAGE))" \
		-command "set geobench_output {$(abspath $(OPENMSX_GEOBENCH_REPORT))}; set geobench_screenshot {$(abspath $(OPENMSX_GEOBENCH_SCREEN))}; set geobench_capture_time $(OPENMSX_GEOBENCH_CAPTURE_TIME)" \
		-script "$(abspath tests/openmsx/geobench_probe.tcl)"
	cmp "$(GEOBENCH_IMAGE)" "$(OPENMSX_GEOBENCH_IMAGE)"
	$(PYTHON) tools/check_geobench.py --boot-state $(OPENMSX_GEOBENCH_REPORT) \
		$(OPENMSX_GEOBENCH_SCREEN)

test-openmsx-msx2: $(OPENMSX_MSX2_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX2 \
		-command "set msx2_output {$(abspath $(OPENMSX_MSX2_REPORT))}; set msx2_screenshot {$(abspath $(OPENMSX_MSX2_SCREEN))}" \
		-script "$(abspath tests/openmsx/msx2_probe.tcl)"
	$(PYTHON) tools/check_msx2_probe.py $(OPENMSX_MSX2_REPORT) \
		$(OPENMSX_MSX2_SCREEN)

test-openmsx-msx2-subrom: $(OPENMSX_MSX2_SUBROM_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX2_SUBROM \
		-command "set msx2_subrom_output {$(abspath $(OPENMSX_MSX2_SUBROM_REPORT))}; set msx2_subrom_screenshot {$(abspath $(OPENMSX_MSX2_SUBROM_SCREEN))}" \
		-script "$(abspath tests/openmsx/msx2_subrom_probe.tcl)"
	$(PYTHON) tools/check_msx2_subrom_probe.py \
		$(OPENMSX_MSX2_SUBROM_REPORT)

test-openmsx-msx2-services: $(OPENMSX_MSX2_SERVICES_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX2_SERVICES \
		-command "set msx2_services_output {$(abspath $(OPENMSX_MSX2_SERVICES_REPORT))}; set msx2_services_screenshot {$(abspath $(OPENMSX_MSX2_SERVICES_SCREEN))}" \
		-script "$(abspath tests/openmsx/msx2_services_probe.tcl)"
	$(PYTHON) tools/check_msx2_services_probe.py \
		$(OPENMSX_MSX2_SERVICES_REPORT)

test-openmsx-msx2-cmdclock: $(OPENMSX_MSX2_CMDCLOCK_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX2_CMDCLOCK \
		-command "set msx2_cmdclock_output {$(abspath $(OPENMSX_MSX2_CMDCLOCK_REPORT))}; set msx2_cmdclock_screenshot {$(abspath $(OPENMSX_MSX2_CMDCLOCK_SCREEN))}" \
		-script "$(abspath tests/openmsx/msx2_cmdclock_probe.tcl)"
	$(PYTHON) tools/check_msx2_cmdclock_probe.py \
		$(OPENMSX_MSX2_CMDCLOCK_REPORT)

test-openmsx-msx2-64k: $(OPENMSX_MSX2_64K_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX2_64K \
		-command "set msx2_64k_output {$(abspath $(OPENMSX_MSX2_64K_REPORT))}; set msx2_64k_screenshot {$(abspath $(OPENMSX_MSX2_64K_SCREEN))}" \
		-script "$(abspath tests/openmsx/msx2_64k_probe.tcl)"
	$(PYTHON) tools/check_msx2_64k_probe.py \
		$(OPENMSX_MSX2_64K_REPORT)

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

$(OPENMSX_CLS_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(CLS_INPUT_CART)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(CLS_INPUT_CART))|' \
		-e 's|RainBIOS_M1_CARTRIDGE|RainBIOS_M1_CLS_CARTRIDGE|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-MSX1-M1-CLS-CARTRIDGE|' \
		$< > $@

test-openmsx-cls: $(OPENMSX_CLS_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_CLS_CARTRIDGE \
		-command "set cls_output {$(abspath $(OPENMSX_CLS_REPORT))}" \
		-script "$(abspath tests/openmsx/cls_probe.tcl)"
	$(PYTHON) tools/check_cls_probe.py $(OPENMSX_CLS_REPORT)

test-openmsx-cartridge: $(OPENMSX_CART_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_M1_CARTRIDGE \
		-command "set cartridge_output {$(abspath $(OPENMSX_CART_REPORT))}; set cartridge_screenshot {$(abspath $(OPENMSX_CART_SCREEN))}" \
		-script "$(abspath tests/openmsx/cartridge_probe.tcl)"
	$(PYTHON) tools/check_cartridge_probe.py $(OPENMSX_CART_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py $(OPENMSX_CART_SCREEN)

$(OPENMSX_FAULT_MACHINE): \
		tests/openmsx/RainBIOS_M1_CARTRIDGE.xml.in \
		$(MSX1_ROM) $(DISK_FAULT_TEST_ROM)
	mkdir -p $(@D)
	sed -e 's|@RAINBIOS_ROM@|$(abspath $(MSX1_ROM))|' \
		-e 's|@CARTRIDGE_ROM@|$(abspath $(DISK_FAULT_TEST_ROM))|' \
		-e 's|RainBIOS_M1_CARTRIDGE|RainBIOS_M1_DISK_FAULT|' \
		-e 's|RainBIOS-MSX1-M1-CARTRIDGE|RainBIOS-MSX1-M1-DISK-FAULT|' \
		-e 's|Cartridge probe fixture|Controller fault-injection fixture|' \
		$< > $@

test-openmsx-disk-fault: $(OPENMSX_FAULT_MACHINE) $(DISK_FAULT_TEST_ROM_SYM)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	$(PYTHON) tools/run_openmsx_disk_fault.py \
		--openmsx "$(OPENMSX)" \
		--home "$(abspath $(OPENMSX_HOME))" \
		--user-data "$(abspath $(OPENMSX_SHARE))" \
		--machine RainBIOS_M1_DISK_FAULT \
		--script tests/openmsx/disk_fault_probe.tcl \
		--symbols "$(DISK_FAULT_TEST_ROM_SYM)" \
		--report "$(abspath $(OPENMSX_FAULT_REPORT))"

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

test-openmsx-embedded-basic: $(OPENMSX_MACHINE)
	mkdir -p $(OPENMSX_HOME) $(OPENMSX_M1_REPORT_DIR)
	OPENMSX_HOME=$(abspath $(OPENMSX_HOME)) \
	OPENMSX_USER_DATA=$(abspath $(OPENMSX_SHARE)) \
	$(OPENMSX) -machine RainBIOS_MSX1 \
		-command "set embedded_basic_output {$(abspath $(OPENMSX_EMBEDDED_BASIC_REPORT))}; set embedded_basic_screenshot {$(abspath $(OPENMSX_EMBEDDED_BASIC_SCREEN))}" \
		-script "$(abspath tests/openmsx/embedded_basic_probe.tcl)"
	$(PYTHON) tools/check_embedded_basic_probe.py \
		$(OPENMSX_EMBEDDED_BASIC_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py --min-colors 2 \
		$(OPENMSX_EMBEDDED_BASIC_SCREEN)

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
		--vdp-r0 02 --vdp-r1 E2 $(OPENMSX_EXTERNAL_ARKANO_REPORT)
	$(PYTHON) tools/check_boot_screenshot.py \
		--min-colors 8 --foreground-box 160,70,225,200 \
		$(OPENMSX_EXTERNAL_ARKANO_SCREEN)

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

test-1983-msx2: $(MSX2_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_msx2.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX2_ROM)" --subrom "$(CBIOS_SUB_ROM)" \
		--screenshot "$(EMULATOR_1983_MSX2_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_MSX2_SCREEN)

test-1983-msx2-subrom: $(MSX2_ROM) $(SUBROM_PROBE_ROM) $(SUBROM_PROBE_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_msx2_subrom.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX2_ROM)" --subrom "$(SUBROM_PROBE_ROM)" \
		--cartridge "$(SUBROM_PROBE_CART)"

test-1983-msx2-subrom-services: \
		$(MSX2_ROM) $(MSX2_SUB_ROM) $(SUBROM_SERVICES_PROBE_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_msx2_subrom_services.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX2_ROM)" --subrom "$(MSX2_SUB_ROM)" \
		--cartridge "$(SUBROM_SERVICES_PROBE_CART)"

test-1983-msx2-subrom-cmdclock: \
		$(MSX2_ROM) $(MSX2_SUB_ROM) $(SUBROM_CMDCLOCK_PROBE_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_msx2_cmdclock.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX2_ROM)" --subrom "$(MSX2_SUB_ROM)" \
		--cartridge "$(SUBROM_CMDCLOCK_PROBE_CART)"

test-1983-cartridge: $(MSX1_ROM) $(DIAGNOSTIC_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(DIAGNOSTIC_CART)" \
		--screenshot "$(EMULATOR_1983_CART_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_CART_SCREEN)

test-1983-stubs: $(MSX1_ROM) $(STUB_PROBE_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_stub_probe.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(STUB_PROBE_CART)"

test-1983-abi-clobber: $(MSX1_ROM) $(ABI_CLOBBER_PROBE_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_abi_clobber_probe.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(ABI_CLOBBER_PROBE_CART)"

test-1983-bbcbasic: $(MSX1_ROM) $(BBC_BASIC_ROM) $(MENU_INPUT_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_bbcbasic.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(BBC_BASIC_ROM)" \
		--input-cartridge "$(MENU_INPUT_CART)" \
		--screenshot "$(EMULATOR_1983_BBC_BASIC_SCREEN)"
	$(PYTHON) tools/check_bbcbasic_screenshot.py \
		$(EMULATOR_1983_BBC_BASIC_SCREEN)

test-1983-embedded-basic: $(MSX1_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_embedded_basic.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" \
		--screenshot "$(EMULATOR_1983_EMBEDDED_BASIC_SCREEN)"
	$(PYTHON) tools/check_bbcbasic_screenshot.py \
		$(EMULATOR_1983_EMBEDDED_BASIC_SCREEN)

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

test-1983-disk-boot-production: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(DISK_BOOT_SECTOR_SYM) $(DISK_BOOT_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--symbols "$(DISK_BOOT_SECTOR_SYM)" \
		--expected-pass-label disk_boot_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_BOOT_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_DISK_BOOT_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_BOOT_SCREEN)

test-1983-disk-boot-fallback: $(MSX1_ROM) $(NMS8250_DISK_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--expect-fallback --expected-slot F0 --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_DISK_BOOT_FALLBACK_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DISK_BOOT_FALLBACK_SCREEN)

test-1983-disk-boot-menu: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(VALID_PAYLOAD_CART) $(MENU_DISK2_INPUT_CART) \
		$(DISK_BOOT_SECTOR_SYM) $(DISK_BOOT_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--payload "$(VALID_PAYLOAD_CART)" \
		--input-cartridge "$(MENU_DISK2_INPUT_CART)" \
		--symbols "$(DISK_BOOT_SECTOR_SYM)" \
		--expected-pass-label disk_boot_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_BOOT_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_DISK_BOOT_MENU_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 $(EMULATOR_1983_DISK_BOOT_MENU_SCREEN)

test-1983-disk-menu-stub: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) $(MENU_DISK3_INPUT_CART)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--input-cartridge "$(MENU_DISK3_INPUT_CART)" \
		--expect-fallback --expected-slot F0 --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_DISK_MENU_STUB_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 $(EMULATOR_1983_DISK_MENU_STUB_SCREEN)

test-1983-ide-boot: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(IDE_BOOT_SECTOR_SYM) $(IDE_BOOT_IMAGE)
	test -f "$(SUNRISE_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_ide_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sunrise-rom "$(SUNRISE_ROM)" \
		--paste-at 180 --paste-text " 3" \
		--symbols "$(IDE_BOOT_SECTOR_SYM)" \
		--expected-pass-label ide_boot_pass \
		--expected-slot F8 --exit-after 1200 \
		--ide "$(IDE_BOOT_IMAGE)" \
		--screenshot "$(EMULATOR_1983_IDE_BOOT_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 --foreground-box 64,224,576,240 \
		$(EMULATOR_1983_IDE_BOOT_SCREEN)

test-1983-ide-menu: $(MSX1_ROM) $(NMS8250_DISK_ROM)
	test -f "$(SUNRISE_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_ide_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sunrise-rom "$(SUNRISE_ROM)" \
		--paste-at 180 --paste-text " 3" \
		--expect-fallback --expected-slot FC --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_IDE_MENU_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 --foreground-box 64,224,576,240 \
		$(EMULATOR_1983_IDE_MENU_SCREEN)

test-1983-sd-boot: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(SD_BOOT_SECTOR_SYM) $(SD_BOOT_IMAGE)
	test -f "$(SD_MAPPER_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_ide_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--paste-at 180 --paste-text " 3" \
		--symbols "$(SD_BOOT_SECTOR_SYM)" \
		--expected-pass-label sd_boot_pass \
		--expected-slot A8 --exit-after 1200 \
		--sd-a "$(SD_BOOT_IMAGE)" --sd-mode read-only \
		--screenshot "$(EMULATOR_1983_SD_BOOT_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 --foreground-box 64,224,576,240 \
		$(EMULATOR_1983_SD_BOOT_SCREEN)

test-1983-sd-menu: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM)
	test -f "$(SD_MAPPER_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_ide_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--paste-at 180 --paste-text " 3" \
		--expect-fallback --expected-slot A0 --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_SD_MENU_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 --foreground-box 64,224,576,240 \
		$(EMULATOR_1983_SD_MENU_SCREEN)

test-1983-sd-empty-floppy: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) \
		$(DISK_BOOT_SECTOR_SYM) $(DISK_BOOT_IMAGE)
	test -f "$(SD_MAPPER_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_boot.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--symbols "$(DISK_BOOT_SECTOR_SYM)" \
		--expected-pass-label disk_boot_pass \
		--expected-slot A0 --exit-after 1200 \
		--disk-a "$(DISK_BOOT_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_SD_EMPTY_FLOPPY_SCREEN)"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 --min-colors 2 \
		$(EMULATOR_1983_SD_EMPTY_FLOPPY_SCREEN)

test-1983-sd-empty-sunrise: $(MSX1_ROM) $(NEXTOR_IMAGE)
	test -f "$(SUNRISE_ROM)"
	test -f "$(SD_MAPPER_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sunrise-rom "$(SUNRISE_ROM)" \
		--ide "$(NEXTOR_IMAGE)" --ide-mode read-only \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" --sd-mode read-only \
		--headless --unthrottled --exit-after 2500 \
		--screenshot "$(EMULATOR_1983_SD_EMPTY_SUNRISE_SCREEN)"
	$(PYTHON) tools/check_nextor_screenshot.py --mixed-storage \
		$(EMULATOR_1983_SD_EMPTY_SUNRISE_SCREEN)

test-1983-nextor: $(MSX1_ROM) $(NEXTOR_IMAGE)
	test -f "$(SUNRISE_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sunrise-rom "$(SUNRISE_ROM)" \
		--ide "$(NEXTOR_IMAGE)" --ide-mode read-only \
		--headless --unthrottled --exit-after 2500 \
		--screenshot "$(EMULATOR_1983_NEXTOR_SCREEN)"
	$(PYTHON) tools/check_nextor_screenshot.py \
		$(EMULATOR_1983_NEXTOR_SCREEN)

test-1983-nextor-sd: $(MSX1_ROM) $(NEXTOR_IMAGE)
	test -f "$(SD_MAPPER_ROM)"
	mkdir -p $(EMULATOR_1983_DIR)
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--sd-a "$(NEXTOR_IMAGE)" --sd-mode read-only \
		--headless --unthrottled --exit-after 2500 \
		--screenshot "$(EMULATOR_1983_NEXTOR_SD_A_SCREEN)"
	$(PYTHON) tools/check_nextor_screenshot.py --sd-card A \
		$(EMULATOR_1983_NEXTOR_SD_A_SCREEN)
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--sd-b "$(NEXTOR_IMAGE)" --sd-mode read-only \
		--headless --unthrottled --exit-after 2500 \
		--screenshot "$(EMULATOR_1983_NEXTOR_SD_B_SCREEN)"
	$(PYTHON) tools/check_nextor_screenshot.py --sd-card B \
		$(EMULATOR_1983_NEXTOR_SD_B_SCREEN)
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--sd-a "$(NEXTOR_IMAGE)" --sd-b "$(NEXTOR_IMAGE)" \
		--sd-mode read-only --paste-at 180 --paste-text "B" \
		--headless --unthrottled --exit-after 2500 \
		--screenshot "$(EMULATOR_1983_NEXTOR_SD_DUAL_SCREEN)"
	$(PYTHON) tools/check_nextor_screenshot.py --sd-card B --sd-dual \
		$(EMULATOR_1983_NEXTOR_SD_DUAL_SCREEN)

test-1983-geobench-sunrise: $(MSX1_ROM)
	test -f "$(CBIOS_SUB_ROM)"
	test -f "$(SUNRISE_ROM)"
	test -f "$(GEOBENCH_IMAGE)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_geobench.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --subrom "$(CBIOS_SUB_ROM)" \
		--sunrise-rom "$(SUNRISE_ROM)" --image "$(GEOBENCH_IMAGE)" \
		--screenshot "$(EMULATOR_1983_GEOBENCH_SUNRISE_SCREEN)"

test-1983-geobench-sd: $(MSX1_ROM)
	test -f "$(CBIOS_SUB_ROM)"
	test -f "$(SD_MAPPER_ROM)"
	test -f "$(GEOBENCH_IMAGE)"
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_geobench.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --subrom "$(CBIOS_SUB_ROM)" \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" --image "$(GEOBENCH_IMAGE)" \
		--screenshot "$(EMULATOR_1983_GEOBENCH_SD_SCREEN)"

run-1983-ide-boot: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) $(IDE_BOOT_IMAGE)
	test -f "$(SUNRISE_ROM)"
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sunrise-rom "$(SUNRISE_ROM)" \
		--ide "$(IDE_BOOT_IMAGE)" --ide-mode read-only --scale 2

run-1983-sd-boot: \
		$(MSX1_ROM) $(NMS8250_DISK_ROM) $(SD_BOOT_IMAGE)
	test -f "$(SD_MAPPER_ROM)"
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(NMS8250_DISK_ROM)" \
		--sd-mapper-rom "$(SD_MAPPER_ROM)" \
		--sd-a "$(SD_BOOT_IMAGE)" --sd-mode read-only --scale 2

run-1983-nextor: $(MSX1_ROM) $(NEXTOR_IMAGE)
	test -f "$(SUNRISE_ROM)"
	"$(EMULATOR_1983)" --config /dev/null --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "" --sunrise-rom "$(SUNRISE_ROM)" \
		--ide "$(NEXTOR_IMAGE)" --ide-mode read-only --scale 2

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

test-1983-disk-dskchg-getdpb: $(MSX1_ROM) $(DISK_DSKCHG_TEST_ROM) \
		$(DISK_DSKCHG_TEST_ROM_SYM) $(DISK_PHYDIO_IMAGE)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_DSKCHG_TEST_ROM)" \
		--symbols "$(DISK_DSKCHG_TEST_ROM_SYM)" \
		--expected-pass-label disk_dskchg_getdpb_pass \
		--expected-slot FC --exit-after 1200 \
		--disk-a "$(DISK_PHYDIO_IMAGE)" --floppy-mode read-only \
		--screenshot "$(EMULATOR_1983_DIR)/disk-dskchg-getdpb.ppm"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DIR)/disk-dskchg-getdpb.ppm

test-1983-disk-dskchg-no-media: $(MSX1_ROM) \
		$(DISK_DSKCHG_NO_MEDIA_TEST_ROM) \
		$(DISK_DSKCHG_NO_MEDIA_TEST_ROM_SYM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_disk_baseline.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--model nms8250 --region pal --bios "$(MSX1_ROM)" \
		--disk-rom "$(DISK_DSKCHG_NO_MEDIA_TEST_ROM)" \
		--symbols "$(DISK_DSKCHG_NO_MEDIA_TEST_ROM_SYM)" \
		--expected-pass-label disk_dskchg_no_media_pass \
		--expected-slot FC --exit-after 1200 \
		--screenshot "$(EMULATOR_1983_DIR)/disk-dskchg-no-media.ppm"
	$(PYTHON) tools/check_boot_screenshot.py \
		--size 640x480 $(EMULATOR_1983_DIR)/disk-dskchg-no-media.ppm

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
		--exit-after 1300 --expected-slot D4 \
		--expected-vdp-r0 02 --expected-vdp-r1 E2
	$(PYTHON) tools/check_boot_screenshot.py --min-colors 8 \
		--foreground-box 320,140,450,400 \
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

test-1983-external-diagnostics-screen3: $(MSX1_ROM) $(MSX_DIAGNOSTICS_ROM)
	mkdir -p $(EMULATOR_1983_DIR)
	$(PYTHON) tools/run_1983_cartridge.py \
		--emulator "$(EMULATOR_1983)" --models "$(MODELS_1983)" \
		--bios "$(MSX1_ROM)" --cartridge "$(MSX_DIAGNOSTICS_ROM)" \
		--screenshot "$(EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN3_SCREEN)" \
		--exit-after 4500 --expected-slot D4 \
		--expected-vdp-r0 00 --expected-vdp-r1 E8 \
		--paste-text "4 " --paste-at 600 --paste-repeat 450
	$(PYTHON) tools/check_boot_screenshot.py --min-colors 2 \
		--size 640x480 $(EMULATOR_1983_EXTERNAL_DIAGNOSTICS_SCREEN3_SCREEN)

test-1983-external-cartridges: test-1983-external-arkano \
	test-1983-external-diagnostics test-1983-external-diagnostics-screen3

test-external-cartridges: test-openmsx-external-cartridges \
	test-1983-external-cartridges

check-bbcbasic:
	$(PYTHON) tools/check_bbcbasic_dependency.py \
		--repository $(BBC_BASIC_DIR)
	$(MAKE) -C $(BBC_BASIC_DIR) check

check-bbcbasic-artifact: bbcbasic-payload

check-manifest: $(MSX1_ROM) $(MSX2_ROM) $(MSX2_SUB_ROM) bbcbasic-payload
	PYTHONDONTWRITEBYTECODE=1 \
	$(PYTHON) -m unittest tests.test_component_manifest -v

clean:
	rm -rf $(BUILD_DIR)
