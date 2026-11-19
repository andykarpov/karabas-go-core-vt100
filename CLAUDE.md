# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A VT100 terminal core for the Karabas Go, Mini and Mini G boards: Xilinx Spartan-6 XC6SLX25, ISE 14.7 (XST). The terminal is the VT100 of Sytse van Slooten's PDP2011 (`rtl/vt100/`, `vt100_top.vhd`; his license allows personal, non-commercial use only and the copyright notice must stay unchanged). The repo itself is MIT (`LICENSE`, Andy Karpov 2024).

The serial line of the terminal is the core serial port of the board (CDC 1, `/dev/serial/by-id/usb-Karabas_Go_*-if02`; CDC 0 `-if00` has only the log and `AT+KARABAS=` since fw 2026-11-19): the MCU forwards the bytes of the PC with `CMD_UART` (FC) and `rtl/mcu/mcu_uart_bridge.v` (a fifo) feeds them to the VT100 and sends its output back. On a Linux host a getty on that port (`agetty ... -if02 vt100`) gives a login prompt (`README.md`).

The repo has no git remote (local only). The core is not converted to karabas-go-modules: it has no `modules/` submodule and carries its own `rtl/mcu/mcu.vhd`, OSD and HDMI.

## Layout

- `rtl/karabas_go_top.v` (VGA, the FT812 pins parked), `rtl/karabas_mini_top.v`, `rtl/karabas_minig_top.v` (HDMI): the board glue around `rtl/vt_top.v`.
- `rtl/vt_top.v`: the PLL (`ipcore_dir/pll`: 10 MHz VT100, 50 MHz system), `mcu`, `overlay` (OSD), `vt100_top`, `usb_ps2_convertor` (USB keyboard scancodes to a PS/2 stream for the VT100), `mcu_uart_bridge`, `soft_switches` (reset). The beeper goes to both audio channels.
- `rtl/vt100`: the PDP2011 sources the terminal needs. `rtl/hdmi`, `rtl/zhdmi`, `rtl/dac`, `rtl/adc`, `rtl/uart`, `rtl/fifo`, `rtl/ram`, `rtl/osd`, `rtl/spi`.
- `ipcore_dir`: Coregen `pll`, `osd_vram`, `rom_font`.

## Build

- ISE GUI projects at the top: `karabas-go.xise` (top `karabas_go_top`, `karabas_go.ucf`), `karabas-mini.xise` (`karabas_mini_top`, `karabas_mini.ucf`, `rtl/dac/dac.vhd`), `karabas-minig.xise` (`karabas_minig_top`, `karabas_minig.ucf`, `rtl/dac/pcm5102.v`). Their working directory is `build/`, where the ISE outputs and the `.bin` files end up. There is no Makefile.
- `build/karabas_go_top.bin`, `karabas_mini_top.bin`, `karabas_minig_top.bin` are committed; the other files in `build/` are ignored.
- `mkcore.sh` packs them: it runs `make_core.py` from `build/` with `core.json` (Go), `core_mini.json`, `core_minig.json` and writes `vt100.kg1` / `kg2` / `kg3` at the repo root (committed). `make_core.py` is a symlink to `../karabas-go-tools/make_core/make_core.py` (the tools repo next to this one) and is listed in `.gitignore`.
- The three json files differ only in `bitstream`; set the same `build` in all of them.

## MCU link and core file

- `rtl/mcu/mcu.vhd` is an old local copy: classic 3-byte frames only, no burst receiver and no `CMD_CAPS` answer (the firmware then stays on classic frames). It gives the keyboard scancodes, the buttons, the USB uart, the soft switch and OSD commands, `HWID` and `DVI_ONLY`.
- Core file: `type: osd`, `eeprom_bank` 255 (none), no ROMs, no file items. The `osd` items are two triggers, Reset (`Ctrl+Alt+Del`, also board button 1 through `hw_btn[1]`) and Global Reset (`Ctrl+Alt+Bkspace`).

## Memory

The Claude Code memory of this repo is shared with all karabas-go repos: `~/.claude/projects/<this project>/memory` is a symlink to `../karabas-go-notes` (private repo `andykarpov/karabas-go-notes`, `link.sh` there makes the links). Its `MEMORY.md` is split by repo; commit and push it after every memory change.
