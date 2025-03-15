import binary
import gpio
import io
import i2c
import log
import monitor
import pcf8574 show *
class Lcd:
  // variables for initializing the Lcd holds the hex commands to send
  static LCD-20x4 ::= 2
  static LCD-DATA_ ::=   1 // To write text to the display.
  static LCD-CMD_  ::=   0 // To send instructions to the display.
  static INIT-SEQ-1_      ::=   0x33
  static INIT-SEQ-2_      ::=   0x32
  static DISP-CLEAR_      ::=   0x01
  static RETURN-HOME_     ::=   0x02
  static DISPLAY-CURSOR-CMD-BIT_ ::= 0b1000
  static DISPLAY-ON-BIT_         ::= 0b0100
  static CURSOR_  ::=   0x00
  static DISPLAY_ ::=   0x08
  static LINE-1_ ::=   0x80 // LCD RAM address for the 1st line.
  static LINE-2_ ::=   0xC0 // LCD RAM address for the 2nd line.
  static LINE-3_ ::=   0x94 // LCD RAM address for the 3rd line.
  static LINE-4_ ::=   0xD4 // LCD RAM address for the 4th line.
  // varaibles for pcf pin configurations
  rs-pin/int? := null 
  _backlight-pin/int? := null
  en-pin/int? := null
  d4-pin/int? := null
  d5-pin/int? := null
  d6-pin/int? := null
  d7-pin/int? := null
  lcd-type/int? := null
  pcf8574:= ?
  device := ?
  keys:=List
  mutex:= monitor.Mutex
  scroll/bool? := null
  _scroll_delay/int? :=null
  scrolling-lines:=Map
  _sda_pin/int? := null
  _scl_pin/int? := null
  _clock_frequency/int? := null
  _device_address := 0
  scrolling-rows := Map  // Map to store current index for each row.
  rows_/int? := null
  columns_/int? :=null
  _enable_scroll_task/bool? := null
  value := List

  constructor
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
      --sda-pin/int = 13
      --scl-pin/int = 16
      --device-address =0x27
      --scroll-delay=10
      --clock-frequency = 100000
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
    lcd-type = type // type varaible is future purpose if use 16X2 LCD
    _sda_pin = sda-pin
    _scl_pin = scl-pin
    _device_address = device-address
    _clock_frequency = clock-frequency
    _enable_scroll_task = enable-scroll-task
    log.set-default (log.default.with-level log.INFO-LEVEL)

    bus := i2c.Bus 
      --sda= gpio.Pin _sda_pin
      --scl= gpio.Pin _scl_pin
      --frequency= clock-frequency
    device = bus.device _device_address

    pcf8574 = Pcf8574 device
    //initialize pcf pins with zero
    pcf8574.write --raw=true 0x00
    // Default initialization of lcd
    write-command_ INIT-SEQ-1_
    write-command_ INIT-SEQ-2_
    backlight-on 
    on
    //clear all the rows initially
    rows_.repeat: |i|
      clear i
    cursor --home

   //Flag to enable scroll task
    if _enable_scroll_task:
      task :: lcd-scroll-task

  /**
  Turns the display on without any cursor.

  Use $cursor to initialize the cursor.
  */
  on:
    write-command_ DISPLAY-CURSOR-CMD-BIT_ | DISPLAY-ON-BIT_

/*  Turns the backlight on.
  */
  backlight-on:
    pcf8574.set --pin=_backlight-pin 1

  /**
  Moves the cursor back to the home position.
  */
  cursor --home -> none:
    write-command_ RETURN-HOME_

  /*Writes the string to the display*/
  write str:
    str.do:
      write-data_ it
  /**
  Moves the cursor to the given position.

  Rows and columns are 0-indexed.
  */
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

  write-command_ byte:
    write-byte_ byte LCD-CMD_
  write-data_ byte:
    write-byte_ byte LCD-DATA_
  // Changed the wrapper logic from normal gpio pin to Pcf pins
  write-byte_ bits mode:
    pcf8574.set --pin=rs-pin mode  // Data mode: 1 for Data, 0 for Instructions.
    pcf8574.set --pin=en-pin 0   // Ensure clock is low initially.
    // Upper nibble.
    pcf8574.set --pin=d7-pin (bits >> 7) & 1
    pcf8574.set --pin=d6-pin (bits >> 6) & 1
    pcf8574.set --pin=d5-pin (bits >> 5) & 1
    pcf8574.set --pin=d4-pin (bits >> 4) & 1
    enbale_clock_pulse
    // Lower nibble.
    pcf8574.set --pin=d7-pin (bits >> 3) & 1
    pcf8574.set --pin=d6-pin (bits >> 2) & 1
    pcf8574.set --pin=d5-pin (bits >> 1) & 1
    pcf8574.set --pin=d4-pin (bits & 1)
    enbale_clock_pulse
  //clock pulse for data transfer
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

/*Here is the main function to test the Lcd 20x4, run the code using jag run lcd.toit*, LCD 16X2 type is reserved for future purpose*/
// main :
//   SDA := 13
//   SCL := 16
//   device-address := 0x27

//   lcd := Lcd
//       --rs = 0
//       --en = 2
//       --d4 = 4
//       --d5 = 5
//       --d6 = 6
//       --d7 = 7
//       --type = Lcd.LCD-20x4
//       --sda-pin = SDA
//       --scl-pin = SCL
//       --device-address =device-address
//       --enable-scroll-task=true
//       --scroll-delay = 10
//       --clock-frequency=50000

//   lcd.display-string 0  0 "12356789012345678901234567890"
//   lcd.display-string  1  9 "HelloWorld"
//   lcd.display-string  2  0 "HelloWorld"
//   lcd.display-string  3  0 "HelloWorld"
//   sleep --ms = 1000
//   lcd.clear 0
//   lcd.clear 1
//   lcd.clear 2
//   lcd.clear 3
//   lcd.display-string 0 1 "123456789012345678901234567890" true
//   lcd.display-string  1  7 "HelloWorld" true
//   lcd.display-string  2  4 "HelloWorld" true
//   lcd.display-string  3  13 "HelloWorld" true
//   sleep --ms = 4000
//   lcd.clear 0
//   lcd.clear 1
//   lcd.clear 2
//   lcd.clear 3
//   while true:
//     sleep --ms = 1