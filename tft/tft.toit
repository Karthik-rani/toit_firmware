import gpio
import spi
import color-tft show *
import pixel-display show *
import font show *
import pixel-display.style show *
import font-x11-adobe.typewriter-18-bold as label-font
import monitor  // For thread safety

get-display setting/Map -> PixelDisplay:
  hz            := 1_000_000 * setting["clock-frequency"]
  width         := setting["x-axis"]
  height        := setting["y-axis"]
  x-offset      := setting["xoff"]
  y-offset      := setting["yoff"]
  mosi          := gpio.Pin setting["sda-pin"]
  clock         := gpio.Pin setting["scl-pin"]
  cs            := gpio.Pin setting["cs-pin"]
  dc            := gpio.Pin setting["dc-pin"]
  reset         := gpio.Pin setting["reset-pin"]
  backlight     := setting["backlight"]
  invert-colors := setting["invert"]
  flags         := setting["orientation-flags"]

  bus := spi.Bus
    --mosi=mosi
    --clock=clock

  device := bus.device
    --cs=cs
    --dc=dc
    --frequency=hz

  driver := ColorTft device width height
    --reset=reset
    --backlight=backlight
    --x-offset=x-offset
    --y-offset=y-offset
    --flags=flags
    --invert-colors=invert-colors

  return PixelDisplay.true-color driver

class Tft:

  // class Varaible Declaration for the Display Parameters
  _display := ?
  lines := []
  scrolling-lines := Map
  mutex := monitor.Mutex
  width/int := ?
  height/int := ?
  additional-line-spacing/int := ?
  char-width := ?
  clock-frequency := ?
  x-axis/int := ?
  y-axis/int := ?
  xoff/int  := ?
  yoff/int := ?
  sda-pin/int := ?
  scl-pin/int := ?
  cs-pin/int := ?
  dc-pin/int  := ?
  reset-pin/int := ?
  backlight := ?
  invert := ?
  orientation-flags := ?
  scroll-delay/int := ?
  enable-scroll-task/bool := ?
