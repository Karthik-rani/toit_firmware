# Component: Weighing Scale

## Overview

This component initializes the printer uart port of the device. The communication is carried out via the UART protocol, and it requires specific configurations for proper operation. The component supports for sending data to the printer through RS232 cable.



## Configuration and Initialization

### Pin Configuration

- Provide the necessary pin configurations to initialize the Uart Port of the device. While creating the object of the Printer as a parameter. Refer main function, How the parameters are parsed.

- Ensure that the Baud Rate of the Uart Communication whether it supports the printer Configuration . It depends on the manufacturer of the printer.


### Driver

Printer.toit contains:
   
    - Printer class constructor for initializing the weighing scale port.
    - printer function for transmitting the data to the printer.
    - tx-pin transmitter pin 
    - rx-pin receiver pin
    - Baud-Rate bits per second for the communication , The device and printer should have same Baud-Rate. Otherwise the data transfer will not occur

Read_peeler_status Function (Work in Progress)

## Hardware Requirements

 - Printer
 - Microcontroller : ESP-DevKit Module.
 - Accessories : Connecting Wires.


## Software Requirements

 - Programming Language: Toit.
 - IDE: Visual Studio Code.
 - Entensions: JAG Extension for Toit.
 - Firmware: ESP-IDF for ESP module support.

# Usage of component-printer

Refer the main function , how to initialize the functions mentioned above.
Run the main function, Using the jag watch printer.toit , See how it behaves. 