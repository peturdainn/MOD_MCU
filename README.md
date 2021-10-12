# MOD_MCU - Modular NodeMCU LUA boilerplate code

## What?
This is a small collection of 'modules' you can use to VERY quickly create an IoT device in LUA with NodeMCU.
It takes care of all the boring stuff so your actual app is just a few lines!

Just as with NodeMCU, it is event-driven: most modules have a timer whose interval you can set on init, and will call your callback so you can chain operations, like sending the data to MQTT. Some modules can be called manually (time 0) for sequential operations in case memory is short.

The MQTT module is a bit of a core module which also sends telemetry and uses that as a ping back 'alive' check, reconnecting and even rebooting if problems are detected. But it is not required in case you want a stand-alone or non-MQTT project.
Some modules (like MQTT, WiFi) have a corresponding cfg file for things you might change between projects, so the modules don't need changing

Also included is a very nice init script that will strip debug and compile any .lua file it finds (and then delete it).
No need to compile on your PC, it's done on first boot. And it saves RAM!

If you need float in embedded, you picked the wrong units. So all this code is integer only. So pick the correct NodeMCU build.

## Why?
When I started my IoT project at home, arduino for ESP8266 wasn't where it is today, but NodeMCU was pretty stable and easy to start with.
Soon I noticed I was doing more copy-paste work than I wanted, so this set of modules was born, to re-use my common code.
Also, MQTT on NodeMCU is tricky to get right, easy to leak memory when doing stuff in callbacks. No worries now :)

## Getting started
Flash your ESP8266 with an integer build of NodeMCU (these scripts work with v3.0)
A typical project consists of an init, app and a selection of modules, enabled in cfg_mod.lua
Note that some included helper code was taken over from the NodeMCU project, like (fifo)sock and ds18b20.
However, the ds18b20 included here was heavily stripped for memory usage and only deals with integer math and degrees C!
So, edit app, cfg files and cdg_mod, then load the whole ting on your ESP8266 and off you go.
Your app *must* call the init method for each module you want to use!
Times are in ms

## Modules

### MOD_1750
BH1750 16bit Digital I2C light sensor module
Requires: node,tmr,i2c
Usage: 
* mod_1750.init(time, scl pin, sda pin, callback)
* callback(lux)

### MOD_adc
ESP8266 ADC with averaging
Requires: node,tmr,adc
Usage:
* mod_adc.init(time, average count, callback)
* callback(average adc value)

### MOD_bme280
BME280 temperature, humidity and pressure sensor module
Requires: node,tmr,i2c,bme280
Usage:
* mod_bme280.init(time, scl pin, sda pin, callback)
* callback(temperature units, temperature decimals, humidity units, humidity decimals, pressure units, pressure decimals)

### MOD_ds18b20
The one-wire DS18B20 temperature sensor. Supports only one sensor per pin.
All temperatures are in .1 units, so 201 means 20.1C.
At some point I checked the calibration of my sensors and noted some had a shift of up to .3C, so I added automatic adjustment.
Returns a temperature of -666 if an error occurred.
This module supports manual operation: pass 0 as time and call do_now() to start a measurement
Requires: node,tmr,ow
Usage:
* mod_ds18b20.init(time, pin, compensation, callback)
* mod_ds18b20.do_now()
* callback(temperature * 10)

### MOD_http
I use a simple http logger on my server, this module can push strings to it and even buffer some if busy
Requires: node,tmr,http
Usage:
* mod_http.init()
* mod_http.log(string without spaces)

### MOD_io
IO input and output. The IO input is edge triggered *and* debounced, configurable per pin.
Since debounce variables take some memory, specify the number of inputs you will use during init().
An IdlePing feature lets you get a callback with the pin state every x ms as some kind of alive signal. Pass 0 to disable.
The callback has a ´time since change' which will be 0 on changes, nonzero on idle callback
Requires: node,tmr,gpio
Usage:
* mod_io.init(pincount, callback)
* mod_io.output(pin, value 0 or 1)
* mod_io.input(pin)
* mod_io.watch(pin, debounce time, idle)
* callback(pin, state, time since change)

### MOD_io_lite
Like MOD_io but for a single IO for reduced RAM usage
Requires: node,tmr,gpio
Usage:
* mod_io.init(callback)
* mod_io.output(pin, value 0 or 1)
* mod_io.input(pin)
* mod_io.watch(pin, debounce time, idle)
* callback(pin, state, time since change)

### MOD_led
Easy LED on/off/toggle. Define the LEDs and the connection pins in the cfg.
Assumes GPIO LOW to drive the LED
Requires: node,tmr,gpio
Usage:
* mod_led.init()
* mod_led.on(led nr)
* mod_led.off(led nr)
* mod_led.toggle(led nr)

