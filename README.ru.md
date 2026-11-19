# Ядро VT100 для Karabas Go

[English version](README.md)

Терминал VT100 для плат Karabas Go, Mini и Mini G: VT100 из [PDP2011](https://pdp2011.sytse.net/)
Sytse van Slooten (PDP-11 с прошивкой терминала vt10x) на последовательном порту платы. Подключите
плату к ПК по USB и запустите getty на порту ядра: на экране платы появится приглашение входа.

| Плата | Файл ядра | Видео |
|---|---|---|
| Karabas Go | `src/vt100.kg` (один файл для всех плат) | VGA 640 x 480 |
| Karabas Mini | | HDMI / DVI 640 x 480 |
| Karabas Mini G | | HDMI / DVI 640 x 480 |

Состояние: проверено на Mini G (линия в обе стороны, поток из 2000 строк на полной скорости без
потерь, жирный текст, цвета). Сборки для Go и Mini на платах ещё не запускались.

## Возможности

- VT100 (прошивка vt10x), 80 x 24, обычный и жирный текст, звонок (на HDMI и на звуковом выходе).
- Последовательная линия: 115200 8N1 на порту ядра платы (ниже). XON / XOFF терминала
  обрабатываются в ядре: при прокрутке ничего не теряется, Ctrl+S / Ctrl+Q ставят вывод на паузу и
  продолжают его.
- USB- или PS/2-клавиатура платы.
- Цвет в OSD: янтарный, зелёный или белый (жирный текст рисуется толще, тем же цветом).

## Начало работы

1. Скопируйте `src/vt100.kg` в корень SD-карты и выберите VT100 в меню ядер. Нужна прошивка
   v26111914 или новее.
2. На ПК (Linux) запустите getty на порту ядра платы: втором USB-последовательном порту,
   `/dev/serial/by-id/usb-Karabas_Go_<серийник>-if02` (обычно `ttyACM1`; номера не постоянны.
   На первом порту `-if00` только лог и команды прошивки `AT+KARABAS=`):

   ```
   sudo agetty -L 115200 /dev/serial/by-id/usb-Karabas_Go_<серийник>-if02 vt100
   ```

   или, с правилом udev из [README прошивки](https://github.com/andykarpov/karabas-go-firmware/blob/master/README.ru.md)
   (`/dev/karabas-serial`):

   ```
   sudo systemctl enable serial-getty@karabas-serial.service
   sudo systemctl start serial-getty@karabas-serial.service
   ```

3. На плате появится приглашение входа. Тип терминала оставьте vt100 (`TERM=vt100`).

macOS: `/dev/cu.usbmodem<серийник>3`; Windows: COM-порт «Karabas core serial». USB-UART
переходник, вставленный в USB host платы, занимает место порта ядра.

## OSD

**Menu+Esc** («Menu» — клавиша Windows): **Colour** (Amber / Green / White) и **Reset** терминала
(**Menu+F12**, также кнопка 1 платы). Ctrl+Alt+Backspace возвращает в меню ядер.

## Сборка

ISE 14.7: `cd src && make minig` (или `go`, `mini`), `make minig-report`; `make sim` запускает
тестбенч последовательной линии (iverilog). Модули берутся из подмодуля `modules`
(karabas-go-modules): `git submodule update --init`. `src/make_core.py` — ссылка на
karabas-go-tools рядом с этим репозиторием.

## Ролики для tty

http://artscene.textfiles.com/vt100/

## Лицензия

Репозиторий: MIT (`LICENSE`). Исходники VT100 / PDP2011 (`src/rtl/vt100`) принадлежат Sytse van
Slooten: только личное некоммерческое использование, их заголовки не меняются.
