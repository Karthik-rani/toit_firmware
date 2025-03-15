import gpio
import i2c
import ssd1306 show *
import pixel-display show *
import pixel-display.two-color show *
import font show *
import font-x11-adobe.typewriter-12 as oled-font
import monitor

class Oled:
  _sda_pin/int?:=null
  _scl_pin/int?:=null
  _device_address := 0
  lines := List
  scrolling-lines:= Map
  keys:= List
  value:=List
  mutex := monitor.Mutex
  box := ?
  device := ?
  oled-driver := ?
  display := ?
  font := 0
  additional-line-spacing/int?:= null
  font-typewriter := Font [oled-font.ASCII]
  font-width-index :=0
  font-height-index := 1
  font-extent := 0
  font-height := 0
  char-width/int? := null 
  style := ?
  width := 128
  height := 64
  _scroll_delay/int? := null
  _enable_scroll_task/bool? := null
  line-space := 6

  constructor --sda-pin = 13
              --scl-pin = 16
              --device-address = 0x3C
              --scroll-delay =10
              --enable-scroll-task = false:
    _sda_pin = sda-pin
    _scl_pin = scl-pin
    _device_address = device-address
    _scroll_delay = scroll-delay
    _enable_scroll_task = enable-scroll-task

    //I2c initialization           
    bus := i2c.Bus
      --sda = gpio.Pin _sda_pin
      --scl = gpio.Pin _scl_pin

    device = bus.device _device_address

    //ssd1306 Driver Initialization
    oled-driver = Ssd1306.i2c device --flip= false
    
    //PixelDisplay Initialization by parsing the driver to render the strings
    display = PixelDisplay.two-color oled-driver
    
    //Initializing the font and styles
    // Changing the B to any other letter does not affect char width
    font-extent = font-typewriter.text-extent "B"
    font-height = font-extent[font-height-index]
    char-width  = font-extent[font-width-index]
    print "char-width:$char-width"

    additional-line-spacing = font-height + line-space
    
    style = Style --class-map={
      "sans": Style --color=0x000000 --font=font-typewriter
    }
    
    //Creating lines with appropriate line-spacing
    lines = List 4: |i/int| Label --id="line$i" --classes=["sans"] --x=0 --y=(additional-line-spacing*(i+1))
    box = Div --id="box" --x=0 --y=0 --w=width --h=height --background=0xffffff lines
    display.add box
    display.set-styles [style]
    
    //Flag to set scroll task
    if _enable_scroll_task:
      task :: oled-scroll-task
 
  //display string 
  display-string str/string row/int column/int scroll/bool = false:
    if row >=0 and row < lines.size:
      line := lines[row]
      line.x = column * char-width
      line.text = str
      if scroll and _enable_scroll_task:
        mutex.do:
          scrolling-lines[line] = [str, line.x, column]
      else:
        mutex.do: scrolling-lines.remove line
        display.draw
    else:
      return 
  //clear row
  clear-row row/int:
    if row >=0 and row < lines.size:
      line := lines[row]
      mutex.do: scrolling-lines.remove line
      line.text = ""
      display.draw
    else:
      return
  //scroll-task
  oled-scroll-task:
    while true:
      mutex.do:
        keys = scrolling-lines.keys
      for i :=0; i< keys.size; i+=1:
        line :=keys[i]
        mutex.do:
          value = scrolling-lines.get line//to get the individual value associated with key
        if value != null:
          str := value[0]
          initial-x-pos :=value[1]
          update-offset :=value[2]
          new-x-pos:= initial-x-pos - update-offset
          reset-x-pos := new-x-pos + (str.size * char-width)
          if reset-x-pos < 0:
            new-x-pos = width
            update-offset = 0
          line.x = new-x-pos
          mutex.do:
            scrolling-lines[line] =[str, initial-x-pos, update-offset+1] 
      display.draw
      sleep --ms = _scroll_delay


/*Here example code to test the Tft display , You Change the parameters*/
main:
  SDA := 13
  SCL := 16
  I2C_OLED_ADDRESS := 0x3C

  oled := Oled --sda-pin=SDA --scl-pin=SCL --device-address=I2C_OLED_ADDRESS --enable-scroll-task=true --scroll-delay = 20
  oled.display-string "ABCDEFGHIJKLM" 0 0 
  oled.display-string "1234567890123" 1 0
  oled.display-string "Line2" 2 5 true
  oled.display-string "Line3" 3 7 true
  // sleep --ms = 10000
  // oled.clear-row 0
  // oled.clear-row 1
  // oled.clear-row 2
  // oled.clear-row 3
  while true:
    sleep --ms =10
    