### MOD_mhz19b
MHZ19b low cost CO2 sensor via UART. Since there is only one usable UART, there is a start method to grab UART.
Tip: I use a jumper and/or delay to start it, so the LUA interpreter is available if needed. 
Requires: node,tmr,uart
Usage:
* mod_mhz19b.init(start, callback)
* mod_mhz19b.enable(0 or 1)
* callback(PPM)

### MOD_mqtt
Maintains an MQTT connection, sends telemetry/heartbeat (and uses that to monitor the connection), and offers publish and subscribe.
Uses leaky bucket on the heartbeat and reboots the ESP8266 if the connection consistently fails.
It detects if you're sending from normal code or an mqtt callback, to prevent memory leaks.
The telemetry is a JSON containing version info, IP address, MQTT ID, reconnect count, heap and uptime. Not HA compatible, sorry.
Note that there is only one subscription callback, if you do multiple subscribes with different callbacks, the last one passed is used for all!
Requires: node,tmr,mqtt
Usage:
* mod_mqtt.init(mqtt id, connection_callback)
* mod_mqtt.subscribe(topic, subscription_callback)
* mod_mqtt.send(topic, data)
* connection callback()
* subscription_callback(topic, data)

### MOD_ntp
Automatic NTP sync. I'm no longer using this but added since it exists :)
It tries to sync time every hour, and at startup.
Requires: tmr,sntp
Usage:
* mod_ntp.init()

### MOD_oled
Written specifically for an ssd1306 (128x64) OLED display using a 9x15B font.
Allows for orientation change, easy line/frame drawing, line-based text updates, and a progress bar
Requires: tmr,i2c,u8g2 with font_9x15B_tf
Usage:
* mod_oled.init(scl, sda)
* mod_oled.update()
* mod_oled.clearscreen()
* mod_oled.textline(line, text)
* mod_oled.drawframe(x, y, w, h)
* mod_oled.drawprogress(x, y, w, h, percent)
* mod_oled.orientation(0/90/180/270/MIRROR)

### MOD_scd4x
Small/basic support for the Sensirion SCD4x CO2 sensor.
Supports configurable periodic measurements, forced (manual) calibration and factory reset.
The manual recalibration command will do the required 3 minute measurement and then calibrate for 480ppm
While calibrating, the response callback will send an incrementing counter every interval, so you can guess how far it is.
For a 5 second interval, it will count to 36. It should normally return the calibration offset but I have so far just gotten an error, though it does seem to have calibrated fine.
Requires: tmr,i2c
Usage:
* mod_scd4x.init(time, scl, sda, data_callback, command_callback)
* mod_scd4x.command("RECALIB" or "FACTORYRST")
* data_callback(CO2, TEMP, RH)
* command_callback(command sequence and result)

### MOD_scd4x_lite
Like MOD_scd4x but no commands, just measuring. Uses less RAM.
Requires: tmr,i2c
Usage:
* mod_scd4x.init(time, scl, sda, data_callback)
* data_callback(CO2, TEMP, RH)

### MOD_sds011
Particle sensor SDS011 interface via UART with enable (use UART) and sleep/wakeup
Since there is only one usable UART, there is a start method to grab UART.
I use a jumper and delay to start it, so the LUA interpreter is available if needed. 
Requires: node,tmr,uart
Usage:
* mod_sds011.init(start, callback)
* mod_sds011.enable(0 or 1)
* mod_sds011.sleep(0 or 1)
* callback(PM2.5 units, PM2.5 decimals, PM10 units, PM10 decimals)

### MOD_telnet
Based on the NodeMCU sample telnet script. Requires sock and fifosock. Allows remote access to NodeMCU interpreter.
Unstable for doing updates IMHO, so don't try that.
I'm no longer using this but added since it exists :)
Requires: node,net
Usage:
* mod_telnet.init()

### MOD_wiegand
My own Wiegand module, in use for 2 years now I think. I know there's one from NodeMCU now but I keep mine, it works very well
It returns a number when the 15ms timeout triggers. So for a keypad (what I use it for) you get a callback with a key code after each press.
The enable function can be used if the device sending the code can be switched on/off, to avoid glitches.
Requires: tmr,gpio
Usage:
* mod_wiegand.init(D0_pin, D1_pin, callback)
* mod_wiegand.enable(0 or 1)
* callback(number)

### MOD_wifi
A simple wifi connect module, with an on_connect callback (not required)
Prints minimalistic progress (IP? while connecting, and IP address when connected)
Change your wifi details in the cfg file!
Requires: tmr,wifi
Usage:
* mod_wifi(callback)
* callback()

### MOD_wifi_ap
A simple wifi AP module, with an on_connect callback (not required)
The callback is actually dummy, to be expanded on, or removed (you can tell I'm not using it much)
Change your wifi AP details in the cfg file!
Requires: tmr,wifi
Usage:
* mod_wifi(callback)
* callback()

