import gpio
import uart
import io
import log
import encoding.hex

class Printer:
  max_fmt_size/int? := null // max label format size
  _rx_pin := 0
  _tx_pin := 0
  _baud_rate := 0 
  port/uart.Port?

  constructor --rx-pin/int = 35
              --tx-pin/int = 32
              --baud-rate/int = 9600:
    _rx_pin = rx-pin
    _tx_pin = tx-pin
    _baud_rate = baud-rate

    port = uart.Port
      --rx=gpio.Pin _rx_pin
      --tx=gpio.Pin _tx_pin
      --baud-rate = _baud_rate

    log.info "Printer Uart Initialized " --tags={"Component":"PRINTER"}
  print text/string:
    log.debug "enter peeler check" --tags={"Function":"Printer"}
    // peeler_cmd := "\x1B!S\n"
    peeler_cmd:="\x01#\n"
    port.out.flush
    port.out.write peeler_cmd.to-byte-array
    sleep --ms = 1000
    port.out.flush
    read_peeler := port.in
    status := read_peeler.read
    log.info "peeler:$status in bytes:$status.to-string-non-throwing" --tags={"Component":"Peeler"}
    sleep --ms = 1000
    // write_text := port.out
    // log.info "Printer function Invoked" --tags={"Component":"PRINTER"}
    // log.info "Text Received from the function: " --tags={"Component":"PRINTER"}
    // log.info "$text" --tags={"Component":"PRINTER"}
    // write_text.write text.to-byte-array
    // write_text.flush
    // sleep --ms =1000
 

  

main:
  log.set-default (log.default.with-level log.INFO-LEVEL)
  RX := 36
  TX := 12
  printer := Printer --rx-pin=RX --tx-pin=TX --baud-rate=9600
  count  := 0
  while true:
    // label := """
    //   SIZE 50 mm,30 mm            
    //   GAP 2 mm,0 mm
    //   DIRECTION 1,0
    //   SPEED 2
    //   SHIFT 0, 0
    //   SOUND 0,1
    //   SET PEEL ON
    //   CLS
    //   TEXT 20,50,"2",0,1,1,"Line1-Toit"
    //   TEXT 20,80,"2",0,1,1,"Line2-TX-12"
    //   TEXT 20,110,"2",0,1,1,"Line3-RX-36"
    //   TEXT 20,140,"2",0,1,1,"Line4-BAUD-RATE:9600"
    //   PRINT 1
    //   """    
    label:="""
          ^XA
          ^MMT
          ^MMP
          ^PW500
          ^LL250
          ^FO50,50
          ^A0N,30,30\n
          ^FDHello, world!^FS
          ^XZ
          """
    label.contains "\n" replace ""
    printer.print label
    sleep --ms = 4000