# Component: MembraneKeypad 4x4

## Overview

This component initializes and manages Membrane Keypad. The communication is carried out via the I2C protocol, and it requires specific configurations for proper operation. The component supports key press management through essential functions like initializing the pcf8574 IC, key_scan 


## Configuration and Initialization

### Pin Configuration

- Provide the necessary pin configurations to initialize the Keypad connected to pcf8574IC, while creating the object of keypad class as a parameter. Refer main function, How the parameters are parsed.
- If the parameters are absence for parsing it will take the default value from the constructor.
- Default Clock frequency 40 MHz is used.


The keypad.toit file contains:

    - Keypad class for initializing the Membrane Keypad.
    - key-scan function acts as task.

### Initialization

    Membarane Keypad initialization is performed by creating object.


## Functions

1. key_scan function simply monitors whatever key is pressed prints the key_pressed on the logs. if callback is disabled, otherwise it can be used in the other .toit files to reuse the varaibles value.

## Hardware Requirements

- Membrane Keypad
- Microcontroller : ESP-DevKit Module.
- Accessories : Connecting Wires.


## Software Requirements

- Programming Language: Toit.
- IDE: Visual Studio Code.
- Extensions: JAG Extension for Toit.
- Package for Pcf8574 Driver : jag pkg install github.com/toitware/toit-pcf8574
- Firmware: ESP-IDF for ESP module support.


# Usage of Component

Refer the main function, how to access the functions mentioned above.
Run the main function, Using the jag watch keypad.toit , See how it behaves.


