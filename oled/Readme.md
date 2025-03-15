# Component: OLED Display

## Overview

This component initializes and manages a Oled display. The communication is carried out via the I2C protocol, and it requires specific configurations for proper operation. The component supports display management through essential functions like initializing the display, display the strings, and clearing rows.


## Configuration and Initialization

### Pin Configuration

- Provide the necessary pin configurations to initialize the OLED display, while creating the object of OLED class as a parameter. Refer main function, How the parameters are parsed.
- If the parameters are absence for parsing it will take the default value from the constructor.
- Default Clock frequency 40 MHz is used.


### OLED Driver

The oled.toit file contains:

    - Oled class for initializing the display.
    - display-string function for displaying text.
    - clear-row function for clearing specific rows.
    - No of Rows - 4.
    - No of Columns - 13.
    - Using Monospaced font - *font-x11-adobe.typewriter-12*

### Initialization

    The Oled display initialization is performed by creating object.


## Functions

1. display-string

    This function is used to display text on the Oled screen.
    Parameters:
        string: The text to be displayed.
        row: The row index where the string will be displayed.
        column: The column index where the string will start.
        scroll: A boolean flag to enable or disable scrolling.Be default scroll Flag is false

2. clear-row

    This function clears a specific row on the display.
    Parameter:
    row: The index of the row to be cleared.

## Hardware Requirements

- Oled Display: 64 x 128 resolution.
- Microcontroller : ESP-DevKit Module.
- Accessories : Connecting Wires.


## Software Requirements

- Programming Language: Toit.
- IDE: Visual Studio Code.
- Extensions: JAG Extension for Toit.
- Package for SSD1306 Driver : jag pkg install github.com/toitware/toit-ssd1306
- Firmware: ESP-IDF for ESP module support.


# Usage of component-oled   

Refer the main function, how to access the functions mentioned above.
Run the main function, Using the jag watch oled.toit , See how it behaves.


