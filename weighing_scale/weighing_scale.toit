import gpio
import uart
import io
import log
import encoding.hex

class WeighingScale:
  weight_str/string?:= null 
  new_weight := 0
  previous_weight := 0
  stable_count := 0
  stable_weight := 0
  last_stable_weight := 0
  _stable_factor := 0
  _scale_resolution := 0
  _rx_pin := 0
  _tx_pin := 0
  _baud_rate := 0
  _callback/Lambda?:= null
  port/uart.Port?

  constructor --rx-pin/int = 36
              --tx-pin/int = 12
              --baud-rate/int = 9600
              --scale-resolution/int = 10
              --stable-factor/int = 3
              --callback/Lambda?= null :
    _rx_pin = rx-pin
    _tx_pin = tx-pin
    _baud_rate = baud-rate
    _scale_resolution = scale-resolution
    _stable_factor = stable-factor

    port = uart.Port
      --rx=gpio.Pin _rx_pin
      --tx=gpio.Pin _tx_pin
      --baud-rate=_baud_rate
              
  enable-weighing-scale-task:
    task:: weighing-scale-task

    log.debug "SCALE_RESOLUTION: $_scale_resolution" --tags = {"Component":"WEIGHING_SCALE"}
    log.debug "STABLE_FACTOR:$_stable_factor" --tags = {"Component":"WEIGHING_SCALE"}


  weighing-scale-task:
    log.info "Weighing scale task Initialized" --tags = {"Component":"WEIGHING_SCALE"}
    if port == null:
      log.debug "UART port not initialized." --tags = {"Component":"WEIGHING_SCALE"}
      return
    read_weight := port.in
    log.info "UART is initialized" --tags = {"Component":"WEIGHING_SCALE"}
    
    while true:
      raw_weight := read_weight.read
      log.debug "RAW BYTES :$raw_weight" --tags = {"Component":"WEIGHING_SCALE"}
      weight_str = raw_weight.to-string-non-throwing.trim
      if weight_str.is-empty:
        log.debug "Invalid weight data: $weight_str" --tags = {"Component":"WEIGHING_SCALE"}
        continue
  
      try:
        new_weight = (float.parse weight_str) *1000  // Convert weight to grams
        log.debug "New_Weight: $(%0.3f new_weight)" --tags={"Component":"WEIGHING_SCALE"}
        // Check if weight difference is within resolution
        if (new_weight - previous_weight).abs <= _scale_resolution:
          stable_count += 1
        else:
          stable_count = 0
        previous_weight = new_weight
        if stable_count == _stable_factor and new_weight != 0:
          stable_count = 0  // Reset stable count after stabilization
          stable_weight = new_weight
          // Print only if the stable weight difference exceeds scale resolution
          if (stable_weight - last_stable_weight).abs >= _scale_resolution:
            if _callback:
              _callback.call stable_weight
            log.info "STABILIZED WEIGHT: $(%0.3f stable_weight)g" --tags = {"Component":"WEIGHING_SCALE"}
            last_stable_weight = stable_weight
      finally:
        continue


/*Use main for testing : jag run weighing_scale.toit
prints the stable weight based on the stable-factor and scale-resolution */
main:
  log.set-default (log.default.with-level log.INFO-LEVEL)
  // log.set-default (log.default.with-level log.DEBUG-LEVEL)
  RX := 36
  TX := 12
  scale := WeighingScale --rx-pin=RX --tx-pin=TX --stable-factor=3 --scale-resolution=10 
  scale.enable-weighing-scale-task
  