// Class Varaible Declaration for Font Parameters
  font-typewriter := Font [label-font.ASCII]
  font-width-index := 0
  font-height-index := 1
 

  constructor --CLOCK-FREQUENCY       = 30
              --X-AXIS                = 320
              --Y-AXIS                = 240
              --XOFF                  = 0
              --YOFF                  = 0
              --SDA-PIN               = 32
              --SCL-PIN               = 19
              --CS-PIN                = 13
              --DC-PIN                = 4
              --RESET-PIN             = 2
              --BACKLIGHT             = null
              --INVERT                = false
              --ORIENTATION-FLAGS     = [COLOR-TFT-16-BIT-MODE | COLOR-TFT-FLIP-Y]
              --ENABLE-SCROLL-TASK    = false
              --SCROLL-DELAY          = 5:
    // Assign parsed values or default values
    clock-frequency    =  CLOCK-FREQUENCY 
    x-axis             =  X-AXIS 
    y-axis             =  Y-AXIS 
    xoff               =  XOFF 
    yoff               =  YOFF 
    sda-pin            =  SDA-PIN 
    scl-pin            =  SCL-PIN 
    cs-pin             =  CS-PIN 
    dc-pin             =  DC-PIN 
    reset-pin          =  RESET-PIN 
    backlight          =  BACKLIGHT 
    invert             =  INVERT 
    orientation-flags  =  ORIENTATION-FLAGS 
    scroll-delay       =  SCROLL-DELAY 
    enable-scroll-task =  ENABLE-SCROLL-TASK
    width              =  Y-AXIS
    height             =  X-AXIS

    display-settings := {
      "clock-frequency"    :clock-frequency,
      "x-axis"             :x-axis,
      "y-axis"             :y-axis,
      "xoff"               :xoff,
      "yoff"               :yoff,
      "sda-pin"            :sda-pin,
      "scl-pin"            :scl-pin,
      "cs-pin"             :cs-pin,
      "dc-pin"             :dc-pin,
      "reset-pin"          :reset-pin,
      "backlight"          :backlight,
      "invert"             :invert,
      "orientation-flags"  :orientation-flags,
    }

    print "Initializing TFT Display..."
    _display = get-display display-settings

    // Calculate line spacing and character width
    // changing from B to any other letter does not have significant impact on width
    font-extent := font-typewriter.text-extent "B"
    font-height := font-extent[font-height-index]
    char-width  = font-extent[font-width-index]
    print "char-width: $char-width"
    additional-line-spacing = font-height + 8
    
    // Assign the Style and Font to the display Characters
    style ::= Style --class-map={
      "sans": Style --color=0xffffff --font=font-typewriter
    }

    // Creating the lines with appropriate line-spacing 
    lines = List 10: |i/int| Label --id="line$i" --classes=["sans"] --x=0 --y=(additional-line-spacing * (i + 1))
    box := Div --id="box" --x=0 --y=0 --w=width --h=height --background=0x000000 lines
    _display.add box 
    _display.set-styles [style]
    print "TFT DISPLAY Successfully Initialized..."

    if enable-scroll-task:
      task :: tft-scroll-task
  
  display-string str/string row/int column/int scroll/bool = false:
    if row >= 0 and row < lines.size:
      line := lines[row]
      line.x = column * char-width
      line.text = str
      if scroll and enable-scroll-task:
        mutex.do:
          print "Displaying Scrolling text on Row: $row, Column: $column, Scroll: $scroll"
          scrolling-lines[line] = [str, line.x , column]
      else:
        print "Displaying Static text on Row: $row, Column: $column, Scroll: $scroll"
        mutex.do: scrolling-lines.remove line
        _display.draw
          
    else:
      print "Invalid Row: $row"

  clear-row row/int:
    if row >= 0 and row < lines.size:
      line := lines[row]
      mutex.do: scrolling-lines.remove line
      line.text = ""
      _display.draw
    else:
      print "Invalid Row: $row"
  

  tft-scroll-task:
    print "Starting scroll task"
    while true:
      keys := []  
      mutex.do:  
        keys = scrolling-lines.keys
      for i := 0; i < keys.size; i += 1:
        line := keys[i]
        value := []
        mutex.do:
          value = scrolling-lines.get line  // Get the value associated with the key
        if value != null:  // Ensure value exists
          str := value[0]
          initial-x-pos := value[1]
          update-offset := value[2]
          new-x-pos := initial-x-pos - update-offset
          reset-x-pos := new_x_pos + (str.size * char-width)
          if reset-x-pos < 0:
            new-x-pos = width  // Reset to the right
            update-offset = 0
          line.x = new-x-pos
          mutex.do:
            scrolling-lines[line] = [str, initial-x-pos, update-offset + 2]
      _display.draw  // Refresh display after updating all scrolling lines
      sleep --ms = scroll-delay


/*Here example code to test the Tft display , You Change the parameters*/
main:
  tft := Tft
    --CLOCK-FREQUENCY=30
    --X-AXIS=240
    --Y-AXIS=320
    --XOFF=0
    --YOFF=0
    --SDA-PIN=32
    --SCL-PIN=19
    --CS-PIN=13
    --DC-PIN=4
    --RESET-PIN=2
    --BACKLIGHT=null
    --INVERT=false
    --ORIENTATION-FLAGS=COLOR-TFT-16-BIT-MODE | COLOR-TFT-FLIP-Y
    --SCROLL-DELAY=10
    --ENABLE-SCROLL-TASK=true

  tft.display-string "line1" 0 0 true
  tft.display-string "line2" 1 8 true
  tft.display-string "line3" 2 10 true
  tft.display-string "line4" 3 15 false
  tft.display-string "line5" 4 0 
  tft.display-string "line6" 5 5 
  tft.display-string "line7" 6 10 
  tft.display-string "line8" 7 15 
  tft.display-string "line9" 8 0 
  tft.display-string "line10" 9 5 
  while true:
    sleep --ms=10
