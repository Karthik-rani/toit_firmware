import gpio
import uart
import io
import log
import encoding.hex

class Printer:
  _rx_pin := 0
  _tx_pin := 0
  _baud_rate := 0 
  _peeler_flag/bool? := null
  port/uart.Port?

  constructor --rx-pin/int = 35
              --tx-pin/int = 32
              --baud-rate/int = 9600
              --peeler-flag/bool= false:
    _rx_pin = rx-pin
    _tx_pin = tx-pin
    _baud_rate = baud-rate
    _peeler_flag = peeler-flag

    port = uart.Port
      --rx=gpio.Pin _rx_pin
      --tx=gpio.Pin _tx_pin
      --baud-rate = _baud_rate
    
    log.set-default (log.default.with-level log.DEBUG-LEVEL)
    // log.set-default (log.default.with-level log.INFO-LEVEL)
    log.info "peeler_flag:$_peeler_flag" --tags={"Component":"Printer"} 
  

  print label/string:
    if port != null:
      log.debug "Printer uart is initialized" --tags={"Function":"Printer UART"}
      if _peeler_flag :
        log.debug "enter peeler check" --tags={"Function":"Printer"}
        peeler_cmd := "\x1B!S\n"
        port.out.flush
        port.out.write peeler_cmd.to-byte-array
        sleep --ms = 20
        port.out.flush
        read_peeler := port.in
        status := read_peeler.read
        log.debug "$status" --tags={"Component":"Peeler"}
        if status.size >= 8: 
          log.debug "peeler_status:$status" --tags={"Component":"Peeler"}
          if status[1] == 76: // 76 is decimal value of 0x4C --wait for label to be peeled
            log.debug "sent print without checking the peeler status" --tags={"Comp":"Printer"} 
            return
          else:
            port.out.flush
            port.out.write label.to-byte-array
      else:
        log.debug"sent print without checking the peeler status" --tags={"Comp":"Printer"} 
        port.out.flush
        port.out.write label.to-byte-array
    else:
      log.debug "Printer uart is not initialized exiting the function" --tags={"Function":"Printer UART"} 
      return 

/*use Main function for testing 
Explicit pf flag is used for changing the label template locally ,
change peeler-flag for the reserved monitor flag from the server */

main:
  RX := 36
  TX := 12
  pf := false // pf -- explicit peeler flag
  label/string? := null
  printer := Printer --rx-pin=RX --tx-pin=TX --baud-rate=9600 --peeler-flag= false
  while true:
    if pf :    
      label="""
        SIZE 40 mm, 50 mm
        GAP 3 mm, 3 mm
        SPEED 2
        DIRECTION 1,0
        SHIFT 0,0
        SOUND 0,1
        SET PEEL ON
        CLS
        TEXT 10,45,"1",0,1,2,\"DESCRIPTION1\"
        TEXT 10,67,"1",0,1,2,\"DESCRIPTION2\"
        TEXT 10,100,"1",0,1,2,"Net Weight WEIGHTkg"
        BARCODE 10, 130, "128",50,1,0,2,4,0,"BARCODE"
        PRINT 1
        """
      printer.print label
    else:
      label="""
        SIZE 40 mm, 50 mm
        GAP 3 mm, 3 mm
        SPEED 2
        DIRECTION 1,0
        SHIFT 0,0
        SOUND 0,1
        SET PEEL OFF
        CLS
        TEXT 10,45,"1",0,1,2,\"DESCRIPTION1\"
        TEXT 10,67,"1",0,1,2,\"DESCRIPTION2\"
        TEXT 10,100,"1",0,1,2,"Net Weight WEIGHTkg"
        BARCODE 10, 130, "128",50,1,0,2,4,0,"BARCODE"
        PRINT 1
        """
      printer.print label
    
  sleep --ms = 1000

