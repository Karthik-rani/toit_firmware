import gpio
import i2c
import log
import esp32

class Rtc:
  // PCF8563 Register Definitions
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

  bus:=?
  _device_address := 0
  constructor --sda-pin =13 --scl-pin= 16 --clock-frequency= 100000 --device-address= 0x51:
    bus = i2c.Bus
      --sda=gpio.Pin sda-pin
      --scl=gpio.Pin scl-pin
      --frequency=clock-frequency
    _device_address = device-address
    device := bus.device device-address
    log.info "Device initialized successfully: $device" --tags={"Component":"Rtc"}
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

  read_all_registers:
    for reg := 0x00; reg <= 0x08; reg++:
      data := bus.read-reg_ _device_address reg 1:
        print "failure to read the reg"
      // dec:= bcd-to-dec data
      print "Register $reg value: $data"
    print "All registers read successfully."

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
    log.info "get_time_date is success" --tags={"Component":"Rtc"}
    day:= bcd_to_dec (d[0] & DAY_MASK)
    weekday:= bcd_to_dec (w[0] & WEEK_DAY_MASK)
    month := bcd_to_dec (m[0] & MONTH_MASK) // Mask the month correctly
    century_flag := (m[0] >> 7) & 0x01
    log.info "Centruy_Flag: $century_flag" --tags={"Component":"Rtc"}
    year:=?
    if century_flag == 1:
      year = bcd_to_dec y[0] 
      year = year + 2000
    else:
      year = bcd_to_dec y[0] 
      year = year + 1900
    print "day:$day, weekday:$weekday, month:$month, year:$year"
    return [day, weekday, month, year]

// Helper functions for BCD/Decimal conversion
  dec_to_bcd dec/int -> int:
    return ((dec / 10) << 4) | (dec % 10)


  bcd_to_dec bcd/int -> int:
   return ((bcd >> 4) * 10) + (bcd & 0x0F)


main:
  current_time := Time.now.local
  print "Current time :$current_time"
  SDA := 13
  SCL := 16
  time := []
  date := []
  address := 0x51
  // Initialize the RTC instance
  rtc := Rtc
    --sda-pin=SDA
    --scl-pin=SCL
    --device-address= address
    --clock-frequency=100000
  // Clear RTC registers
  rtc.init_rtc
  rtc.read-all-registers
  // rtc.set_time_date 54 59 23 30 5 11 2023
  date = rtc.get_date
  log.info "Date:$(date[0].stringify)-$(date[2].stringify)-$(date[3].stringify)" --tags={"Component":"Rtc"}
  while true:
    time =rtc.get_time
    log.info "Time:$(time[0].stringify):$(time[1].stringify):$(time[2].stringify)" --tags={"Component":"Rtc"}
    if time[0] == 0 and time[1] == 0 and time[2]== 0:
      date = rtc.get_date
      log.info "Date:$(date[0].stringify)-$(date[2].stringify)-$(date[3].stringify)" --tags={"Component":"Rtc"}
    sleep --ms = 1000

// main:
//   rtc := Rtc  --device-address=0x51

//   now := Time.now.local
//   rtc_time := rtc.get_time
//   rtc_date := rtc.get_date

//   // Extract RTC values
//   rtc_hours := rtc_time[0]
//   rtc_minutes := rtc_time[1]
//   rtc_seconds := rtc_time[2]
//   rtc_day := rtc_date[0]
//   rtc_weekday := rtc_date[1]  // Fetch weekday
//   rtc_month := rtc_date[2]
//   rtc_year := rtc_date[3]

//   // Convert RTC values into a Time object
//   rtc_current_time := Time.local
//     --year=rtc_year
//     --month=rtc_month
//     --day=rtc_day
//     --h=rtc_hours
//     --m=rtc_minutes
//     --s=rtc_seconds

//   print "System Time: $now"
//   print "RTC Time: $rtc_current_time (Weekday: $rtc_weekday)"

//   // Check if RTC time is significantly different (more than 10 seconds)
//   if (rtc_current_time.to now).abs > Duration --s=10:
//     print "System time is incorrect. Updating from RTC..."
//     esp32.adjust-real-time-clock rtc_current_time
//     print "System time updated to RTC: $rtc_current_time (Weekday: $rtc_weekday)"
//   else:
//     print "System time is correct."

//   while true:
//     now := Time.now.local
//     weekday := now.weekday  // Get weekday from TimeInfo
//     print "IST Time: $now (Weekday: $weekday)"
//     sleep --ms=1000
