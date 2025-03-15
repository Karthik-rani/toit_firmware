import gpio
import i2c
import log
import .lcd1 show *

class RTC:
  static CONTROL_STATUS1 ::= 0x00
  static CONTROL_STATUS2 ::= 0x01
  static SECONDS         ::= 0x02
  static MINUTES         ::= 0x03
  static HOURS           ::= 0x04
  static DAY             ::= 0x05
  static WEEKDAY         ::= 0x06
  static MONTH           ::= 0x07
  static YEAR            ::= 0x08
  static SECOND_MASK     ::= 0x7F
  static MINUTE_MASK     ::= 0x7F
  static HOUR_MASK       ::= 0x3F
  static DAY_MASK        ::= 0x3F
  static WEEK_DAY_MASK   ::= 0x07
  static MONTH_MASK      ::= 0x1F
  static CENTURY_MASK    ::= 0x80
  
  bus := ?
  _device_address := 0

  constructor --bus/i2c.Bus --device-address=0x51:
    this.bus = bus
    _device_address = device-address
    print "RTC initialized on address $device-address"
    log.set-default (log.default.with-level log.INFO-LEVEL)
  

  init_rtc:
    bus.write-reg_ _device_address CONTROL_STATUS1 #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address CONTROL_STATUS2 #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address SECONDS #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address MINUTES #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address HOURS #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address DAY #[0x01]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address WEEKDAY #[0x06]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address MONTH #[0x00]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address YEAR #[0x01]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    print "RTC cleared to default values."
    print "RTC initialized with default values."

  

  set_time_date seconds minutes hours day weekday month year:
    print "month: $month"
    bus.write-reg_ _device_address SECONDS #[dec_to_bcd (seconds & SECOND_MASK)]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address MINUTES #[dec_to_bcd (minutes & MINUTE_MASK)]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address HOURS #[dec_to_bcd (hours & HOUR_MASK)]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address DAY #[dec_to_bcd (day & DAY_MASK)]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address WEEKDAY #[dec_to_bcd (weekday & WEEK_DAY_MASK) ]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address MONTH #[(dec_to_bcd (month & 0x1F)) | (year >= 2000 ? 0x80 : 0x00)]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    bus.write-reg_ _device_address YEAR #[dec_to_bcd year % 100]:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    print "Time and date set successfully."

  get_time -> List:
    sec := bus.read-reg_ _device_address SECONDS 1:
      print "Failure to read seconds"
    min := bus.read-reg_ _device_address MINUTES 1:
      print "Failure to read minutes"
    hr := bus.read-reg_ _device_address HOURS 1:
      print "Failure to read hours"
    seconds := bcd_to_dec sec[0] & SECOND_MASK
    minutes := bcd_to_dec min[0] & MINUTE_MASK
    hours := bcd_to_dec hr[0] & HOUR_MASK
    return [hours, minutes, seconds]

  get_date -> List:
    d:=bus.read-reg_ _device_address DAY 1:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    w:=bus.read-reg_ _device_address WEEKDAY 1:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    m:=bus.read-reg_ _device_address MONTH 1:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    y:=bus.read-reg_ _device_address YEAR 1:
      log.info  "failure to write" --tags={"Component":"Rtc"}
    print "d:$d"
    print "w:$w"
    print "m:$m"
    print "y:$y"
    print "get_time_date is success"
    day:= bcd_to_dec (d[0] & DAY_MASK)
    weekday:= bcd_to_dec (w[0] & WEEK_DAY_MASK)
    month := bcd_to_dec (m[0] & MONTH_MASK) // Mask the month correctly
    century_flag := (m[0] >> 7) & 0x01
    print "CFlag: $century_flag"
    year:=?
    if century_flag == 1:
      year = bcd_to_dec y[0] 
      year = year + 2000
    else:
      year = bcd_to_dec y[0] 
      year = year + 1900
    print "day:$day, weekday:$weekday, month:$month, year:$year"
    return [day, weekday, month, year]
  

  static dec_to_bcd dec/int -> int:
    return ((dec / 10) << 4) | (dec % 10)

  static bcd_to_dec bcd/int -> int:
    return ((bcd >> 4) * 10) + (bcd & 0x0F)

    
main:
  SDA := 13
  SCL := 16
  time := List
  date := List
  prev_time := [0, 0, 0]  // Track previous time for comparison
  // Create a shared I2C bus
  bus := i2c.Bus
    --sda=gpio.Pin SDA
    --scl=gpio.Pin SCL
    --frequency=100000

  // Initialize RTC using shared I2C bus
  rtc := RTC
    --bus=bus
    --device-address=0x51

  // Initialize LCD using the same shared I2C bus
  lcd := Lcd
    --bus=bus
    --device-address=0x27

  rtc.init_rtc
  // sleep --ms= 100
  // rtc.set_time_date 14 21 13 3 04 01 2000
  // rtc.set_time_date 54 59 13 31 1 2 1908  // Set time to 23:59:59 on Jan 10, 2025
  // rtc.set_time_date 30 45 12 25 6 12 1998  // December 1998
  // rtc.set_time_date 30 45 12 25 6 12 2025  // December 2025
  rtc.set_time_date 54 59 23 30 5 11 2023
  date = rtc.get_date
  lcd.display-string 0 0 "Date:$(format-two-digits date[0])-$(format-two-digits date[2])-$(format-two-digits date[3])"
  // lcd.display-string 2 0 "Test is goingonDon't"
  // lcd.display-string 3 0 "Power off the device" 

  while true:
    time = rtc.get_time

    // Handle transition to the next day
    if time[0] == 0 and time[1] == 0 and time[2] == 0 and prev_time != [0, 0, 0]:
      date = rtc.get_date
      lcd.clear 0
      lcd.display-string 0 0 "Date:$(format-two-digits date[0])-$(format-two-digits date[2])-$(format-two-digits date[3])"

    // Update time display
    lcd.display-string 1 0 "RTC:$(format-two-digits time[0]):$(format-two-digits time[1]):$(format-two-digits time[2])"
    
    // Store the current time for the next iteration
    prev_time = time
    sleep --ms=600

// Helper function to format numbers as two-digit strings
format-two-digits num/int -> string:
  if num < 10:
    return "0$num"
  return num.stringify
