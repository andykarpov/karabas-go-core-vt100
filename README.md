# Karabas Go VT100 Core

VT100 terminal emulator

## Howto:

### On Linux side:

The terminal is on the core serial port of the board: the second USB serial port,
`/dev/serial/by-id/usb-Karabas_Go_<serial>-if02` (usually `ttyACM1`; the numbers are not stable, the
first port `-if00` has only the log and the `AT+KARABAS=` commands of the firmware).

- sudo agetty -L 115200 /dev/serial/by-id/usb-Karabas_Go_<serial>-if02 vt100

or, with the udev rule of the firmware README (`/dev/karabas-serial`):

- sudo systemctl enable serial-getty@karabas-serial.service
- sudo systemctl start serial-getty@karabas-serial.service

### On Karabas side:

- you should see a login prompt.

Make sure the terminal type is set to vt100 (default).

### Resource with tty movies:

http://artscene.textfiles.com/vt100/
