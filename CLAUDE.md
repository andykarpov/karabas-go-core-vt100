# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A VT100 terminal core for the Karabas Go, Mini and Mini G boards: Xilinx Spartan-6 XC6SLX25, ISE 14.7 (XST). The terminal is the VT100 of Sytse van Slooten's PDP2011 (`src/rtl/vt100/`: a PDP-11 running the vt10x firmware, `vt100_top.vhd`; his license allows personal, non-commercial use only and the copyright notice must stay unchanged). The RTL of the terminal is the one of core-rc2014 (the tsybulin / karabas-go-core-pdp2026 version with the karabas fixes, below) plus the half intensity output. The repo itself is MIT (`LICENSE`, Andy Karpov 2024). Public repo `andykarpov/karabas-go-core-vt100` since 2026-11-19.

The serial line of the terminal is the core serial port of the board: kg_mcu2 port 0 = CDC 1 of the firmware (Linux `/dev/serial/by-id/usb-Karabas_Go_*-if02`, "Karabas core serial"; or a USB-UART adapter on the USB host). CDC 0 `-if00` has only the log and `AT+KARABAS=` (firmware 26111914 and newer). On a Linux host a getty on `-if02` gives a login prompt (`README.md`).

## Rules of the core

The rules of the other karabas-go cores apply: standard video timing with syncs always present, `FT_CLK_OUT` about 8 MHz on Mini / Mini G, Go `FDC_*` outputs 0 when unused, Mini / Mini G drive T3 (`FLASH_CS_N`) = 0, OSD switch index = item position unless `"index"`, Verilog-2001 for XST, VHDL-93 for XST, imported code marked `karabas:`, builds through `src/Makefile`.

- **Ask the user before every check on the board** (and the HDMI capture). Ask before a firmware flash.
- Heavy builds: Mini G only while working on one feature, all boards for a release; map with cost table 2 first.

## Layout

- `modules`: the karabas-go-modules submodule (`kg_mcu2` link v2, `kg_l2_osd_overlay`, `hdmi_tx`, `kg_pll`, `kg_pcm5102`).
- `src/rtl/karabas_minig_top.v`: the board glue around `vt100_top` (see its header): `vt_clocks` (50 / 25 / 125 / 10 / 8 MHz), `kg_mcu2` (port 0, OSD, AUX debug), `vt_uart` (8N1 115200 between port 0 and kl11; out_ready drops with out_wr and while the terminal holds rts), the picture in two levels in the colour of the OSD item, the bitmap OSD, HDMI and the PCM5102 (the bell).
- `src/rtl/vt100`: the PDP2011 sources the terminal needs. The karabas fixes (from core-rc2014): `kl11.vhd` sample divider `<` instead of `<=` (it ran at 111607 bps, back-to-back frames lost sync), `vt.vhd` rts of kl11 wired out, `vt100_top.vhd` rtscts 1 (the receive silo of 16 bytes) and the PS/2 byte interface (`ps2k_upd` / `ps2k_dat`, `ps2.vhd` + `rtl/fifo/afifo.v`), `vgai` (vga_ht, normal text) next to `vgao` (bold).
- `src/sim/tb_vt_uart.v` (`make sim`, iverilog): vt_uart fed as kg_l2_port feeds it, back to back with rts going on and off.

## Build

- `cd src && make minig` (xst, impl, `.kg`), `make minig-report`. `make_core.py` is a symlink to `../../karabas-go-tools/make_core/make_core.py`. `core.json` (kgo2, `"link": 2`) packs `vt100.kg`; `karabas_<board>.bin` and `vt100.kg` are committed.
- OSD (`core.json`): 0 Colour (Amber / Green / White), 1 Reset (Menu+F12; also board button 1).
- XON / XOFF of the terminal are done in the line (`karabas_minig_top.v`, as `rc2014_xonxoff`): the vt10x firmware drops characters while it scrolls and sends XOFF; the PC reacts too late (2000-line flood at 115200 lost chunks on 26111920), so XOFF holds `vt_uart_tx` at once, XON releases it, both are not sent to the PC. ^S / ^Q of the keyboard pause the output.
- DEBUG (`AT+KARABAS=debug:1`): addr { bytes PC -> terminal, bytes terminal -> PC }, data { rts, xoff, out ready, in full, XOFF count (4 bits), bytes dropped }.

## Memory

The Claude Code memory of this repo is shared with all karabas-go repos: `~/.claude/projects/<this project>/memory` is a symlink to `../karabas-go-notes` (private repo `andykarpov/karabas-go-notes`, `link.sh` there makes the links). Its `MEMORY.md` is split by repo; commit and push it after every memory change.
