// Important Note: subtract weekday by "1" because toit uses 1-7 for weekday , but rtc uses 0-6 for weekday

import gpio
import i2c
import log
import esp32
import ntp

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
    log.info "pcf8563 initialized successfully: $device" --tags={"Component":"Rtc"}
    log.set-default (log.default.with-level log.INFO-LEVEL)
  
  //Initialization of Rtc
  init_rtc:
    bus.write-reg_ _device_address CONTROL_STATUS1 #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address CONTROL_STATUS2 #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address SECONDS #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address MINUTES #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address HOURS #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address DAY #[0x01]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address WEEKDAY #[0x06]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address MONTH #[0x00]:
      log.info  "failure to write" --tags={"Component":"initRtc"}
    bus.write-reg_ _device_address YEAR #[0x01]:
      log.info  "failure to write" --tags={"Component":"initRtc"}

  //Set Rtc time
  set_time_date seconds minutes hours day weekday month year:
    bus.write-reg_ _device_address SECONDS #[dec_to_bcd (seconds & SECOND_MASK)]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address MINUTES #[dec_to_bcd (minutes & MINUTE_MASK)]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address HOURS #[dec_to_bcd (hours & HOUR_MASK)]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address DAY #[dec_to_bcd (day & DAY_MASK)]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address WEEKDAY #[dec_to_bcd (weekday & WEEK_DAY_MASK) ]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address MONTH #[(dec_to_bcd (month & 0x1F)) | (year >= 2000 ? 0x80 : 0x00)]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
    bus.write-reg_ _device_address YEAR #[dec_to_bcd year % 100]:
      log.info  "failure to write" --tags={"Component":"set_time_date"}
  
  // set System date and time from the ntp server
  set_local_time_date:
    current_time_date/Time?:=null
    result_flag := ntp.synchronize
    print result_flag
    if result_flag:
      log.info "NTP synchronization successful" --tags={"Component":"set_local_time_date"}
      current_time_date = Time.now
      esp32.adjust-real-time-clock result_flag.adjustment
    ist_time_date := current_time_date.plus --h=5 --m=30
    return ist_time_date

  //get the system date and time    
  get_local_time_date -> List:
    get_time_date :=set_local_time_date.local
    l_seconds := get_time_date.s
    l_minutes := get_time_date.m
    l_hours := get_time_date.h
    l_day:= get_time_date.day
    l_weekday:= get_time_date.weekday - 1 
    l_month:= get_time_date.month
    l_year:= get_time_date.year
    return [l_seconds,l_minutes,l_hours,l_day,l_weekday,l_month,l_year]

  // Function to update system time from RTC when NTP fails
  set_system_time_date_from_rtc:
    log.info"NTP sync failed, falling back to RTC time" --tags={"Component":"set_system_time_from_rtc"}
    // Get time from RTC
    rtc_time := get_time
    rtc_date := get_date
    // Construct a new Time object using RTC values
    set_time_date_from_rtc := Time.local 
      --year  = rtc_date[3]  
      --month = rtc_date[2]
      --day   = rtc_date[0]  
      --h     = rtc_time[0]  //Hours
      --m     = rtc_time[1]  // Minutes
      --s     = rtc_time[2]  // Seconds
    // Set system time using RTC
    esp32.adjust-real-time-clock (Duration --s=set_time_date_from_rtc.s-since-epoch)
    return set_time_date_from_rtc

  //get the time from the Rtc 
  get_time -> List:
    sec := bus.read-reg_ _device_address SECONDS 1:
      log.info "Failure to read seconds" --tags={"Component":"get_time"}
    min := bus.read-reg_ _device_address MINUTES 1:
      log.info "Failure to read minutes" --tags={"Component":"get_time"}
    hr := bus.read-reg_ _device_address HOURS 1:
      log.info "Failure to read hours" --tags={"Component":"get_time"}
    seconds := bcd_to_dec sec[0] & SECOND_MASK
    minutes := bcd_to_dec min[0] & MINUTE_MASK
    hours := bcd_to_dec hr[0] & HOUR_MASK
    return [hours, minutes, seconds]

  // get the date from the Rtc
  get_date -> List:
    d:=bus.read-reg_ _device_address DAY 1:
      log.info  "failure to write" --tags={"Component":"get_date"}
    w:=bus.read-reg_ _device_address WEEKDAY 1:
      log.info  "failure to write" --tags={"Component":"get_date"}
    m:=bus.read-reg_ _device_address MONTH 1:
      log.info  "failure to write" --tags={"Component":"get_date"}
    y:=bus.read-reg_ _device_address YEAR 1:
      log.info  "failure to write" --tags={"Component":"get_date"}
    log.info "get_time_date is success" --tags={"Component":"get_date"}
    day:= bcd_to_dec (d[0] & DAY_MASK)
    weekday:= bcd_to_dec (w[0] & WEEK_DAY_MASK)
    month := bcd_to_dec (m[0] & MONTH_MASK) // Mask the month correctly
    century_flag := (m[0] >> 7) & 0x01
    year:=?
    if century_flag == 1:
      year = bcd_to_dec y[0] 
      year = year + 2000
    else:
      year = bcd_to_dec y[0] 
      year = year + 1900
    return [day, weekday, month, year]

// Helper functions for BCD/Decimal conversion
  dec_to_bcd dec/int -> int:
    return ((dec / 10) << 4) | (dec % 10)

  bcd_to_dec bcd/int -> int:
   return ((bcd >> 4) * 10) + (bcd & 0x0F)

/*main function to test
 Use jag run rtc.toit to test the main function*/
main:
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
  set_ist:=rtc.set_local_time_date
  log.info "ist:$set_ist" --tags={"Component":"Rtc_main"}
  get_ist:=rtc.get_local_time_date
  log.info"system  Time:$get-ist[2]:$get-ist[1]:$get-ist[0], Date:$get_ist[3]-$get_ist[5]-$get_ist[6]" --tags={"Component":"Rtc_main"} 
  rtc.set_time_date get_ist[0] get_ist[1] get_ist[2] get_ist[3] get_ist[4] get_ist[5] get_ist[6] 
  date =rtc.get_date
  log.info "Rtc_Date:$(date[0])-$(date[2])-$(date[3])" --tags={"Component":"Rtcmain"}
  time =rtc.get_time
  log.info "Rtc_Time:$(time[0]):$(time[1]):$(time[2])" --tags={"Component":"Rtcmian"}

  /*to update the system time using the External Rtc Uncomment below Lines and Comment out above lines upto rtc.init-rtc */
  // rtc.set_time_date 30 45 12 25 6 12 1999  // December 1998
  // set_ist:= rtc.set_system_time_date_from_rtc
  // print "Sytem time from rtc : $set_ist"




  