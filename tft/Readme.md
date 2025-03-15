# Component: TFT Display

## Overview

This component initializes and manages a TFT display using t. The communication is carried out via the SPI protocol, and it requires specific configurations for proper operation. The component supports display management through essential functions like initializing the display, display the strings, and clearing rows.


## Configuration and Initialization

### Pin Configuration

- Provide the necessary pin configurations to initialize the TFT display, while creating the object of TFT class as a parameter. Refer main function, How the parameters are passed.
- If the parameters of the
- Ensure that the crystal frequency is set to 30 MHz or below. Note: Frequencies above 30 MHz are not supported.


### TFT Driver

The tft.toit file contains:

    - Tft class for initializing the display.
    - display-string function for displaying text.
    - clear-row function for clearing specific rows.
    - No of Rows - 10.
    - No of Columns - 21.
    - Using Monospaced font - *font-x11-adobe.typewriter-18-bold*

### Initialization

    The TFT display initialization is performed by creating object.


## Functions

1. display-string

    This function is used to display text on the TFT screen.
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

- TFT Display: 240 x 320 resolution.
- Microcontroller : ESP-DevKit Module.
- Accessories : Connecting Wires.


## Software Requirements

- Programming Language: Toit.
- IDE: Visual Studio Code.
- Extensions: JAG Extension for Toit.
- Package for TFT Display : jag pkg install github.com/toitware/toit-color-tft
- Firmware: ESP-IDF for ESP module support.


# Usage of component-tft

Refer the main function, how to access the functions mentioned above.
Run the main function, Using the jag watch tft.toit , See how it behaves.


