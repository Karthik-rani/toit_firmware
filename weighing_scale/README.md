# Component: Weighing Scale

## Overview

This component initializes the weighing scale port of the device. The communication is carried out via the UART protocol, and it requires specific configurations for proper operation. The component supports weight read data from the weighing scale through the task named as weighing-scale-task



## Configuration and Initialization

### Pin Configuration

- Provide the necessary pin configurations to initialize the Uart Port of the device. While creating the object of the WeighingScale as a parameter. Refer main function, How the parameters are parsed.

- Ensure that the Baud Rate of the Uart Communication whether it supports the weighing scale. It depends on the manufacturer of the weighing scale.


### Driver

the Weighing_scale.toit contains:
   
    - Weighing Scale for initializing the weighing scale port.
    - weight-read-task function for fetching from the weighing scale.
    - tx-pin transmitter pin 
    - rx-pin receiver pin
    - baud-rate bits per second for the communication , The device and weighing scale should have same Baud-Rate. Otherwise the weigt data won't available.

## Hardware Requirements

 - Weighing Scale.
 - Microcontroller : ESP-DevKit Module.
 - Accessories : Connecting Wires.


## Software Requirements

 - Programming Language: Toit.
 - IDE: Visual Studio Code.
 - Entensions: JAG Extension for Toit.
 - Firmware: ESP-IDF for ESP module support.

# Usage of component-weighing_scale

Refer the main function , how to initialize the functions mentioned above.
Run the main function, Using the jag watch tft.toit , See how it behaves. 