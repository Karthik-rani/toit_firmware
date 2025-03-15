import binary
import gpio
import io
import i2c
import log
import monitor
import pcf8574 show *

class Lcd:
  static LCD-20x4 ::= 2
  static LCD-DATA_ ::= 1
  static LCD-CMD_ ::= 0
  static INIT-SEQ-1_ ::= 0x33
  static INIT-SEQ-2_ ::= 0x32
  static DISP-CLEAR_ ::= 0x01
  static RETURN-HOME_ ::= 0x02
  static DISPLAY-CURSOR-CMD-BIT_ ::= 0b1000
  static DISPLAY-ON-BIT_ ::= 0b0100
  static CURSOR_ ::= 0x00
  static DISPLAY_ ::= 0x08
  static LINE-1_ ::= 0x80
  static LINE-2_ ::= 0xC0
  static LINE-3_ ::= 0x94
  static LINE-4_ ::= 0xD4

  rs-pin/int? := null 
  _backlight-pin/int? := null
  en-pin/int? := null
  d4-pin/int? := null
  d5-pin/int? := null
  d6-pin/int? := null
  d7-pin/int? := null
  lcd-type/int? := null
  pcf8574 := ?
  device := ?
  keys := List
  mutex := monitor.Mutex
  scroll/bool? := null
  _scroll_delay/int? := null
  scrolling-lines := Map
  _device_address := 0
  scrolling-rows := Map
  rows_/int? := null
  columns_/int? := null
  _enable_scroll_task/bool? := null
  value := List

  constructor
      --bus/i2c.Bus
      --rs/int = 0
      --en/int = 2
      --d4/int = 4
      --d5/int = 5
      --d6/int = 6
      --d7/int = 7
      --backlight-pin/int = 3
      --type/int = Lcd.LCD-20x4
      --rows/int = 4
      --columns/int = 20
      --device-address=0x27
      --scroll-delay=10
      --enable-scroll-task=false:

    rs-pin = rs
    en-pin = en
    d4-pin = d4
    d5-pin = d5
    d6-pin = d6
    d7-pin = d7
    rows_ = rows
    columns_ = columns
    _backlight-pin = backlight-pin
    _scroll_delay = scroll-delay
    lcd-type = type
    _device_address = device-address
    _enable_scroll_task = enable-scroll-task
    log.set-default (log.default.with-level log.INFO-LEVEL)

    device = bus.device _device_address
    pcf8574 = Pcf8574 device
    pcf8574.write --raw=true 0x00 // Initialize PCF8574 pins
    write-command_ INIT-SEQ-1_
    write-command_ INIT-SEQ-2_
    backlight-on 
    on
    // rows_.repeat: |i| clear i
    // place-cursor 0 0
    write-command_ DISP-CLEAR_
    cursor --home

    if _enable_scroll_task:
      task :: lcd-scroll-task

  on: write-command_ DISPLAY-CURSOR-CMD-BIT_ | DISPLAY-ON-BIT_
  backlight-on: pcf8574.set --pin=_backlight-pin 1
  cursor --home -> none: write-command_ RETURN-HOME_

  write str: str.do: write-data_ it

  place-cursor row/int column/int -> none:
    if lcd-type == LCD-20x4:
      if not (0 <= row <= 3 ): throw "INVALID_ROW_COLUMN"
    else:
      unreachable
    command := ?
    if row == 0:      command = LINE-1_
    else if row == 1: command = LINE-2_
    else if row == 2: command = LINE-3_
    else:             command = LINE-4_
    command += column
    write-command_ command

  write-command_ byte: write-byte_ byte LCD-CMD_
  write-data_ byte: write-byte_ byte LCD-DATA_

  write-byte_ bits mode:
    pcf8574.set --pin=rs-pin mode
    pcf8574.set --pin=en-pin 0
    pcf8574.set --pin=d7-pin (bits >> 7) & 1
    pcf8574.set --pin=d6-pin (bits >> 6) & 1
    pcf8574.set --pin=d5-pin (bits >> 5) & 1
    pcf8574.set --pin=d4-pin (bits >> 4) & 1
    enbale_clock_pulse
    pcf8574.set --pin=d7-pin (bits >> 3) & 1
    pcf8574.set --pin=d6-pin (bits >> 2) & 1
    pcf8574.set --pin=d5-pin (bits >> 1) & 1
    pcf8574.set --pin=d4-pin bits & 1
    enbale_clock_pulse

  enbale_clock_pulse:
    pcf8574.set --pin=en-pin 1
    sleep --ms=1
    pcf8574.set --pin=en-pin 0
    sleep --ms=1

/*Handles the display-string for rows 0, 1, 2, 3*/
  display-string row/int column/int str/string scroll/bool=false:
    if not (0 <= row < rows_):
      throw "INVALID_ROW: $row"

    mutex.do:
      if scroll and _enable_scroll_task:
        value = scrolling-lines.get row
        if value == null:
          scrolling-lines[row] = [str, column, 0]
        else:
          scrolling-lines[row] = [str, column, value[2]]
      else:
        max_char := columns_ - column
        if str.size > max_char:
          str = str[0..max_char]
        place-cursor row column
        write str
        scrolling-lines.remove row

  /*Function to handle the LCD scrolling task*/
  lcd-scroll-task:
    while true:
      mutex.do:
        keys = scrolling-lines.keys
      for i:=0; i< keys.size;i++:
        row :=keys[i]
        mutex.do:
          value = scrolling-lines.get row
        if value == null:
          continue
        str := value[0]
        start-column := value[1]
        current-index := value[2]
        if str.size == 0:
          continue
        buffer := ""
        for j := 0 ;j<(columns_ - start-column - 1);j++:
          if current-index + j < str.size:
            buffer += string.from-rune (str[current-index + j])
          else:
            buffer += " "
        mutex.do:
          if scrolling-lines.contains row:
            place-cursor row start-column
            write buffer
            log.info "Row $row Buffer: $buffer" --tags={"Component": "Lcd"}
            scrolling-lines[row] = [str, start-column, (current-index + 1) % str.size]
      sleep --ms=_scroll_delay

  /*Clears the individual rows*/
  clear row/int:
    if not (0 <= row < rows_):
        throw "INVALID_ROW: $row"
    mutex.do:
        if scrolling-lines.contains row:
          scrolling-lines.remove row 
          place-cursor row 0
          write " " * columns_
        else:
          place-cursor row 0
          write " " * columns_
