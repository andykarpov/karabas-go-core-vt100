# Karabas Go VT100 Core

[Русская версия](README.ru.md)

A VT100 terminal for the Karabas Go, Mini and Mini G boards: the VT100 of Sytse van Slooten's
[PDP2011](https://pdp2011.sytse.net/) (a PDP-11 running the vt10x terminal firmware) on the serial
port of the board. Plug the board into a PC by USB and run a getty on its core serial port: the
board shows the login prompt.

| Board | Core file | Video |
|---|---|---|
| Karabas Go | `src/vt100.kg` (one file for all boards) | VGA 640 x 480 |
| Karabas Mini | | HDMI / DVI 640 x 480 |
| Karabas Mini G | | HDMI / DVI 640 x 480 |

Status: checked on Mini G (both ways of the line, a full-speed flood of 2000 lines without a lost
one, bold text, the colours). The Go and Mini builds have not been run on a board yet.

## Features

- VT100 (vt10x firmware), 80 x 24, normal and bold text, the bell (on HDMI and the audio output).
- The serial line: 115200 8N1 on the core serial port of the board (below). XON / XOFF of the
  terminal are handled in the core: nothing is lost while the screen scrolls, and Ctrl+S / Ctrl+Q
  pause and resume the output.
- USB or PS/2 keyboard of the board.
- Colour in the OSD: amber, green or white; normal text at half brightness, bold at full.

## Getting started

1. Copy `src/vt100.kg` to the root of the SD card and choose VT100 in the core menu. Firmware
   v26111914 or newer.
2. On the PC (Linux), run a getty on the core serial port of the board: the second USB serial port,
   `/dev/serial/by-id/usb-Karabas_Go_<serial>-if02` (usually `ttyACM1`; the numbers are not stable.
   The first port `-if00` has only the log and the `AT+KARABAS=` commands of the firmware):

   ```
   sudo agetty -L 115200 /dev/serial/by-id/usb-Karabas_Go_<serial>-if02 vt100
   ```

   or, with the udev rule of the [firmware README](https://github.com/andykarpov/karabas-go-firmware#two-serial-ports)
   (`/dev/karabas-serial`):

   ```
   sudo systemctl enable serial-getty@karabas-serial.service
   sudo systemctl start serial-getty@karabas-serial.service
   ```

3. The board shows a login prompt. Keep the terminal type vt100 (`TERM=vt100`).

macOS: `/dev/cu.usbmodem<serial>3`; Windows: the COM port named "Karabas core serial". A USB-UART
adapter plugged into the USB host of the board takes the place of the core serial port.

## OSD

**Menu+Esc** ("Menu" is the Windows key): **Colour** (Amber / Green / White) and **Reset** of the
terminal (**Menu+F12**, also board button 1). Ctrl+Alt+Backspace goes back to the core menu.

## Build

ISE 14.7: `cd src && make minig` (or `go`, `mini`), `make minig-report`; `make sim` runs the
testbench of the serial line (iverilog). The modules come from the `modules` submodule
(karabas-go-modules): `git submodule update --init`. `src/make_core.py` is a link to
karabas-go-tools next to this repo.

## Resource with tty movies

http://artscene.textfiles.com/vt100/

## License

The repo: MIT (`LICENSE`). The VT100 / PDP2011 sources (`src/rtl/vt100`) are Sytse van Slooten's:
personal, non-commercial use only, their notices unchanged.
