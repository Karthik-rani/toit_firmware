# Component: RTC (Real-Time Clock)  

## Overview  

This component handles the initialization and management of an RTC using the PCF8563 chip. It leverages the I2C protocol for communication, allowing for precise timekeeping and synchronization with network time protocol (NTP) servers. Core functionality includes setting and getting the time and date, both locally and through external synchronization. 

## Configuration and Initialization  

### Pin Configuration  

    The RTC component utilizes specific I2C pin configurations, provided as parameters when creating an instance of the Rtc class. Check the main function for detailed parameter usage.
    Default parameters may apply if no arguments are passed to the constructor.
    Clock frequency for I2C communication is set to 100kHz.
     

### RTC Driver  

The rtc.toit file includes: 

    Rtc class for RTC initialization and management.
    init_rtc function to reset RTC registers.
    Functions like set_time_date, get_time, and get_date for complete RTC functionality.
     

### Initialization  

RTC initialization is achieved through an instance of the Rtc class, which includes configuring I2C pins and setting registers. 

## Functions  

    init_rtc  

    Initializes the RTC by clearing and setting its registers to default values. 

    set_time_date  

    Sets the RTC time and date. 
        Parameters are the seconds, minutes, hours, day, weekday, month, and year.
         

    get_time  

    Retrieves the current time from the RTC. 
        Returns a list containing hours, minutes, and seconds.
         

    get_date  

    Retrieves the current date from the RTC. 
        Returns a list containing day, weekday, month, and year.
         

    set_local_time_date  

    Syncs system time using an NTP server and adjusts for the local timezone (IST). 

    set_system_time_date_from_rtc  

    Sets the system time using RTC values if NTP synchronization fails. 
     

## Hardware Requirements  

    RTC Module: PCF8563
    Microcontroller: ESP-DevKit Module
    Accessories: Connecting Wires, 3.3V battery
     

## Software Requirements  

    Programming Language: Toit
    IDE: Visual Studio Code
    Extensions: JAG Extension for Toit
    Firmware: ESP-IDF for ESP module support
     

# Usage of Component-RTC  

Refer to the main function to understand using the functions listed above. Run the main function using jag run rtc.toit to test RTC operations and see the implementation in action. 