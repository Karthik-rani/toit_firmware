import gpio
import i2c
import pcf8574 show *
import log

class Keypad:
  _sda_pin/int := 0
  _scl_pin/int := 0
  _device_address := 0
  _debounce_delay := 200
  _last_key := ""  // Stores the last key pressed
  _key_released := true  // Tracks if the key has been released
  _callback/Lambda? := null
  device := ?
  pcf8574 := ?
  keymap := [["D", "C", "B", "A"],
             ["#", "9", "6", "3"],
             ["0", "8", "5", "2"],
             ["*", "7", "4", "1"]]
  columnMask := [0x7F, 0xBF, 0xDF, 0xEF]

  constructor --sda-pin/int = 13
              --scl-pin/int = 16
              --device-address= 0x20
              --debounce_delay=200
              --callback/Lambda?=null:

    _sda_pin = sda-pin
    _scl_pin = scl-pin
    _device_address = device-address
    _debounce_delay = debounce_delay
    _callback = callback

    // Initialize I2C bus
    bus := i2c.Bus
      --sda = gpio.Pin _sda_pin
      --scl = gpio.Pin _scl_pin

    device = bus.device _device_address

    // Initialize PCF8574
    pcf8574 = Pcf8574 device
    log.set-default (log.default.with-level log.INFO-LEVEL)

  enable_keypad_task:
    task ::key_scan
    log.info "Keypad task started" --tags={"Component": "KEYPAD"}

  key_scan:
    last_state := 0x00
    while true:
      for row := 0; row < columnMask.size; row++:
        pcf8574.write --raw = true columnMask[row]
        port_value := pcf8574.read --raw = true
        port_value = port_value | 0xF0 

        if port_value != last_state:
          last_state = port_value  // Update the last state
          key_pressed := ""
          if port_value == 247:  // hex 0xF7
            key_pressed = keymap[row][0]
          else if port_value == 251:  // hex 0xFB
            key_pressed = keymap[row][1]
          else if port_value == 253:  // hex 0xFD
            key_pressed = keymap[row][2]
          else if port_value == 254:  // hex 0xFE
            key_pressed = keymap[row][3]

          if not key_pressed.is-empty:
            if _key_released:  // Only process if the key was previously released
              _last_key = key_pressed
              _key_released = false  // Key is now pressed
              if _callback:
                _callback.call key_pressed
              else:
                log.info "key_pressed:$key_pressed" --tags={"Component": "KEYPAD"}
          else:
            _key_released = true  // Key has been released

      sleep --ms=_debounce_delay  // Add a delay between iterations


main:
  SDA := 13
  SCL := 16
  I2C_KEYPAD_ADDRESS := 0x20

  keypad := Keypad --sda-pin=SDA --scl-pin=SCL --device-address=I2C_KEYPAD_ADDRESS --debounce_delay=150

  keypad.enable_keypad_task
